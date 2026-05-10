import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:g_route_app/services/image_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  TripItinerary? _itinerarioIA;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
    if (cachedRoteiro != null) {
      final itinerario = await RoteiroService.getItinerarioCompleto(cachedRoteiro['id']);
      
      if (mounted && itinerario != null) {
        setState(() {
          _itinerarioIA = itinerario;
          _isLoading = false;
        });

        // Enriquecer com imagens em background se necessário
        final needsImages = itinerario.ticketsEAtracoes.any((t) => t.imageUrl == null || t.imageUrl!.isEmpty);
        if (needsImages) {
          final enriched = await ImageService.enrichItinerary(itinerario);
          if (mounted) {
            setState(() {
              _itinerarioIA = enriched;
            });
            // Opcional: salvar versão enriquecida
            RoteiroService.salvarDadosIA(cachedRoteiro['id'], enriched.toJson());
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ingressos e Atrações",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Garanta seu lugar com os melhores preços oficiais e segurança.",
                style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 25),

              if (_itinerarioIA != null && _itinerarioIA!.ticketsEAtracoes.isNotEmpty) ...[
                const Text(
                  "Sugeridos para sua Viagem",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 15),
                ..._itinerarioIA!.ticketsEAtracoes.map((ticket) => _buildAttractionCard(
                  context,
                  name: ticket.nome,
                  location: ticket.tipo ?? "Atração",
                  price: ticket.custoEstimado ?? "Consulte",
                  imageUrl: ticket.imageUrl ?? "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&q=80&w=1000",
                  tip: ticket.dicaSeguranca ?? "Compre em canais oficiais.",
                  isOfficial: ticket.isOficial,
                  link: ticket.linkOficial,
                )),
              ] else if (!_isLoading) ...[
                _buildEmptyState(),
              ] else ...[
                const Center(child: CircularProgressIndicator()),
              ],

              if (_itinerarioIA != null) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                _buildDocSection(),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Icon(Icons.confirmation_number_outlined, size: 60, color: AppTheme.primaryPurple.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            "Nenhum ingresso sugerido ainda.",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),
          const Text(
            "Gere um novo roteiro para que a IA encontre as melhores atrações para você.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionCard(
    BuildContext context, {
    required String name,
    required String location,
    required String price,
    required String imageUrl,
    required String tip,
    required bool isOfficial,
    String? link,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheHeight: 360,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      isOfficial ? "Preço Oficial" : "Skip-the-line",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textGrey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location, 
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 1,
                      child: Text(
                        price,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Tip Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryPurple, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryPurple,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Affiliate Button
                ElevatedButton(
                  onPressed: () async {
                    if (link != null && link.isNotEmpty) {
                      final uri = Uri.parse(link);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("COMPRAR INGRESSO AGORA", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDocSection() {
    final docs = _itinerarioIA!.destinoInfo.documentacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Documentação e Requisitos",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildDocCard(
              "Visto", 
              docs.vistoObrigatorio ? "Obrigatório" : "Não precisa", 
              docs.vistoObrigatorio ? Icons.assignment_late : Icons.assignment_turned_in,
              docs.vistoObrigatorio ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 12),
            _buildDocCard(
              "Seguro", 
              docs.seguroViagemObrigatorio ? "Obrigatório" : "Recomendado", 
              Icons.security,
              docs.seguroViagemObrigatorio ? Colors.blue : Colors.blueGrey,
            ),
          ],
        ),
        if (docs.vacinasExigidas.isNotEmpty) ...[
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.vaccines, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Vacinas Exigidas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                      Text(
                        docs.vacinasExigidas.join(", "),
                        style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocCard(String title, String status, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
            Text(status, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
