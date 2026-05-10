import 'dart:convert';
import 'package:g_route_app/models/fridge_model.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FridgeService {
  static final _supabase = Supabase.instance.client;

  static String get _cacheKey {
    final user = _supabase.auth.currentUser;
    return 'user_fridge_magnets_${user?.id ?? 'guest'}';
  }

  static Future<List<FridgeMagnet>> getMagnets() async {
    // 1. Tentar Cache
    final cached = await CacheService.getData(_cacheKey);
    if (cached != null) {
      final List<dynamic> list = jsonDecode(cached);
      return list.map((item) => FridgeMagnet.fromJson(item)).toList();
    }

    // 2. Tentar Supabase (Se logado)
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('fridge_magnets')
            .select()
            .eq('user_id', user.id);
        
        final List<FridgeMagnet> magnets = (response as List)
            .map((item) => FridgeMagnet.fromJson(item))
            .toList();
        
        // Salvar no Cache
        await CacheService.saveData(_cacheKey, jsonEncode(magnets.map((m) => m.toJson()).toList()));
        return magnets;
      } catch (e) {
        print('Erro ao buscar imãs: $e');
      }
    }

    return [];
  }

  static Future<void> saveToCacheOnly(List<FridgeMagnet> magnets) async {
    await CacheService.saveData(_cacheKey, jsonEncode(magnets.map((m) => m.toJson()).toList()));
  }

  static Future<void> syncWithSupabase(List<FridgeMagnet> magnets) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Salva Cache primeiro
    await saveToCacheOnly(magnets);

    // Salva no Supabase em paralelo (upsert de múltiplos registros)
    try {
      final List<Map<String, dynamic>> dataToSync = magnets.map((magnet) => {
        'id': magnet.id,
        'user_id': user.id,
        'destination': magnet.destination,
        'emoji': magnet.emoji,
        'color_hex': magnet.colorHex,
        'x': magnet.x,
        'y': magnet.y,
        'rotation': magnet.rotation,
      }).toList();

      await _supabase.from('fridge_magnets').upsert(dataToSync);
    } catch (e) {
      print('Erro ao sincronizar imãs: $e');
    }
  }

  static Future<void> saveMagnetPosition(FridgeMagnet magnet) async {
    final magnets = await getMagnets();
    final index = magnets.indexWhere((m) => m.id == magnet.id);
    
    if (index != -1) {
      magnets[index] = magnet;
    } else {
      magnets.add(magnet);
    }

    await syncWithSupabase(magnets);
  }

  static Future<void> addMagnet(FridgeMagnet magnet) async {
    await saveMagnetPosition(magnet);
  }
}
