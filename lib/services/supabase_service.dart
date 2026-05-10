import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://zsprjastaiblctaoulof.supabase.co';
  static const String anonKey = 'sb_publishable_dtoS4EyP8J4wmJ7IMRIv7A_VoCnXO6I';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
