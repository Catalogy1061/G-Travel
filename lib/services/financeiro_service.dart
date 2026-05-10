import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class FinanceiroService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchExpenses(String roteiroId) async {
    try {
      final response = await _supabase
          .from('despesas')
          .select()
          .eq('roteiro_id', roteiroId)
          .order('created_at', ascending: false);
      
      final expenses = List<Map<String, dynamic>>.from(response);
      
      // Salva no cache local
      CacheService.saveData('expenses_$roteiroId', expenses);
      
      return expenses;
    } catch (e) {
      print('Erro ao buscar despesas: $e');
      return [];
    }
  }

  static Future<bool> addExpense({
    required String roteiroId,
    required String title,
    required double amount,
    required String category,
    required String date,
  }) async {
    try {
      await _supabase.from('despesas').insert({
        'roteiro_id': roteiroId,
        'titulo': title,
        'valor': amount,
        'categoria': category,
        'data': date,
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar despesa: $e');
      return false;
    }
  }
}
