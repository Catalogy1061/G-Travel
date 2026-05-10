import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class ExchangeRateCard extends StatelessWidget {
  final String? currency;
  final String? timezone;

  const ExchangeRateCard({super.key, this.currency, this.timezone});

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
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "INFO LOCAL",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textGrey),
                ),
                currency != null
                  ? Text(
                      "$currency / ${timezone ?? 'Local'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green),
                    )
                  : Container(
                      width: 60, height: 12, 
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
