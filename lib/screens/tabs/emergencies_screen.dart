import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/globals.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';

class EmergenciesScreen extends StatefulWidget {
  final TripItinerary? itinerarioIA;
  const EmergenciesScreen({super.key, this.itinerarioIA});

  @override
  State<EmergenciesScreen> createState() => _EmergenciesScreenState();
}

class _EmergenciesScreenState extends State<EmergenciesScreen> {
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
  void didUpdateWidget(covariant EmergenciesScreen oldWidget) {
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Emergências",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Contatos e hospitais úteis no seu destino.",
                    style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 30),

                  // 1. NÚMEROS DE EMERGÊNCIA
                  _buildEmergencySection(
                    title: "Números Locais",
                    items: _itinerarioIA != null 
                      ? _itinerarioIA!.guiaLocal.saudeEmergencia.telefones.entries.map((e) {
                          return _EmergencyItem(
                            label: e.key.toUpperCase(), 
                            number: e.value, 
                            icon: e.key.toLowerCase().contains('pol') ? Icons.local_police : Icons.medical_services
                          );
                        }).toList()
                      : [
                          _EmergencyItem(label: "Polícia / Geral", number: "112", icon: Icons.local_police_rounded),
                          _EmergencyItem(label: "Ambulância", number: "192", icon: Icons.medical_services_rounded),
                        ],
                  ),

                  const SizedBox(height: 30),

                  // 2. ALERTAS DE SEGURANÇA
                  if (_itinerarioIA != null) ...[
                    _buildSectionTitle("Alertas de Segurança"),
                    const SizedBox(height: 15),
                    _buildSecurityAlertsCard(),
                    const SizedBox(height: 30),
                  ],

                  // 3. HOSPITAIS PRÓXIMOS
                  _buildSectionTitle("Saúde e Hospitais"),
                  const SizedBox(height: 15),
                  if (_itinerarioIA != null)
                    ..._itinerarioIA!.guiaLocal.saudeEmergencia.hospitaisProximos.map((h) => _buildActionCard(
                      title: h,
                      subtitle: "Hospital de Referência",
                      icon: Icons.local_hospital_rounded,
                      color: Colors.redAccent,
                      action: "ABRIR MAPA",
                    )).toList()
                  else
                    _buildActionCard(
                      title: "Buscando hospitais...",
                      subtitle: "Aguardando dados da IA",
                      icon: Icons.local_hospital_rounded,
                      color: Colors.redAccent,
                      action: "ABRIR MAPA",
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSOSToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: Globals.sosActive,
        builder: (context, isActive, child) {
          return SwitchListTile(
            title: const Text("Botão SOS Emergencial", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: const Text("Ativa botão flutuante em todas as telas", style: TextStyle(fontSize: 12)),
            secondary: Icon(isActive ? Icons.emergency_share : Icons.emergency_outlined, color: isActive ? Colors.red : AppTheme.textGrey),
            value: isActive,
            activeColor: Colors.red,
            onChanged: (value) => Globals.sosActive.value = value,
          );
        },
      ),
    );
  }

  Widget _buildEmergencySection({required String title, required List<_EmergencyItem> items}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 15),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                Icon(item.icon, color: Colors.red),
                const SizedBox(width: 15),
                Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text(item.number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSecurityAlertsCard() {
    final seguranca = _itinerarioIA!.guiaLocal.seguranca;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.amber.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Text("Nível de Alerta: ${seguranca.nivelAlerta}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Áreas a evitar:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(seguranca.bairrosPerigosos.join(", "), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          const Text("Golpes comuns:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(seguranca.golpesComuns.join(", "), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark));
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required String action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey))])),
          TextButton(onPressed: () {}, child: Text(action, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }
}

class _EmergencyItem {
  final String label;
  final String number;
  final IconData icon;
  _EmergencyItem({required this.label, required this.number, required this.icon});
}
