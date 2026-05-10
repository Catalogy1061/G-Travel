import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';

class DicasScreen extends StatefulWidget {
  final TripItinerary? itinerarioIA;
  const DicasScreen({super.key, this.itinerarioIA});

  @override
  State<DicasScreen> createState() => _DicasScreenState();
}

class _DicasScreenState extends State<DicasScreen> {
  TripItinerary? _itinerarioIA;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _itinerarioIA = widget.itinerarioIA;
    _isLoading = _itinerarioIA == null;
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DicasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerarioIA != oldWidget.itinerarioIA) {
      setState(() {
        _itinerarioIA = widget.itinerarioIA;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData({bool force = false}) async {
    if (_itinerarioIA != null && !force) {
      setState(() => _isLoading = false);
      return;
    }

    final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
    if (cachedRoteiro != null) {
      final itinerario = await RoteiroService.getItinerarioCompleto(cachedRoteiro['id'].toString());
      if (mounted) {
        setState(() {
          _itinerarioIA = itinerario;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _itinerarioIA = null;
          _isLoading = false;
        });
      }
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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  backgroundColor: AppTheme.bgLight,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text("Dicas e Hacks", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                    centerTitle: true,
                  ),
                ),

                if (_itinerarioIA != null)
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTipSection(
                          title: "Dicas Locais",
                          icon: Icons.lightbulb_outline_rounded,
                          iconColor: Colors.amber,
                          tips: _itinerarioIA!.dicasLocais,
                        ),
                        _buildTipSection(
                          title: "Etiqueta e Cultura",
                          icon: Icons.translate_rounded,
                          iconColor: AppTheme.primaryPurple,
                          tips: [
                            "Regras Sociais: ${_itinerarioIA!.guiaLocal.etiquetaECultura.regrasSociais}",
                            ..._itinerarioIA!.guiaLocal.etiquetaECultura.frasesSobrevivencia.entries.map((e) => "${e.key}: ${e.value}"),
                          ],
                        ),
                        _buildTipSection(
                          title: "Segurança",
                          icon: Icons.security_rounded,
                          iconColor: Colors.redAccent,
                          tips: [
                            "Nível de Alerta: ${_itinerarioIA!.guiaLocal.seguranca.nivelAlerta}",
                            "Golpes Comuns: ${_itinerarioIA!.guiaLocal.seguranca.golpesComuns.join(', ')}",
                            "Áreas a evitar: ${_itinerarioIA!.guiaLocal.seguranca.bairrosPerigosos.join(', ')}",
                          ],
                        ),
                      ]),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: Center(child: Text("Nenhuma dica disponível."))),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
    );
  }

  Widget _buildTipSection({required String title, required IconData icon, required Color iconColor, required List<String> tips}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
                const SizedBox(width: 15),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: tips.map((tip) => _buildTipItem(tip)).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle)),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.5))),
        ],
      ),
    );
  }
}
