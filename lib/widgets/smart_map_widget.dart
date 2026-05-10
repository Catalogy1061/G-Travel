import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'dart:typed_data';

class SmartMapWidget extends StatefulWidget {
  const SmartMapWidget({super.key});

  @override
  State<SmartMapWidget> createState() => _SmartMapWidgetState();
}

class _SmartMapWidgetState extends State<SmartMapWidget> with SingleTickerProviderStateMixin {
  bool _showRoteiro = true;
  bool _showMovimentacao = false;
  bool _showPerigo = false;

  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.normal;
  
  late AnimationController _pulseController;
  double _pulseRadius = 0.0;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  Set<Polygon> _polygons = {};

  // Ícone transparente para o marcador "invisível"
  BitmapDescriptor? _transparentIcon;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseController.addListener(() {
      if (_showMovimentacao) {
        setState(() {
          _pulseRadius = 20 + (_pulseController.value * 30);
          _updateLayers();
        });
      }
    });

    _createTransparentIcon();
    _updateLayers();
  }

  // Cria um pixel transparente para esconder o marcador mas manter o balão
  Future<void> _createTransparentIcon() async {
    final Uint8List transparentBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x00, 0x00,
      0x02, 0x00, 0x01, 0x73, 0x75, 0x01, 0x18, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82
    ]);
    _transparentIcon = BitmapDescriptor.fromBytes(transparentBytes);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.5615, -46.6559), // Avenida Paulista, SP
    zoom: 15,
  );

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
  }

  void _setMapStyle() {
    String style = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
      {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
      {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
      {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
      {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
      {"featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
      {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]}
    ]
    ''';
    _mapController.setMapStyle(style);
  }

  void _updateLayers() {
    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};
    final Set<Circle> newCircles = {};
    final Set<Polygon> newPolygons = {};

    if (_showRoteiro) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route1'),
          color: AppTheme.primaryPurple,
          width: 5,
          points: const [
            LatLng(-23.5615, -46.6559),
            LatLng(-23.5625, -46.6549),
            LatLng(-23.5635, -46.6539),
            LatLng(-23.5645, -46.6529),
          ],
        ),
      );
      newMarkers.add(
        const Marker(
          markerId: MarkerId('end_point'),
          position: LatLng(-23.5645, -46.6529),
        ),
      );
    }

    if (_showMovimentacao) {
      final List<LatLng> flowPoints = [
        const LatLng(-23.5615, -46.6559),
        const LatLng(-23.5620, -46.6550),
        const LatLng(-23.5610, -46.6565),
        const LatLng(-23.5605, -46.6545),
      ];

      for (int i = 0; i < flowPoints.length; i++) {
        newCircles.add(
          Circle(
            circleId: CircleId('flow_$i'),
            center: flowPoints[i],
            radius: _pulseRadius,
            fillColor: Colors.purple.withOpacity(0.3),
            strokeWidth: 2,
            strokeColor: Colors.purple.withOpacity(0.1),
          ),
        );
      }

      // Adiciona um marcador informativo para o Fluxo
      newMarkers.add(
        Marker(
          markerId: const MarkerId('flow_info_marker'),
          position: flowPoints[0],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(
            title: "Fluxo em Tempo Real",
            snippet: "Movimentação de pessoas detectada agora.",
          ),
        ),
      );
    }

    if (_showPerigo) {
      newPolygons.add(
        Polygon(
          polygonId: const PolygonId('risk_zone'),
          points: const [
            LatLng(-23.5625, -46.6575),
            LatLng(-23.5635, -46.6585),
            LatLng(-23.5645, -46.6570),
            LatLng(-23.5630, -46.6560),
          ],
          fillColor: Colors.red.withOpacity(0.25),
          strokeColor: Colors.red.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
      
      // Marcador para ancorar o InfoWindow (Usando amarelo para ser discreto)
      newMarkers.add(
        Marker(
          markerId: const MarkerId('danger_marker_1'),
          position: const LatLng(-23.5635, -46.6575),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(
            title: "Zona de Atenção",
            snippet: "Alta incidência de furtos nesta área.",
          ),
        ),
      );
    }

    _markers = newMarkers;
    _polylines = newPolylines;
    _circles = newCircles;
    _polygons = newPolygons;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 450,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E3DF),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  polylines: _polylines,
                  circles: _circles,
                  polygons: _polygons,
                  mapType: _currentMapType,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                ),
                
                // Botões de Controle Restaurados
                Positioned(
                  top: 15,
                  right: 15,
                  child: Column(
                    children: [
                      _buildMapActionBtn(Icons.my_location, () {
                        _mapController.animateCamera(
                          CameraUpdate.newCameraPosition(_initialPosition),
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.layers_outlined, () {
                        setState(() {
                          _currentMapType = _currentMapType == MapType.normal
                              ? MapType.satellite
                              : _currentMapType == MapType.satellite
                                  ? MapType.terrain
                                  : MapType.normal;
                        });
                      }),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.add, () {
                        _mapController.animateCamera(CameraUpdate.zoomIn());
                      }),
                      const SizedBox(height: 8),
                      _buildMapActionBtn(Icons.remove, () {
                        _mapController.animateCamera(CameraUpdate.zoomOut());
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleBtn(
                  "Roteiro",
                  Icons.route_outlined,
                  _showRoteiro,
                  () {
                    setState(() {
                      _showRoteiro = !_showRoteiro;
                      _updateLayers();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleBtn(
                  "Fluxo",
                  Icons.people_outline,
                  _showMovimentacao,
                  () async {
                    setState(() {
                      _showMovimentacao = !_showMovimentacao;
                      _updateLayers();
                    });

                    if (_showMovimentacao) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted && _showMovimentacao) {
                        _mapController.showMarkerInfoWindow(const MarkerId('flow_info_marker'));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleBtn(
                  "Risco",
                  Icons.warning_amber_rounded,
                  _showPerigo,
                  () async {
                    setState(() {
                      _showPerigo = !_showPerigo;
                      _updateLayers();
                    });
                    
                    if (_showPerigo) {
                      // Espera a animação da câmera e um pequeno frame para garantir que o marcador foi registrado no mapa
                      await _mapController.animateCamera(
                        CameraUpdate.newLatLng(const LatLng(-23.5635, -46.6575)),
                      );
                      
                      // Pequeno delay adicional para garantir o registro no SDK nativo
                      await Future.delayed(const Duration(milliseconds: 300));
                      
                      if (mounted && _showPerigo) {
                        _mapController.showMarkerInfoWindow(const MarkerId('danger_marker_1'));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? AppTheme.primaryPurple : const Color(0xFFEEEEEE),
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : AppTheme.textGrey, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
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
}
