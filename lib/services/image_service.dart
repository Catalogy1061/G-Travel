import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:g_route_app/services/mapbox_service.dart';
import 'package:g_route_app/services/cache_service.dart';

import 'package:g_route_app/services/google_places_service.dart';
import 'package:g_route_app/models/itinerary_model.dart';

class ImageService {
  static final _supabase = Supabase.instance.client;

  // Cache em memória para acesso instantâneo durante a sessão
  static final Map<String, Map<String, String?>> _memoryCache = {};
  static final Map<String, List<Map<String, dynamic>>> _poiMemoryCache = {};

  // Fallback genérico caso a busca falhe
  static const String _fallbackImage = 'https://images.unsplash.com/photo-1488085061387-422e29b40080?q=80&w=1000&auto=format&fit=crop';

  /// Busca a imagem e a bandeira, utilizando cache do Supabase e Memória
  /// Agora suporta o armazenamento de metadados geográficos completos
  static Future<Map<String, String?>> getCityVisuals(
    String cityName, {
    double? lat,
    double? lng,
    String? pais,
    String? estado,
  }) async {
    final cityKey = cityName.trim().toLowerCase();

    // 1. Verificar Cache de Memória
    if (_memoryCache.containsKey(cityKey)) {
      return _memoryCache[cityKey]!;
    }

    // 2. Verificar Cache Local (SharedPreferences)
    final localCache = await CacheService.getData('visuals_$cityKey');
    if (localCache != null) {
      final result = Map<String, String?>.from(localCache);
      _memoryCache[cityKey] = result;
      return result;
    }

    // 2. Verificar Cache do Supabase (ECONOMIA)
    try {
      final cacheData = await _supabase
          .from('cache_cidades')
          .select('image_url, flag_url, pais, estado, lat, lng')
          .eq('cidade_nome', cityKey)
          .maybeSingle();

      if (cacheData != null && cacheData['image_url'] != null && cacheData['image_url'] != _fallbackImage) {
        final result = {
          'image': cacheData['image_url'] as String?,
          'flag': cacheData['flag_url'] as String?,
          'pais': cacheData['pais'] as String?,
          'estado': cacheData['estado'] as String?,
          'lat': cacheData['lat']?.toString(),
          'lng': cacheData['lng']?.toString(),
        };
        _memoryCache[cityKey] = result;
        CacheService.saveData('visuals_$cityKey', result);
        return result;
      }
    } catch (e) {
      print('Erro ao consultar cache no Supabase: $e');
    }

    // 3. Se não houver cache válido, buscar na Google Places API
    debugPrint('G-ROUTE: Buscando imagem de $cityName na Google Places API...');
    final googleImage = await GooglePlacesService.fetchImageUrl(cityName);
    
    final imageUrl = googleImage ?? _fallbackImage;
    String? flagUrl; // Poderia ser implementado via outra API se necessário

    final finalResult = {
      'image': imageUrl,
      'flag': flagUrl,
      'pais': pais,
      'estado': estado,
      'lat': lat?.toString(),
      'lng': lng?.toString(),
    };

    // 4. Salvar no Cache do Supabase para futuras consultas de outros usuários
    _saveToCache(
      cityKey: cityKey,
      image: imageUrl,
      flag: flagUrl,
      pais: pais,
      estado: estado,
      lat: lat,
      lng: lng,
    );
    
    // Salvar na memória e localmente
    _memoryCache[cityKey] = finalResult;
    CacheService.saveData('visuals_$cityKey', finalResult);

    return finalResult;
  }

  /// REMOVIDO: Busca na Wikipedia desativada para evitar conflitos
  static Future<String> _fetchFromWikipedia(String cityName) async => _fallbackImage;

  static Future<String?> _getWikipediaThumbnail(String title, String lang) async => null;

  static Future<String?> _fetchCountryFlag(String cityName) async => null;

  static void _saveToCache({
    required String cityKey,
    required String image,
    String? flag,
    String? pais,
    String? estado,
    double? lat,
    double? lng,
  }) async {
    try {
      await _supabase.from('cache_cidades').upsert({
        'cidade_nome': cityKey,
        'image_url': image,
        'flag_url': flag,
        'pais': pais,
        'estado': estado,
        'lat': lat,
        'lng': lng,
      });
    } catch (e) {
      print('Erro ao salvar no cache do Supabase: $e');
    }
  }

  /// REMOVIDO: Busca de informações desativada para evitar conflitos
  static Future<Map<String, String>> _getWikipediaInfo(String query) async {
    return {'image': '', 'description': ''};
  }

