import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class LocalGuideScreen extends StatefulWidget {
  const LocalGuideScreen({super.key});

  @override
  State<LocalGuideScreen> createState() => _LocalGuideScreenState();
}

class _LocalGuideScreenState extends State<LocalGuideScreen> {
  String _selectedSegment = "Todos";

  final List<Map<String, dynamic>> _establishments = [
    {
      "name": "Café Central",
      "type": "Café",
      "rating": 4.8,
      "distance": "200m",
      "icon": Icons.coffee,
      "color": Colors.brown,
    },
    {
      "name": "La Trattoria",
      "type": "Restaurante",
      "rating": 4.5,
      "distance": "450m",
      "icon": Icons.restaurant,
      "color": Colors.orange,
    },
    {
      "name": "Pingo Doce",
      "type": "Supermercado",
      "rating": 4.2,
      "distance": "600m",
      "icon": Icons.shopping_cart,
      "color": Colors.blue,
    },
    {
      "name": "Farmácia Saúde",
      "type": "Farmácia",
      "rating": 4.9,
      "distance": "150m",
      "icon": Icons.local_pharmacy,
      "color": Colors.red,
    },
    {
      "name": "Sushi House",
      "type": "Restaurante",
      "rating": 4.7,
      "distance": "800m",
      "icon": Icons.restaurant,
      "color": Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = _selectedSegment == "Todos"
        ? _establishments
        : _establishments.where((e) => e['type'] == _selectedSegment).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Guia Local",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Encontre o que você precisa ao seu redor.",
                  style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          
          // Horizontal Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip("Todos"),
                _buildFilterChip("Restaurante"),
                _buildFilterChip("Café"),
                _buildFilterChip("Supermercado"),
                _buildFilterChip("Farmácia"),
              ],
            ),
          ),

          // List of Establishments
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _buildEstablishmentCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedSegment == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSegment = label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : const Color(0xFFEEEEEE),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEstablishmentCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item['icon'], color: item['color'], size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item['type'],
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, size: 4, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      item['rating'].toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['distance'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textGrey),
            ],
          ),
        ],
      ),
    );
  }
}
