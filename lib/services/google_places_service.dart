import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:g_route_app/globals.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Busca a referência de uma foto para um dado local
  static Future<String?> getPhotoReference(String placeName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/findplacefromtext/json?input=${Uri.encodeComponent(placeName)}&inputtype=textquery&fields=photos&key=${Globals.GOOGLE_API_KEY}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final photos = candidates.first['photos'] as List?;
          if (photos != null && photos.isNotEmpty) {
            return photos.first['photo_reference'] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro no GooglePlacesService.getPhotoReference: $e');
      return null;
    }
  }

  /// Constrói a URL final da foto a partir da referência
  static String getPhotoUrl(String photoReference, {int maxWidth = 800}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=${Globals.GOOGLE_API_KEY}';
  }

  /// Atalho para buscar a URL direta de uma foto pelo nome do local
  static Future<String?> fetchImageUrl(String placeName, {int maxWidth = 800}) async {
    final reference = await getPhotoReference(placeName);
    if (reference != null) {
      return getPhotoUrl(reference, maxWidth: maxWidth);
    }
    return null;
  }
}
