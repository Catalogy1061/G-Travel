import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:g_route_app/screens/auth/splash_screen.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/theme/theme_manager.dart';
import 'package:g_route_app/services/supabase_service.dart';
import 'package:g_route_app/screens/auth/login_screen.dart';
import 'package:g_route_app/screens/home_page.dart';
import 'package:g_route_app/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuração Global do Mapbox
  MapboxOptions.setAccessToken('pk.eyJ1IjoiYWx2ZXMxMDYxIiwiYSI6ImNtb3Z0ZGJncDA3cHgycnBwemI2ZjNqbDUifQ.zkWMo_ZgUHu7Kcv436y9Jg');
  
  // Inicializa o Supabase (Certifique-se de configurar as chaves em supabase_service.dart)
  await SupabaseConfig.init();
  
  // Inicializa Cache Local
  await CacheService.init();
  
  runApp(const NextGenTravelApp());
}

class NextGenTravelApp extends StatelessWidget {
  const NextGenTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'G-TRAVEL',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => LoginScreen(),
            '/main': (context) => HomePage(),
          },
        );
      },
    );
  }
}
