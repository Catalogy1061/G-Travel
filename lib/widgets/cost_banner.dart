import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class CostBanner extends StatelessWidget {
  const CostBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "MONTE SEU ROTEIRO INTELIGENTE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "CUSTO TOTAL DO ROTEIRO",
                      style: TextStyle(fontSize: 10, color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 12, color: AppTheme.textGrey),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "R\$ 29,00",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const Text(
                  "Baseado nas suas seleções",
                  style: TextStyle(fontSize: 10, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: -10,
            child: SizedBox(
              height: 150,
              child: Image.asset(
                'assets/images/3d_purple_suitcase_palm_tree.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.luggage, size: 100, color: AppTheme.primaryPurple);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
