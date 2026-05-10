import 'package:flutter/material.dart';
import 'package:g_route_app/widgets/hybrid_map_widget.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String _selectedMode = 'Roteiro';
  List<Map<String, dynamic>> _pontosRoteiro = [];
  Map<String, dynamic>? _roteiroAtivo;
  bool _isLoading = true;
  double? _centerLat;
  double? _centerLng;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await _loadCachedData();
    _carregarDados();
  }

  Future<void> _loadCachedData() async {
    final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
    if (cachedRoteiro != null) {
      final roteiro = Map<String, dynamic>.from(cachedRoteiro);
      final cachedPoints = await CacheService.getData('pontos_${roteiro['id']}');

      if (mounted) {
        setState(() {
          _roteiroAtivo = roteiro;
          if (cachedPoints != null) {
            _pontosRoteiro = (cachedPoints as List).map((i) => Map<String, dynamic>.from(i)).toList();
          }
          _centerLat = (roteiro['lat'] as num?)?.toDouble() ?? 0.0;
          _centerLng = (roteiro['lng'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final roteiros = await RoteiroService.fetchRoteiros();
    
    if (roteiros.isNotEmpty) {
      final roteiro = roteiros.first;
      final pontos = await RoteiroService.fetchPontos(roteiro['id']);
      
      setState(() {
        _roteiroAtivo = roteiro; // Armazena o roteiro ativo
        _pontosRoteiro = pontos;
        _centerLat = (roteiro['lat'] as num?)?.toDouble() ?? 0.0;
        _centerLng = (roteiro['lng'] as num?)?.toDouble() ?? 0.0;
        _isLoading = false;
      });

      // Salva no cache local
      CacheService.saveData(CacheService.KEY_ACTIVE_ITINERARY, roteiro);
      CacheService.saveData('pontos_${roteiro['id']}', pontos);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarPonto(Map<String, dynamic> poi) async {
    // Função removida a pedido do usuário: busca no mapa agora é apenas para navegação/visualização
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          HybridMapWidget(
            isFullScreen: true,
            initialCenter: _centerLat != null ? Position(_centerLng!, _centerLat!) : null,
            points: _selectedMode == 'Roteiro' ? _pontosRoteiro : [],
          ),

          // Indicador de Carregamento
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.textGrey),
              const SizedBox(width: 8),
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
