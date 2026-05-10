import 'dart:convert';
import 'package:http/http.dart' as http;

class MapboxService {
  static const String accessToken = 'pk.eyJ1IjoiYWx2ZXMxMDYxIiwiYSI6ImNtb3Z0ZGJncDA3cHgycnBwemI2ZjNqbDUifQ.zkWMo_ZgUHu7Kcv436y9Jg';

  static Future<List<Map<String, dynamic>>> searchPlaces(String query, {double? lat, double? lng, String? bbox}) async {
    if (query.length < 3) return [];

    final encodedQuery = Uri.encodeComponent(query);
    
    // Filtros geográficos: Proximidade (prioriza) e BBox (restringe)
    String filterParams = '';
    if (lat != null && lng != null) {
      filterParams += '&proximity=$lng,$lat';
    }
    if (bbox != null) {
      filterParams += '&bbox=$bbox';
    }

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$accessToken$filterParams&limit=10&language=pt&autocomplete=true'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];

        return features.map((f) {
          final context = f['context'] as List?;
          String? region;
          String? country;

          if (context != null) {
            for (var item in context) {
              if (item['id'].toString().startsWith('region')) region = item['text'];
              if (item['id'].toString().startsWith('country')) country = item['text'];
            }
          }

          return {
            'placeName': f['text'],
            'fullName': f['place_name'],
            'lat': f['center'][1],
            'lng': f['center'][0],
            'state': region,
            'country': country,
          };
        }).toList();
      }
    } catch (e) {
      print('Erro na busca Mapbox: $e');
    }
    return [];
  }

  /// Busca pontos de interesse (POIs) próximos a uma coordenada
  static Future<List<Map<String, dynamic>>> getNearbyPOIs(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/tourist_attraction,restaurant,museum,cafe.json?access_token=$accessToken&proximity=$lng,$lat&types=poi&limit=10&language=pt'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];

        return features.map((f) {
          return {
            'name': f['text'],
            'fullName': f['place_name'],
            'lat': f['center'][1],
            'lng': f['center'][0],
            'category': (f['properties']['category'] as String?)?.split(',').first ?? 'Local',
          };
        }).toList();
      }
    } catch (e) {
      print('Erro ao buscar POIs: $e');
    }
    return [];
  }

  /// Busca a rota (Directions) entre múltiplos pontos
  static Future<Map<String, dynamic>?> getRoute(List<Map<String, double>> coordinates, {String profile = 'driving'}) async {
    if (coordinates.length < 2) return null;

    final waypoints = coordinates.map((c) => '${c['lng']},${c['lat']}').join(';');
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$profile/$waypoints?geometries=geojson&overview=full&access_token=$accessToken'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0]['geometry'];
        return route; // GeoJSON geometry
      }
    } catch (e) {
      print('Erro ao buscar rota Mapbox: $e');
    }
    return null;
  }
}
