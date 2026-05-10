import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LogisticsScreen extends StatefulWidget {
  final TripItinerary? itinerarioIA;
  const LogisticsScreen({super.key, this.itinerarioIA});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
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
  void didUpdateWidget(covariant LogisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerarioIA != oldWidget.itinerarioIA) {
      setState(() {
        _itinerarioIA = widget.itinerarioIA;
        _isLoading = _itinerarioIA == null && widget.itinerarioIA != null;
      });
    }
  }

  Future<void> _loadData() async {
    if (_itinerarioIA != null) {
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
            onRefresh: _loadData,
            color: AppTheme.primaryPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transporte e Logística",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mova-se com inteligência pelo seu destino.",
                    style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 25),

                  // 1. CHEGADA AO DESTINO
                  _buildSectionTitle("Como Chegar do Aeroporto"),
                  const SizedBox(height: 15),
                  _buildArrivalCard(),

                  const SizedBox(height: 30),

                  // 2. MOBILIDADE LOCAL
                  _buildSectionTitle("Como se locomover"),
                  const SizedBox(height: 15),
                  _buildInternalMobilityCard(),

                  const SizedBox(height: 30),

                  // 3. STATUS EM TEMPO REAL
                  _buildSectionTitle("Status em Tempo Real"),
                  const SizedBox(height: 15),
                  _buildRealTimeStatusCard(),

                  const SizedBox(height: 30),

                  // 4. DICAS DE ECONOMIA
                  _buildSectionTitle("Dicas de Economia"),
                  const SizedBox(height: 15),
                  _buildEconomyTipsCard(),

                  const SizedBox(height: 30),

                  // 5. LOCAÇÃO DE VEÍCULOS
                  if (_itinerarioIA?.logistica.opcoesLocacao.isNotEmpty ?? false) ...[
                    _buildSectionTitle("Locação de Veículos e Motos"),
                    const SizedBox(height: 15),
                    ..._itinerarioIA!.logistica.opcoesLocacao.map((l) => _buildRentalCard(l)).toList(),
                  ],

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

  Widget _buildArrivalCard() {
    if (_itinerarioIA == null) return const SizedBox.shrink();
    final chegada = _itinerarioIA!.logistica.chegada;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_land, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chegada.aeroportoPrincipal, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...chegada.transporteParaCentro.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.directions_bus, color: Colors.white70, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInternalMobilityCard() {
    if (_itinerarioIA == null) return const SizedBox.shrink();
    final interna = _itinerarioIA!.logistica.locomocaoInterna;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildMobilityRow(Icons.phone_android_rounded, "Melhor App", interna.melhorApp, Colors.blue),
          const Divider(height: 30),
          _buildMobilityRow(Icons.confirmation_number_outlined, "Passe Sugerido", interna.passeTransporte, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMobilityRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_protected_setup, color: Colors.green),
          const SizedBox(width: 15),
          Text("Sistemas operando normalmente", style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEconomyTipsCard() {
    if (_itinerarioIA == null) return const SizedBox.shrink();
    final interna = _itinerarioIA!.logistica.locomocaoInterna;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.savings_outlined, color: Colors.green),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              interna.dicaEconomia,
              style: const TextStyle(color: Colors.green, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(LocadoraOpcao locadora) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                  locadora.tipoVeiculo?.toLowerCase().contains('moto') ?? false 
                    ? Icons.motorcycle 
                    : Icons.directions_car, 
                  color: AppTheme.primaryPurple, 
                  size: 20
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locadora.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (locadora.tipoVeiculo != null)
                      Text(locadora.tipoVeiculo!, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          if (locadora.endereco != null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                Expanded(child: Text(locadora.endereco!, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey))),
              ],
            ),
          ],
          if (locadora.siteOficial != null) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse(locadora.siteOficial!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                  foregroundColor: AppTheme.primaryPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Visitar Site Oficial", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
