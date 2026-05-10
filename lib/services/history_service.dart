import 'package:g_route_app/models/travel_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  static final _supabase = Supabase.instance.client;

  static Future<void> saveHistory({
    required String destination,
    required String style,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    String? profile,
    int? days,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('travel_history').insert({
          'user_id': user.id,
          'destination': destination,
          'style': style,
          'orcamento': budget,
          'data_inicio': startDate?.toIso8601String(),
          'data_fim': endDate?.toIso8601String(),
          'perfil': profile,
          'duracao_dias': days,
          'completion_date': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Erro ao salvar histórico: $e');
      }
    }
  }

  static Future<List<TravelHistory>> getHistory() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('travel_history')
            .select()
            .eq('user_id', user.id)
            .order('completion_date', ascending: false);
        
        return (response as List)
            .map((item) => TravelHistory.fromJson(item))
            .toList();
      } catch (e) {
        print('Erro ao buscar histórico: $e');
      }
    }
    return [];
  }
}
