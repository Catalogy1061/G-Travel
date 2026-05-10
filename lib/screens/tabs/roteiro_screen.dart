import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/mapbox_service.dart';
import 'package:g_route_app/services/gemini_service.dart';
import 'package:g_route_app/services/google_places_service.dart';
import 'package:g_route_app/services/fridge_service.dart';
import 'package:g_route_app/services/history_service.dart';
import 'package:g_route_app/models/fridge_model.dart';
import 'package:uuid/uuid.dart';
import 'package:g_route_app/services/image_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:g_route_app/widgets/hybrid_map_widget.dart';
import 'package:g_route_app/widgets/clay_magnet_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:g_route_app/screens/criar_roteiro_screen.dart';
import 'package:g_route_app/models/itinerary_model.dart';
import 'package:g_route_app/widgets/travel_loading_widget.dart';

class RoteiroScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RoteiroScreen({super.key, this.onRefresh});

  @override
  State<RoteiroScreen> createState() => _RoteiroScreenState();
}

class _RoteiroScreenState extends State<RoteiroScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _roteiroAtivo;
  TripItinerary? _itinerarioIA;
  List<Map<String, dynamic>> _meusPontos = [];
  List<Map<String, dynamic>> _sugestoes = []; 
  List<Map<String, dynamic>> _searchResults = []; 
  String? _cityImageUrl;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
      final cachedVisuals = await CacheService.getData('visuals_${roteiro['destino'].toLowerCase().trim()}');
      final cachedPois = await CacheService.getData('pois_${roteiro['destino'].toLowerCase().trim()}');

      if (mounted) {
        setState(() {
          _roteiroAtivo = roteiro;
          if (cachedPoints != null) _meusPontos = (cachedPoints as List).map((i) => Map<String, dynamic>.from(i)).toList();
          if (cachedVisuals != null) _cityImageUrl = cachedVisuals['image'];
          if (cachedPois != null) _sugestoes = (cachedPois as List).map((i) => Map<String, dynamic>.from(i)).toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    // Só mostramos o loading se ainda não tivermos dados (nem cache, nem estado anterior)
    if (_roteiroAtivo == null) {
      setState(() => _isLoading = true);
    }
    
    final roteiros = await RoteiroService.fetchRoteiros();
    
    if (roteiros.isNotEmpty) {
      final roteiro = roteiros.first;
      final visuals = await ImageService.getCityVisuals(roteiro['destino']);
      final pontos = await RoteiroService.fetchPontos(roteiro['id'].toString());
      
      final lat = (roteiro['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (roteiro['lng'] as num?)?.toDouble() ?? 0.0;
      final sugestoes = await ImageService.getEnrichedPOIs(lat, lng, cityName: roteiro['destino']);
      final itinerario = await RoteiroService.getItinerarioCompleto(roteiro['id'].toString());

      if (mounted) {
        setState(() {
          _roteiroAtivo = roteiro;
          _cityImageUrl = visuals['image'];
          _meusPontos = pontos;
          _sugestoes = sugestoes;
          _isLoading = false;
        });

        // Enriquecer o itinerário com imagens em background
        if (itinerario != null) {
          ImageService.enrichItinerary(itinerario).then((enriched) {
            if (mounted) {
              setState(() {
                _itinerarioIA = enriched;
              });
            }
          });
        }
        
        CacheService.saveData(CacheService.KEY_ACTIVE_ITINERARY, roteiro);
        CacheService.saveData('pontos_${roteiro['id']}', pontos);
      }
    } else {
      if (mounted) {
        setState(() {
          _roteiroAtivo = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _adicionarPonto(Map<String, dynamic> poi) async {
    if (_roteiroAtivo == null) return;

    final success = await RoteiroService.salvarPonto(
      roteiroId: _roteiroAtivo!['id'],
      nome: poi['name'],
      lat: poi['lat'],
      lng: poi['lng'],
      categoria: poi['category'],
    );

    if (success) {
      _carregarDados();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${poi['name']} adicionado!')));
    }
  }

  Future<void> _removerPonto(String id) async {
    final success = await RoteiroService.deletarPonto(id);
    if (success) _carregarDados();
  }

  Future<void> _concluirViagem() async {
    if (_itinerarioIA == null || _roteiroAtivo == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Concluir Viagem'),
        content: const Text('Ao concluir, este roteiro será removido da tela principal e movido para o seu Histórico de Viagens. Além disso, você ganhará um Imã de Geladeira!\n\nDeseja concluir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Concluir', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: TravelLoadingWidget(size: 150, showIcons: false)),
    );

    try {
      final options = await GeminiService.getClayMagnetOptions(_itinerarioIA!.configuracaoUsuario.destinoSolicitado);
      
      if (mounted) Navigator.pop(context);

      if (options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao carregar imãs. Tente novamente.")));
        return;
      }

      _showMagnetSelectionDialog(options);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Erro ao concluir viagem: $e');
    }
  }

  void _showMagnetSelectionDialog(List<Map<String, String>> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
            SizedBox(height: 10),
            Text("Viagem Concluída!", textAlign: TextAlign.center),
            Text("Escolha seu imã de lembrança", style: TextStyle(fontSize: 14, color: AppTheme.textGrey), textAlign: TextAlign.center),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              return GestureDetector(
                onTap: () async {
                  final magnet = FridgeMagnet(
                    id: const Uuid().v4(),
                    destination: opt['name']!,
                    emoji: opt['emoji']!,
                    colorHex: opt['colorHex']!,
                  );
                  
                  // Fecha o diálogo de seleção de imãs usando o contexto atual do item
                  Navigator.pop(context);
                  
                  if (!mounted) return;
                  
                  // Mostra o loading usando o contexto principal da tela
                  showDialog(
                    context: this.context,
                    barrierDismissible: false,
                    builder: (loadingContext) => const Center(child: TravelLoadingWidget(size: 150, showIcons: false)),
                  );
                  
                  await FridgeService.addMagnet(magnet);
                  await HistoryService.saveHistory(
                    destination: _itinerarioIA!.configuracaoUsuario.destinoSolicitado,
                    style: _itinerarioIA!.configuracaoUsuario.perfil,
                    budget: _roteiroAtivo!['orcamento'] != null ? (_roteiroAtivo!['orcamento'] as num).toDouble() : null,
                    startDate: _roteiroAtivo!['data_inicio'] != null ? DateTime.parse(_roteiroAtivo!['data_inicio']) : null,
                    endDate: _roteiroAtivo!['data_fim'] != null ? DateTime.parse(_roteiroAtivo!['data_fim']) : null,
                    profile: _itinerarioIA!.configuracaoUsuario.perfil,
                    days: _itinerarioIA!.roteiroDiario.length,
                  );

                  await RoteiroService.deletarRoteiro(_roteiroAtivo!['id'].toString());
                  await CacheService.removeData(CacheService.KEY_ACTIVE_ITINERARY);
                  
                  if (mounted) {
                    // Fecha o loading usando o contexto principal da tela
                    Navigator.pop(this.context);
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("Viagem salva no histórico! Imã adicionado à geladeira.")));
                    _carregarDados();
                    if (widget.onRefresh != null) widget.onRefresh!();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClayMagnetWidget(
                        magnet: FridgeMagnet(
                          id: 'preview_$index',
                          destination: opt['name']!,
                          emoji: opt['emoji']!,
                          colorHex: opt['colorHex']!,
                        ),
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(opt['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: TravelLoadingWidget(size: 200)));

    if (_roteiroAtivo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Roteiro', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0),
        body: _buildEmptyState(),
      );
    }

    final currentLat = (_roteiroAtivo!['lat'] as num?)?.toDouble() ?? 0.0;
    final currentLng = (_roteiroAtivo!['lng'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cityImageUrl != null)
                      CachedNetworkImage(
                        imageUrl: _cityImageUrl!,
                        fit: BoxFit.cover,
                        memCacheHeight: 400,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.7)]))),
                  ],
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_roteiroAtivo!['destino'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    if (_itinerarioIA != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: Text(_itinerarioIA!.configuracaoUsuario.perfil.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                  ],
                ),
              ),
            ),

            if (_itinerarioIA != null) SliverToBoxAdapter(child: _buildAITimeline()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                child: Row(
                  children: [
                    const Text("Locais Adicionados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text("${_meusPontos.length} locais", style: const TextStyle(color: AppTheme.textGrey)),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ponto = _meusPontos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppTheme.primaryPurple.withOpacity(0.1), child: const Icon(Icons.location_on, color: AppTheme.primaryPurple, size: 20)),
                      title: Text(ponto['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(ponto['categoria'] ?? 'Ponto Turístico'),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removerPonto(ponto['id'])),
                    ),
                  );
                },
                childCount: _meusPontos.length,
              ),
            ),

            if (_meusPontos.isEmpty) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("Nenhum local adicionado ainda.", style: TextStyle(color: AppTheme.textGrey))))),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _isSearching = val.isNotEmpty);
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () async {
                      if (val.length > 2) {
                        double offset = 0.15;
                        String bbox = '${currentLng - offset},${currentLat - offset},${currentLng + offset},${currentLat + offset}';
                        final results = await MapboxService.searchPlaces(val, lat: currentLat, lng: currentLng, bbox: bbox);
                        final enriched = await ImageService.enrichPlaces(results);
                        if (mounted) setState(() => _searchResults = enriched);
                      } else {
                        setState(() => _searchResults = []);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Onde você quer ir em ${_roteiroAtivo!['destino']}?",
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                    suffixIcon: _isSearching ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() { _isSearching = false; _searchResults = []; }); }) : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade100)),
                  ),
                ),
              ),
            ),

            if (_searchResults.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text("Resultados da Busca", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                    SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _searchResults.length, itemBuilder: (context, index) => _buildSearchMiniCard(_searchResults[index]))),
                    const Divider(indent: 20, endIndent: 20),
                  ],
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: Row(children: [const Icon(Icons.star_outline, color: AppTheme.primaryPurple, size: 24), const SizedBox(width: 8), Text("Mais Visitados", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark))]),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 380,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
                  itemCount: _sugestoes.length,
                  itemBuilder: (context, index) {
                    final poi = _sugestoes[index];
                    return _buildPOICard(poi);
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                child: Column(
                  children: [
                    if (_itinerarioIA != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _concluirViagem,
                          icon: const Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white),
                          label: const Text("Concluir Viagem", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmarExclusao(),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        label: const Text("Excluir este Roteiro", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildPOICard(Map<String, dynamic> poi) {
    final hasImage = poi['image'] != null && poi['image'].toString().isNotEmpty;
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage) CachedNetworkImage(
                  imageUrl: poi['image'], 
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                )
                else Container(color: AppTheme.primaryPurple.withOpacity(0.1), child: const Icon(Icons.landscape, color: AppTheme.primaryPurple, size: 40)),
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)])))),
                Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(12)), child: Text(poi['category'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Expanded(child: Text(poi['description'] ?? "Explore este local único.", style: TextStyle(color: AppTheme.textGrey, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => _adicionarPonto(poi), child: const Text("ADICIONAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 20), SizedBox(width: 8), Text("Roteiro Inteligente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          ..._itinerarioIA!.roteiroDiario.map((dia) => _buildDiaItem(dia)).toList(),
        ],
      ),
    );
  }

  Widget _buildDiaItem(RoteiroDiario dia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text("DIA ${dia.dia} - ${dia.tema.toUpperCase()}", style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 12))),
        const SizedBox(height: 15),
        ...dia.atividades.asMap().entries.map((entry) {
          int index = entry.key;
          Atividade atividade = entry.value;
          bool isLast = index == dia.atividades.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))), if (!isLast) Expanded(child: Container(width: 2, color: AppTheme.primaryPurple.withOpacity(0.2)))]),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Text(atividade.horarioSugerido, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, fontSize: 13)), const SizedBox(width: 10), Expanded(child: Text(atividade.local, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))]),
                      const SizedBox(height: 8),
                      if (atividade.imageUrl != null && atividade.imageUrl!.isNotEmpty)
                        Container(
                          height: 120,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                atividade.imageUrl!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Text(atividade.descricaoAtividade, style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
                      if (atividade.hackLocal.isNotEmpty) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.tips_and_updates_outlined, size: 14, color: Colors.amber), const SizedBox(width: 8), Expanded(child: Text("HACK: ${atividade.hackLocal}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)))]))
                      else const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        // Gastronomia do Dia
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 30),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.1))),
          child: Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.orange),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sugestão de Gastronomia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                    Text("${dia.gastronomia.restauranteSugerido} • ${dia.gastronomia.pratoTipico}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text("Preço Médio: ${dia.gastronomia.precoMedio}", style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    if (dia.gastronomia.imageUrl != null && dia.gastronomia.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: dia.gastronomia.imageUrl!,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheHeight: 160,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Excluir Roteiro'), content: const Text('Tem certeza que deseja apagar todo o seu planejamento?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)))]));
    if (confirmar == true) {
      setState(() => _isLoading = true);
      final sucesso = await RoteiroService.deletarRoteiro(_roteiroAtivo!['id']);
      if (sucesso) {
        _carregarDados();
        if (widget.onRefresh != null) widget.onRefresh!();
      }
    }
  }

  Widget _buildSearchMiniCard(Map<String, dynamic> poi) {
    return Container(width: 160, margin: const EdgeInsets.only(right: 12, bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)), child: InkWell(onTap: () => _adicionarPonto(poi), borderRadius: BorderRadius.circular(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: poi['image'] != null ? CachedNetworkImage(imageUrl: poi['image'], fit: BoxFit.cover, width: double.infinity, memCacheWidth: 250) : Container(color: AppTheme.primaryPurple.withOpacity(0.1), child: const Icon(Icons.place, color: AppTheme.primaryPurple)))), Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(poi['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Row(children: [const Icon(Icons.add_circle, size: 14, color: AppTheme.primaryPurple), const SizedBox(width: 4), const Text("Adicionar", style: TextStyle(fontSize: 10, color: AppTheme.primaryPurple, fontWeight: FontWeight.bold))])]))])));
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.flight_takeoff_rounded, size: 60, color: AppTheme.primaryPurple)), const SizedBox(height: 25), const Text("Nenhum roteiro ativo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 32), SizedBox(width: 220, height: 50, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CriarRoteiroScreen())).then((_) => _carregarDados()), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: Colors.white), SizedBox(width: 8), Text("Criar Meu Roteiro", style: TextStyle(color: Colors.white))])))])));
  }
}
