import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static Future<void> updateLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      
      // Reverse Geocoding para pegar Cidade/UF/País
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      String city = 'Desconhecido';
      String state = '';
      String country = '';

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        city = place.locality ?? place.subAdministrativeArea ?? 'Desconhecido';
        state = place.administrativeArea ?? '';
        country = place.country ?? '';
      }

      await Supabase.instance.client.from('profiles').update({
        'last_lat': position.latitude,
        'last_lng': position.longitude,
        'city': city,
        'state': state,
        'country': country,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print("Erro ao atualizar localização: $e");
    }
  }
}