  /// Busca imagem de um lugar específico (com cache no Supabase)
  static Future<String?> fetchPlaceImage(String placeName, {String? cityName, int maxWidth = 800}) async {
    final searchName = cityName != null ? '$placeName, $cityName' : placeName;
    final cacheKey = searchName.toLowerCase().trim();

    // 1. Verificar Cache de Memória
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]?['image'];
    }

    // 2. Verificar Cache Global no Supabase (ECONOMIA)
    try {
      final cloudData = await _supabase
          .from('cache_pois')
          .select('imagem_url')
          .eq('poi_nome', placeName.trim())
          .maybeSingle();
      
      if (cloudData != null && cloudData['imagem_url'] != null) {
        final url = cloudData['imagem_url'] as String;
        _memoryCache[cacheKey] = {'image': url};
        return url;
      }
    } catch (e) {
      print('Erro ao consultar cache global de imagem: $e');
    }

    // 3. Buscar no Google Places
    debugPrint('G-ROUTE: Buscando imagem de $placeName no Google Places (Width: $maxWidth)...');
    final imageUrl = await GooglePlacesService.fetchImageUrl(searchName, maxWidth: maxWidth);
    
    if (imageUrl != null) {
      // Salvar no cache (usando a estrutura de POIs se possível)
      _memoryCache[cacheKey] = {'image': imageUrl};
      if (cityName != null) {
        _savePOIsToCloud(cityName, [{
          'name': placeName,
          'image': imageUrl,
          'description': '',
          'category': 'Roteiro IA',
          'lat': 0.0,
          'lng': 0.0,
        }]);
      }
    }

    return imageUrl;
  }

  /// Enriquece o itinerário completo da IA com imagens reais
  static Future<TripItinerary> enrichItinerary(TripItinerary itinerary) async {
    final cityName = itinerary.destinoInfo.nomeOficial;
    
    // Processar atividades em paralelo para maior velocidade
    final List<Future<void>> futures = [];

    for (var dia in itinerary.roteiroDiario) {
      // Imagens das Atividades
      for (var atividade in dia.atividades) {
        if (atividade.imageUrl == null || atividade.imageUrl!.isEmpty) {
          futures.add(fetchPlaceImage(atividade.local, cityName: cityName, maxWidth: 600).then((url) {
            atividade.imageUrl = url;
          }));
        }
      }
      
      // Imagem da Gastronomia
      if (dia.gastronomia.imageUrl == null || dia.gastronomia.imageUrl!.isEmpty) {
        futures.add(fetchPlaceImage(dia.gastronomia.restauranteSugerido, cityName: cityName, maxWidth: 600).then((url) {
          dia.gastronomia.imageUrl = url;
        }));
      }
    }

    // Imagem da Hospedagem (NOVO)
    if (itinerary.hospedagem != null && 
        itinerary.hospedagem!.status == 'sugerido' && 
        itinerary.hospedagem!.nome != null && 
        (itinerary.hospedagem!.imageUrl == null || itinerary.hospedagem!.imageUrl!.isEmpty)) {
      futures.add(fetchPlaceImage(itinerary.hospedagem!.nome!, cityName: cityName, maxWidth: 1000).then((url) {
        itinerary.hospedagem!.imageUrl = url;
      }));
    }
    // Imagens dos Tickets e Atrações (NOVO)
    for (var ticket in itinerary.ticketsEAtracoes) {
      if (ticket.imageUrl == null || ticket.imageUrl!.isEmpty) {
        futures.add(fetchPlaceImage(ticket.nome, cityName: cityName, maxWidth: 800).then((url) {
           ticket.imageUrl = url;
        }));
      }
    }

    await Future.wait(futures);
    return itinerary;
  }

  /// Pré-carrega e cacheia imagens da cidade e os POIs principais em background
  static Future<void> warmUpCityData(double lat, double lng, String cityName, String? pais, String? estado) async {
    // Apenas inicia busca visual básica (agora retorna fallback)
    await getCityVisuals(cityName, lat: lat, lng: lng, pais: pais, estado: estado);
  }

  /// Busca POIs enriquecidos com imagens reais da Google Places API
  static Future<List<Map<String, dynamic>>> getEnrichedPOIs(double lat, double lng, {String? cityName}) async {
    debugPrint('G-ROUTE: Buscando POIs para ${cityName ?? 'coordenadas'}');
    final cacheKey = cityName?.toLowerCase().trim() ?? '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    
    // 1. Verificar Cache de Memória
    if (_poiMemoryCache.containsKey(cacheKey)) {
      return _poiMemoryCache[cacheKey]!;
    }

    // 2. Verificar Cache Local
    final localCache = await CacheService.getData('pois_$cacheKey');
    if (localCache != null) {
      final results = (localCache as List).map((i) => Map<String, dynamic>.from(i)).toList();
      _poiMemoryCache[cacheKey] = results;
      return results;
    }

    // 2. Verificar Cache Global no Supabase (Nuvem - ECONOMIA)
    if (cityName != null) {
      try {
        final cloudData = await _supabase
            .from('cache_pois')
            .select()
            .eq('cidade_nome', cityName.toLowerCase().trim())
            .limit(10);
        
        if (cloudData != null && cloudData.isNotEmpty) {
          debugPrint('G-ROUTE: Encontrado cache na nuvem para $cityName (${cloudData.length} pontos)');
          final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(cloudData).map((p) => {
            'name': p['poi_nome'],
            'fullName': p['poi_nome'],
            'lat': p['lat'],
            'lng': p['lng'],
            'category': p['categoria'] ?? 'Atração',
            'image': p['imagem_url'] ?? '',
            'description': p['descricao'] ?? '',
          }).toList();
          
          _poiMemoryCache[cacheKey] = results;
          CacheService.saveData('pois_$cacheKey', results);
          return results;
        }
      } catch (e) {
        print('Erro ao consultar cache global de POIs: $e');
      }
    }

    // 3. Se não houver cache, buscar no Mapbox para nomes e localizações
    debugPrint('G-ROUTE: Cache não encontrado. Buscando via API Mapbox + Google Places...');
    double offset = 0.15; 
    double minLng = lng - offset;
    double maxLng = lng + offset;
    double minLat = lat - offset;
    double maxLat = lat + offset;
    String bbox = '$minLng,$minLat,$maxLng,$maxLat';

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/sightseeing.json?access_token=${MapboxService.accessToken}&bbox=$bbox&types=poi&limit=15&language=pt'
    );

    try {
      final response = await http.get(url);
      List<Map<String, dynamic>> results = [];
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        
        // Mapeia os resultados e busca imagens no Google Places em paralelo
        results = await Future.wait(features.map((f) async {
          final name = f['text'] ?? 'Local';
          final searchName = cityName != null ? '$name, $cityName' : name;
          
          // Busca imagem no Google Places
          final imageUrl = await GooglePlacesService.fetchImageUrl(searchName);
          
          return {
            'name': name,
            'fullName': f['place_name'] ?? '',
            'lat': (f['center'][1] as num).toDouble(),
            'lng': (f['center'][0] as num).toDouble(),
            'category': (f['properties']?['category'] as String?)?.split(',').first ?? 'Atração',
            'image': imageUrl ?? '',
            'description': 'Explore este ponto turístico incrível em ${cityName ?? 'seu destino'}.',
          };
        }).toList());
      }

      debugPrint('G-ROUTE: Buscas concluídas. Encontrados ${results.length} POIs com imagens.');
      
      _poiMemoryCache[cacheKey] = results;
      CacheService.saveData('pois_$cacheKey', results);

      // 4. Salvar no Cache Global do Supabase para o próximo usuário
      if (cityName != null && results.isNotEmpty) {
        _savePOIsToCloud(cityName.toLowerCase().trim(), results);
      }
      
      return results;
    } catch (e) {
      print('Erro ao buscar POIs: $e');
      return [];
    }
  }

  static void _savePOIsToCloud(String cityName, List<Map<String, dynamic>> pois) async {
    try {
      final inserts = pois.map((p) => {
        'cidade_nome': cityName,
        'poi_nome': p['name'],
        'descricao': p['description'],
        'imagem_url': p['image'],
        'categoria': p['category'],
        'lat': p['lat'],
        'lng': p['lng'],
      }).toList();

      await _supabase.from('cache_pois').upsert(inserts, onConflict: 'cidade_nome,poi_nome');
    } catch (e) {
      print('Erro ao salvar POIs na nuvem: $e');
    }
  }

  /// Enriquece uma lista genérica de lugares com imagens do Google Places
  static Future<List<Map<String, dynamic>>> enrichPlaces(List<Map<String, dynamic>> places) async {
    return await Future.wait(places.map((place) async {
      final name = place['placeName'] ?? place['name'];
      final imageUrl = await GooglePlacesService.fetchImageUrl(name);
      
      return {
        'name': name,
        'fullName': place['fullName'] ?? name,
        'lat': place['lat'],
        'lng': place['lng'],
        'category': 'Pesquisa',
        'image': imageUrl ?? '',
        'description': 'Local encontrado na sua busca.',
      };
    }).toList());
  }
}
