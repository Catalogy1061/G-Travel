import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class WeatherWidget extends StatelessWidget {
  final String? temp;
  final String? description;

  const WeatherWidget({super.key, this.temp, this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "CLIMA",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textGrey),
                ),
                temp != null 
                  ? Text(
                      "$temp / ${description ?? 'Clima Local'}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                    )
                  : Container(
                      width: 80, height: 12, 
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
