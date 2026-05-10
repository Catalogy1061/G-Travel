import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoService {
  static const String _baseUrl = 'https://countriesnow.space/api/v0.1/countries';

  /// Busca todos os países
  static Future<List<String>> getCountries() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List countriesData = data['data'];
        return countriesData.map((c) => c['country'] as String).toList();
      }
    } catch (e) {
      print('Erro ao buscar países: $e');
    }
    return ['Brasil', 'Estados Unidos', 'França', 'Itália', 'Portugal']; 
  }

  /// Busca estados de um país
  static Future<List<String>> getStates(String country) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/states'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'country': country}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List statesData = data['data']['states'];
        return statesData.map((s) => s['name'] as String).toList();
      }
    } catch (e) {
      print('Erro ao buscar estados: $e');
    }
    return [];
  }

  /// Busca cidades de um estado e país
  static Future<List<String>> getCities(String country, String state) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/state/cities'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'country': country, 'state': state}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List citiesData = data['data'];
        return citiesData.cast<String>();
      }
    } catch (e) {
      print('Erro ao buscar cidades: $e');
    }
    return [];
  }
}
