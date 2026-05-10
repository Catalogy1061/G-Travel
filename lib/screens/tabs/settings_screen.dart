import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/theme/theme_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Ajustes",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          _buildSettingsItem(Icons.language_rounded, "Idioma", "Português (BR)"),
          _buildSettingsItem(Icons.notifications_active_rounded, "Notificações", "Ativado"),
          _buildSettingsItem(Icons.security_rounded, "Privacidade e Segurança", ""),
          _buildSettingsItem(Icons.help_outline_rounded, "Central de Ajuda", ""),
          _buildSettingsItem(Icons.info_outline_rounded, "Sobre o App", "v1.0.4"),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
        ],
      ),
      onTap: () {},
    );
  }
}
