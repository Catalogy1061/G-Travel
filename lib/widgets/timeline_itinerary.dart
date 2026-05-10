import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class TimelineItinerary extends StatelessWidget {
  const TimelineItinerary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text(
              "Dia 1: Lisboa",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 2,
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildTimelineItem("09:00", "Torre de Belém"),
                      const SizedBox(height: 15),
                      _buildTimelineItem("11:00", "Mosteiro dos Jerónimos"),
                      const SizedBox(height: 15),
                      _buildInsiderTip(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String time, String title) {
    return Row(
      children: [
        Text(time, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        const SizedBox(width: 15),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildInsiderTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DICA INSIDER",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            "Dica: Compre o ticket na livraria ao lado, com comprar a ticket na entrada da nando o cante de a módulo aito.",
            style: TextStyle(fontSize: 11, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
