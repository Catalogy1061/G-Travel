import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';

class ComercioLocalScreen extends StatefulWidget {
  const ComercioLocalScreen({super.key});

  @override
  State<ComercioLocalScreen> createState() => _ComercioLocalScreenState();
}

class _ComercioLocalScreenState extends State<ComercioLocalScreen> {
  TripItinerary? _itinerarioIA;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool force = false}) async {
    if (force) setState(() => _isLoading = true);
    
    final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
    if (cachedRoteiro != null) {
      final itinerario = await RoteiroService.getItinerarioCompleto(
        cachedRoteiro['id'].toString(),
        forceRefresh: force,
      );
      if (mounted) {
        setState(() {
          _itinerarioIA = itinerario;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : RefreshIndicator(
            onRefresh: () => _loadData(force: true),
            color: AppTheme.primaryPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Comércio e Utilidades",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Encontre o que você precisa ao seu redor.",
                    style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 25),
                  
                  if (_itinerarioIA != null) ...[
                    _buildSectionTitle("Supermercados Baratos"),
                    const SizedBox(height: 15),
                    ..._itinerarioIA!.comercioEUtilidades.supermercadosBaratos.map((s) => _buildUtilityCard(
                      title: s,
                      subtitle: "Rede de Supermercado Recomendada",
                      icon: Icons.shopping_cart_rounded,
                      color: Colors.green,
                    )).toList(),

                    const SizedBox(height: 30),

                    _buildSectionTitle("Áreas de Compras"),
                    const SizedBox(height: 15),
                    _buildTextCard(
                      _itinerarioIA!.comercioEUtilidades.melhoresAreasCompras,
                      Icons.store_rounded,
                      Colors.orange,
                    ),

                    const SizedBox(height: 30),

                    _buildSectionTitle("Lojas de Conveniência"),
                    const SizedBox(height: 15),
                    _buildTextCard(
                      _itinerarioIA!.comercioEUtilidades.lojasConveniencia,
                      Icons.access_time_filled_rounded,
                      Colors.blue,
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text("Nenhum dado disponível."),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
    );
  }

  Widget _buildUtilityCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
