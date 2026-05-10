import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/services/mapbox_service.dart';

class HybridMapWidget extends StatefulWidget {
  final bool isFullScreen;
  final Position? initialCenter;
  final List<Map<String, dynamic>>? points;

  const HybridMapWidget({
    super.key, 
    this.isFullScreen = false,
    this.initialCenter,
    this.points,
  });

  @override
  State<HybridMapWidget> createState() => _HybridMapWidgetState();
}

class _HybridMapWidgetState extends State<HybridMapWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;
  
  String _selectedFilter = 'Todos';
  String _routeProfile = 'driving'; // driving or walking
  final Map<String, List<String>> _filters = {
    'Todos': [],
    'Restaurantes': ['food_and_drink'],
    'Lojas': ['store'],
    'Saúde': ['health_and_care', 'hospital'],
    'Turismo': ['museum', 'attraction', 'park', 'lodging'],
  };

  // Toggle States
  bool _showRoteiro = true;
  bool _showFluxo = false;
  bool _showRisco = false;
  bool _is3DMode = true; // Controle do modo 3D

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPlace;
  bool _isSearchingLoading = false;
  PointAnnotation? _searchMarker;
  PolylineAnnotationManager? _searchPolylineManager;

  @override
  void dispose() {
    _searchController.dispose();
    _mapboxMap = null;
    _pointAnnotationManager = null;
    _polylineAnnotationManager = null;
    _circleAnnotationManager = null;
    _searchPolylineManager = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HybridMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      _drawItinerary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: widget.isFullScreen ? 1 : 0,
          child: Container(
            width: double.infinity,
            height: widget.isFullScreen ? null : 450,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FE),
            ),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: MapWidget(
                    key: const ValueKey("mapbox_map_v2"),
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: widget.initialCenter ?? Position(-46.6559, -23.5615)), // Destino ou Paulista
                      zoom: 15.5,
                      pitch: 60.0, // Ângulo inicial 3D
                      bearing: 45.0,
                    ),
                    onMapCreated: _onMapCreated,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                    },
                  ),
                ),
                
                // Filtros Superiores (Pílulas) corrigidos
                if (widget.isFullScreen)
                  Positioned(
                    top: 65, // Mais para baixo para evitar o notch
                    left: 0,
                    right: 0, // Ocupa toda a tela horizontalmente
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: _filters.keys.length,
                        itemBuilder: (context, index) {
                          final label = _filters.keys.elementAt(index);
                          final isSelected = label == _selectedFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) _applyFilter(label);
                              },
                              backgroundColor: Colors.white.withOpacity(0.9),
                              selectedColor: AppTheme.primaryPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: isSelected ? 4 : 2,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Botões Flutuantes (3D, GPS, Zoom) reposicionados
                Positioned(
                  bottom: widget.isFullScreen ? 280 : 100,
                  right: 15,
                  child: Column(
                    children: [
                      _buildMapActionBtn(_is3DMode ? Icons.map : Icons.threed_rotation, _toggle3D),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(_routeProfile == 'driving' ? Icons.directions_car : Icons.directions_walk, () {
                        setState(() {
                          _routeProfile = _routeProfile == 'driving' ? 'walking' : 'driving';
                        });
                        _drawItinerary();
                      }),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.my_location, _resetCamera),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.add, () => _zoom(true)),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.remove, () => _zoom(false)),
                    ],
                  ),
                ),

                // Botões de Toggle Flutuantes Inferiores (Só no modo FullScreen)
                if (widget.isFullScreen)
                  Positioned(
                    bottom: 130,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Expanded(child: _buildToggleBtn("Roteiro", Icons.route_outlined, _showRoteiro, () {
                          setState(() => _showRoteiro = !_showRoteiro);
                          _drawItinerary();
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _buildToggleBtn("Fluxo", Icons.people_outline, _showFluxo, () => setState(() => _showFluxo = !_showFluxo))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildToggleBtn("Risco", Icons.warning_amber_rounded, _showRisco, () => setState(() => _showRisco = !_showRisco))),
                      ],
                    ),
                  ),
                
                // --- NOVA BUSCA UNIVERSAL (LUPA) ---
                if (widget.isFullScreen)
                  Positioned(
                    top: 60,
                    right: 20,
                    child: _buildSearchTrigger(),
                  ),

                if (_isSearching)
                  Positioned.fill(
                    child: _buildSearchOverlay(),
                  ),
              ],
            ),
          ),
        ),
        
        // Se NÃO for full screen, mostra os botões embaixo como antes (compatibilidade)
        if (!widget.isFullScreen) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildToggleBtn("Roteiro", Icons.route_outlined, _showRoteiro, () => setState(() => _showRoteiro = !_showRoteiro))),
                const SizedBox(width: 8),
                Expanded(child: _buildToggleBtn("Fluxo", Icons.people_outline, _showFluxo, () => setState(() => _showFluxo = !_showFluxo))),
                const SizedBox(width: 8),
                Expanded(child: _buildToggleBtn("Risco", Icons.warning_amber_rounded, _showRisco, () => setState(() => _showRisco = !_showRisco))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    
    // Esconde os ornamentos imediatamente ANTES de carregar o estilo para evitar "piscar" (flicker)
    _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _mapboxMap?.logo.updateSettings(LogoSettings(enabled: false));
    _mapboxMap?.attribution.updateSettings(AttributionSettings(enabled: false));
    _mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));

    // Carrega o novo estilo Mapbox Standard com 3D nativo
    _mapboxMap?.loadStyleURI('mapbox://styles/mapbox/standard').then((_) {
      _initAnnotationManagers();
      
      try {
        // Configura o Mapbox Standard para o modo Escuro e ativa os objetos 3D
        _mapboxMap?.style.setStyleImportConfigProperty('basemap', 'lightPreset', 'dark');
        _mapboxMap?.style.setStyleImportConfigProperty('basemap', 'show3dObjects', true);
      } catch (e) {
        print("Erro ao configurar estilo Standard: $e");
      }

      _drawItinerary();
    });
  }

  void _initAnnotationManagers() async {
    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();
    _circleAnnotationManager = await _mapboxMap?.annotations.createCircleAnnotationManager();
    _searchPolylineManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();
  }

  bool _isDrawing = false;
  Future<void> _drawItinerary() async {
    if (_mapboxMap == null || _pointAnnotationManager == null || _polylineAnnotationManager == null || _circleAnnotationManager == null) return;
    if (_isDrawing) return;
    
    setState(() => _isDrawing = true);

    try {
      // Limpa tudo antes
      await _pointAnnotationManager?.deleteAll();
      await _polylineAnnotationManager?.deleteAll();
      await _circleAnnotationManager?.deleteAll();

      if (!_showRoteiro || widget.points == null || widget.points!.isEmpty) {
        if (mounted) setState(() => _isDrawing = false);
        return;
      }

      print("Desenhando ${widget.points!.length} pontos no itinerário...");

      // 1. Desenhar Marcadores
      for (var i = 0; i < widget.points!.length; i++) {
        final p = widget.points![i];
        final lat = (p['lat'] as num).toDouble();
        final lng = (p['lng'] as num).toDouble();
        final position = Position(lng, lat);
        final isStart = i == 0;

        await _circleAnnotationManager?.create(CircleAnnotationOptions(
          geometry: Point(coordinates: position),
          circleColor: isStart ? Colors.green.value : AppTheme.primaryPurple.value,
          circleRadius: isStart ? 10.0 : 8.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ));
        
        await _pointAnnotationManager?.create(PointAnnotationOptions(
          geometry: Point(coordinates: position),
          textField: p['nome'],
          textColor: Colors.white.value,
          textSize: 12,
          textOffset: [0, 1.5],
          textHaloColor: AppTheme.textDark.value,
          textHaloWidth: 1.0,
        ));
      }

      // 2. Desenhar Rota (Se houver mais de 1 ponto)
      if (widget.points!.length > 1) {
        final waypoints = widget.points!.map((p) => {
          'lng': (p['lng'] as num).toDouble(),
          'lat': (p['lat'] as num).toDouble()
        }).toList();
        
        print("Buscando rota para ${waypoints.length} waypoints no modo $_routeProfile...");
        final routeData = await MapboxService.getRoute(waypoints, profile: _routeProfile);
        
        if (routeData != null && routeData['coordinates'] != null) {
          final coords = (routeData['coordinates'] as List).map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList();
          final lineString = LineString(coordinates: coords);

          await _polylineAnnotationManager?.create(PolylineAnnotationOptions(
            geometry: lineString,
            lineColor: AppTheme.primaryPurple.value,
            lineWidth: 6.0,
            lineOpacity: 0.9,
            lineJoin: LineJoin.ROUND,
          ));

          print("Rota desenhada com sucesso! ${coords.length} pontos.");

          // Ajustar câmera para caber a rota se for a primeira vez ou mudança significativa
          if (widget.isFullScreen) {
            _mapboxMap?.setCamera(CameraOptions(
              center: Point(coordinates: coords.first),
              zoom: 12.0,
            ));
          }
        } else {
          print("Falha ao obter dados da rota do Mapbox Service.");
        }
      }
    } catch (e) {
      print("Erro ao desenhar itinerário: $e");
    } finally {
      if (mounted) setState(() => _isDrawing = false);
    }
  }

  void _applyFilter(String label) {
    setState(() {
      _selectedFilter = label;
    });

    if (_mapboxMap == null) return;

    final classes = _filters[label];
    
    try {
      if (classes == null || classes.isEmpty) {
        // Remove o filtro (Mostra todos os POIs nativos)
        // Se o filtro for uma string vazia ou nula, ele limpa. O formato exato na API Dart:
        _mapboxMap?.style.setStyleLayerProperty('poi-label', 'filter', 'null'); 
      } else {
        // Cria a sintaxe de filtro do Mapbox Expression (JSON)
        // Exemplo: ["in", "class", "food_and_drink", "store"]
        List<dynamic> filterExpression = ["in", ["get", "class"]];
        filterExpression.addAll(classes);
        
        // Em Flutter Mapbox v2, as propriedades complexas podem precisar ser enviadas como JSON string
        // Mas a API Dart pode aceitar a lista diretamente. Vamos tentar string se não funcionar.
        String filterString = '["in", ["get", "class"], ${classes.map((c) => '"$c"').join(',')}]';
        _mapboxMap?.style.setStyleLayerProperty('poi-label', 'filter', filterString);
      }
    } catch (e) {
      print("Erro ao aplicar filtro: $e");
    }
  }

  void _toggle3D() async {
    final currentCamera = await _mapboxMap?.getCameraState();
    if (currentCamera == null) return;
    
    setState(() => _is3DMode = !_is3DMode);
    
    // Anima a câmera suavemente (efeito cinematográfico)
    _mapboxMap?.easeTo(
      CameraOptions(
        pitch: _is3DMode ? 60.0 : 0.0,
        bearing: _is3DMode ? 45.0 : currentCamera.bearing,
      ),
      MapAnimationOptions(duration: 1200), // Duração de 1.2 segundos para suavidade
    );
  }

  void _resetCamera() {
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: widget.initialCenter ?? Position(-46.6559, -23.5615)),
      zoom: 15.0,
      bearing: 0,
      pitch: 0,
    ));
  }

  void _zoom(bool zoomIn) async {
    final currentZoom = await _mapboxMap?.getCameraState().then((s) => s.zoom);
    if (currentZoom != null) {
      _mapboxMap?.setCamera(CameraOptions(zoom: currentZoom + (zoomIn ? 1 : -1)));
    }
  }

  Widget _buildToggleBtn(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryPurple : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? AppTheme.primaryPurple : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : AppTheme.textGrey, size: 18),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppTheme.textDark, size: 20),
        ),
      ),
    );
  }

  // --- SEARCH UI BUILDERS ---

  Widget _buildSearchTrigger() {
    return _buildMapActionBtn(Icons.search, () {
      setState(() {
        _isSearching = true;
        _searchResults = [];
        _searchController.clear();
      });
    });
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textDark),
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Onde você quer ir?",
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isSearching = false),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          // Lista de resultados
          if (_isSearchingLoading)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white)),
          
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final res = _searchResults[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryPurple),
                      title: Text(res['placeName'] ?? 'Local sem nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(res['address'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectSearchResult(res),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onSearchChanged(String val) async {
    if (val.length < 3) return;
    
    setState(() => _isSearchingLoading = true);
    
    // Pega o centro atual do mapa para dar prioridade na busca (Google Maps style)
    final camera = await _mapboxMap?.getCameraState();
    final center = camera?.center;
    
    final results = await MapboxService.searchPlaces(
      val, 
      lat: center?.coordinates.lat.toDouble(), 
      lng: center?.coordinates.lng.toDouble()
    );
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchingLoading = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> res) async {
    setState(() {
      _isSearching = false;
      _selectedPlace = res;
    });

    final lat = (res['lat'] as num).toDouble();
    final lng = (res['lng'] as num).toDouble();
    final position = Position(lng, lat);

    // 1. Zoom no Local
    _mapboxMap?.easeTo(
      CameraOptions(center: Point(coordinates: position), zoom: 16.5, pitch: 45),
      MapAnimationOptions(duration: 1000)
    );

    // 2. Adicionar Marcador de Destaque
    if (_searchMarker != null) {
      await _pointAnnotationManager?.delete(_searchMarker!);
    }
    
    _searchMarker = await _pointAnnotationManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: position),
      textField: res['placeName'],
      textColor: Colors.white.value,
      textSize: 14,
      textOffset: [0, 2],
      textHaloColor: Colors.blueAccent.value,
      textHaloWidth: 2.0,
      iconImage: 'custom-marker', // Pode precisar de uma imagem carregada
    ));

    // 3. Mostrar Bottom Sheet de Detalhes
    _showPlaceDetails(res);
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place['placeName'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 5),
                        Text(place['address'] ?? '', style: const TextStyle(color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.stars, color: Colors.amber, size: 30),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _drawSearchRoute(place);
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text("TRAÇAR ROTA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("FECHAR", style: TextStyle(color: AppTheme.textGrey)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _drawSearchRoute(Map<String, dynamic> destination) async {
    if (_mapboxMap == null || _searchPolylineManager == null) return;

    try {
      // 1. Limpa rota de busca anterior
      await _searchPolylineManager?.deleteAll();

      // 2. Define Origem (Centro atual do mapa como "Local Atual" para o exemplo)
      final camera = await _mapboxMap?.getCameraState();
      if (camera == null) return;

      final origin = {
        'lng': camera.center.coordinates.lng.toDouble(),
        'lat': camera.center.coordinates.lat.toDouble(),
      };

      final dest = {
        'lng': (destination['lng'] as num).toDouble(),
        'lat': (destination['lat'] as num).toDouble(),
      };

      // 3. Busca Rota no Mapbox (Cast explícito para Map<String, double>)
      final routeData = await MapboxService.getRoute([
        Map<String, double>.from(origin), 
        Map<String, double>.from(dest)
      ], profile: 'driving');

      if (routeData != null && routeData['coordinates'] != null) {
        final coords = (routeData['coordinates'] as List)
            .map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble()))
            .toList();

        await _searchPolylineManager?.create(PolylineAnnotationOptions(
          geometry: LineString(coordinates: coords),
          lineColor: Colors.blueAccent.value,
          lineWidth: 5.0,
          lineOpacity: 0.8,
        ));

        // Ajusta câmera para ver a rota
        _mapboxMap?.setCamera(CameraOptions(
          center: Point(coordinates: coords[coords.length ~/ 2]),
          zoom: 13.0,
        ));
      }
    } catch (e) {
      print("Erro ao traçar rota de busca: $e");
    }
  }
}
