import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RESUMO FINANCEIRO",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 15),
            _buildExpenseRow("Alimentação", 0.7, Colors.orange, "R\$ 14,00"),
            const SizedBox(height: 10),
            _buildExpenseRow("Transporte", 0.4, Colors.blue, "R\$ 9,00"),
            const SizedBox(height: 10),
            _buildExpenseRow("Lazer", 0.3, Colors.green, "R\$ 6,00"),
            const SizedBox(height: 15),
            const Text("Valores estimados", style: TextStyle(fontSize: 10, color: AppTheme.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseRow(String label, double percent, Color color, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
