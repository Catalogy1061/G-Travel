import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HospedagemScreen extends StatefulWidget {
  final TripItinerary? itinerarioIA;
  const HospedagemScreen({super.key, this.itinerarioIA});

  @override
  State<HospedagemScreen> createState() => _HospedagemScreenState();
}

class _HospedagemScreenState extends State<HospedagemScreen> {
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
  void didUpdateWidget(covariant HospedagemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerarioIA != oldWidget.itinerarioIA) {
      setState(() {
        _itinerarioIA = widget.itinerarioIA;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData({bool force = false}) async {
    // Só mostramos o loading se não houver dados e não for um refresh forçado
    if (_itinerarioIA == null || force) {
      setState(() => _isLoading = true);
    }

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
    final hospedagem = _itinerarioIA?.hospedagem;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading && _itinerarioIA == null
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : RefreshIndicator(
            onRefresh: () => _loadData(force: true),
            color: AppTheme.primaryPurple,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppTheme.primaryPurple,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text("Hospedagem", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                    background: hospedagem?.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: hospedagem!.imageUrl!, 
                          fit: BoxFit.cover,
                          memCacheHeight: 400,
                          placeholder: (context, url) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF9042F5)]),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF9042F5)]),
                            ),
                            child: const Icon(Icons.hotel_rounded, size: 80, color: Colors.white24),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF9042F5)]),
                          ),
                          child: const Icon(Icons.hotel_rounded, size: 80, color: Colors.white24),
                        ),
                  ),
                ),

                if (hospedagem == null || (hospedagem.status == 'confirmada' && (hospedagem.nome == null || hospedagem.nome!.isEmpty)))
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text("Hospedagem confirmada pelo usuário", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                          const SizedBox(height: 8),
                          const Text("Nenhuma sugestão necessária.", style: TextStyle(fontSize: 14, color: AppTheme.textGrey)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildInfoCard(hospedagem),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Por que escolher este local?"),
                        const SizedBox(height: 12),
                        _buildInsightCard(hospedagem.motivoSugestao ?? "Sugestão baseada no seu perfil de viajante."),
                        const SizedBox(height: 30),
                        _buildActionButtons(hospedagem),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard(Hospedagem h) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(h.nome ?? "Hotel Sugerido", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(h.nivel ?? "Médio", style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(h.tipo ?? "Hospedagem", style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.location_on_rounded, h.endereco ?? "Endereço não informado"),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.payments_rounded, h.custoEstimado ?? "Preço sob consulta"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryPurple),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textDark))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark));
  }

  Widget _buildInsightCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Colors.blue),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.blue, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Hospedagem h) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {}, // Abrir no Google Maps
            icon: const Icon(Icons.map_rounded),
            label: const Text("VER NO MAPA"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (h.linkReferencia != null && h.linkReferencia!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(h.linkReferencia!)),
              icon: const Icon(Icons.language_rounded),
              label: const Text("SITE OFICIAL / RESERVA"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                side: const BorderSide(color: AppTheme.primaryPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
      ],
    );
  }
}
