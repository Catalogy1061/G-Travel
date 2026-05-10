import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const int CURRENT_CACHE_VERSION = 3; // Versão v3 para limpeza total da migração

  static Future<void> saveData(String key, dynamic data, {int? version, bool isUserSpecific = true}) async {
    if (_prefs == null) await init();
    
    final finalKey = isUserSpecific ? _getUserKey(key) : key;
    
    final payload = {
      'v': version ?? CURRENT_CACHE_VERSION,
      'd': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    
    String jsonString = jsonEncode(payload);
    await _prefs!.setString(finalKey, jsonString);
  }

  static Future<dynamic> getData(String key, {int? requiredVersion, bool isUserSpecific = true}) async {
    if (_prefs == null) await init();
    final finalKey = isUserSpecific ? _getUserKey(key) : key;
    String? jsonString = _prefs!.getString(finalKey);
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> payload = jsonDecode(jsonString);
        final int version = payload['v'] ?? 0;
        final int targetVersion = requiredVersion ?? CURRENT_CACHE_VERSION;

        // Se a versão for diferente, invalidamos o cache
        if (version != targetVersion) {
          print('Cache version mismatch for $key: expected $targetVersion, found $version. Invalidating...');
          await removeData(key);
          return null;
        }

        return payload['d'];
      } catch (e) {
        print('Erro ao ler cache: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> removeData(String key, {bool isUserSpecific = true}) async {
    if (_prefs == null) await init();
    final finalKey = isUserSpecific ? _getUserKey(key) : key;
    await _prefs!.remove(finalKey);
  }

  static Future<void> clearAll() async {
    if (_prefs == null) await init();
    await _prefs!.clear();
  }

  static String _getUserKey(String baseKey) {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return "guest_$baseKey";
      return "${userId}_$baseKey";
    } catch (e) {
      return "guest_$baseKey";
    }
  }

  // Chaves constantes para evitar erros de digitação
  static const String KEY_ACTIVE_ITINERARY = 'active_itinerary';
  static const String KEY_CITY_VISUALS = 'city_visuals';
  static const String KEY_USER_PROFILE = 'user_profile';
  static const String KEY_EXPENSES = 'expenses';
}
