import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/models/fridge_model.dart';
import 'package:g_route_app/services/fridge_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:g_route_app/widgets/clay_magnet_widget.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeladeiraScreen extends StatefulWidget {
  const GeladeiraScreen({super.key});

  @override
  State<GeladeiraScreen> createState() => _GeladeiraScreenState();
}

class _GeladeiraScreenState extends State<GeladeiraScreen> {
  List<FridgeMagnet> _magnets = [];
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Cores da geladeira
  Color _primaryColor = const Color(0xFF63C8B7); // Verde água padrão
  Color _detailColor = const Color(0xFFE87A30); // Laranja/marrom padrão
  
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<Color> _colorOptions = [
    const Color(0xFF63C8B7), // Verde Água
    const Color(0xFFE87A30), // Laranja
    const Color(0xFFE24C4C), // Vermelho
    const Color(0xFF4C8CE2), // Azul
    const Color(0xFFE2C44C), // Amarelo
    const Color(0xFFD4D4D4), // Cinza Metálico
    const Color(0xFF5A5A5A), // Grafite
    const Color(0xFFE27CAE), // Rosa
    const Color(0xFF8B5A2B), // Madeira
    const Color(0xFFF5F5DC), // Creme
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final magnets = await FridgeService.getMagnets();
    
    // Carregar cores do cache
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    final pColorVal = await CacheService.getData('fridge_p_color_$userId');
    final dColorVal = await CacheService.getData('fridge_d_color_$userId');

    setState(() {
      _magnets = magnets;
      if (pColorVal != null) _primaryColor = Color(pColorVal);
      if (dColorVal != null) _detailColor = Color(dColorVal);
      _isLoading = false;
    });
  }

  Future<void> _saveColors() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    await CacheService.saveData('fridge_p_color_$userId', _primaryColor.value);
    await CacheService.saveData('fridge_d_color_$userId', _detailColor.value);
  }

  void _updateMagnetPosition(FridgeMagnet magnet, Offset delta, Size size) {
    setState(() {
      magnet.x = (magnet.x + delta.dx / size.width).clamp(0.0, 1.0);
      magnet.y = (magnet.y + delta.dy / size.height).clamp(0.0, 1.0);
    });
    // Salva apenas no Cache durante o arraste para manter os 60fps
    FridgeService.saveToCacheOnly(_magnets);
  }

  Future<void> _saveAllToSupabase() async {
    setState(() => _isLoading = true);
    await FridgeService.syncWithSupabase(_magnets);
    setState(() => _isLoading = false);
  }

  Future<void> _shareFridge() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preparando sua geladeira...")));
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/minha_geladeira_groute.png').create();
      
      final capturedImage = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (capturedImage != null) {
        await imagePath.writeAsBytes(capturedImage);
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Dá uma olhada na minha geladeira de viagens do G-Route!');
      }
    } catch (e) {
      print("Erro ao compartilhar: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao gerar a imagem.")));
    }
  }

  void _showMagnetDetail(FridgeMagnet magnet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayMagnetWidget(magnet: magnet, size: 200),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Text(magnet.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("PERSONALIZAR GELADEIRA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, letterSpacing: 1)),
                const SizedBox(height: 20),
                
                const Text("Cor Principal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = _colorOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _primaryColor = color);
                          setState(() => _primaryColor = color);
                          _saveColors();
                        },
                        child: Container(
                          width: 45, height: 45,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor == color ? Colors.black : Colors.transparent, width: 3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 25),
                const Text("Cor de Detalhe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = _colorOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _detailColor = color);
                          setState(() => _detailColor = color);
                          _saveColors();
                        },
                        child: Container(
                          width: 45, height: 45,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: _detailColor == color ? Colors.black : Colors.transparent, width: 3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Minha Geladeira", 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 24, 
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: Text(
                "${_magnets.length}", 
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : SingleChildScrollView(
            physics: _isEditing ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Botões Pílula (Ações)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(_isEditing ? Icons.check_rounded : Icons.open_with_rounded, size: 18),
                          label: Text(_isEditing ? "Salvar" : "Mover Imãs", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (_isEditing) {
                              // Saindo do modo de edição: Salvar tudo no banco
                              _saveAllToSupabase();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Posições sincronizadas com a nuvem!")));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arraste os imãs para organizar.")));
                            }
                            setState(() => _isEditing = !_isEditing);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing ? Colors.green : Colors.white,
                            foregroundColor: _isEditing ? Colors.white : AppTheme.primaryPurple,
                            elevation: _isEditing ? 4 : 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.color_lens_rounded, size: 18),
                          label: const Text("Pintar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: _showColorPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryPurple,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: const Color(0xFFF0F0F0), // Fundo da screenshot
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final size = MediaQuery.of(context).size;
                          final fridgeWidth = math.min(size.width * 0.85, 400.0);
                          final fridgeHeight = math.max(size.height * 0.65, 550.0);
                          
                          return SizedBox(
                            width: fridgeWidth + 25, // Espaço para a sombra
                            height: fridgeHeight + 20, // Espaço para os pés
                            child: Stack(
                              children: [
                                // --- RepaintBoundary para o fundo estático da geladeira ---
                                // Isso garante que o fundo complexo não seja redesenhado enquanto arrastamos um imã
                                RepaintBoundary(
                                  child: Stack(
                                    children: [
                                      // --- Pés da Geladeira ---
                                      Positioned(
                                        bottom: 0,
                                        left: 30,
                                        child: Container(
                                          width: 20, height: 25,
                                          decoration: BoxDecoration(
                                            color: _detailColor,
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: Colors.black, width: 2.5),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 55,
                                        child: Container(
                                          width: 20, height: 25,
                                          decoration: BoxDecoration(
                                            color: _detailColor,
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: Colors.black, width: 2.5),
                                          ),
                                        ),
                                      ),

                                      // --- Painel Traseiro / Sombra 3D ---
                                      Positioned(
                                        top: 5,
                                        left: 15,
                                        child: Container(
                                          width: fridgeWidth + 10,
                                          height: fridgeHeight - 10,
                                          decoration: BoxDecoration(
                                            color: _detailColor,
                                            borderRadius: BorderRadius.circular(25),
                                            border: Border.all(color: Colors.black, width: 3.5),
                                          ),
                                        ),
                                      ),

                                      // --- Corpo Principal ---
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Container(
                                          width: fridgeWidth,
                                          height: fridgeHeight,
                                          decoration: BoxDecoration(
                                            color: _primaryColor,
                                            borderRadius: BorderRadius.circular(25),
                                            border: Border.all(color: Colors.black, width: 3.5),
                                          ),
                                          child: Stack(
                                            children: [
                                              // --- Brilho da borda ---
                                              Positioned(
                                                top: 10,
                                                left: 15,
                                                bottom: 10,
                                                child: Container(
                                                  width: 15,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.3),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                              
                                              // --- Divisão Congelador/Refrigerador ---
                                              Positioned(
                                                top: fridgeHeight * 0.3,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  height: 3.5,
                                                  color: Colors.black,
                                                ),
                                              ),

                                              // --- Puxador do Congelador ---
                                              Positioned(
                                                top: fridgeHeight * 0.1,
                                                left: 20,
                                                child: Container(
                                                  width: 12,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.black, width: 2),
                                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(-2, 0))],
                                                  ),
                                                ),
                                              ),

                                              // --- Distintivo/Logo ---
                                              Positioned(
                                                top: fridgeHeight * 0.12,
                                                right: 25,
                                                child: Container(
                                                  width: 45,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: _detailColor,
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: Colors.black, width: 2),
                                                  ),
                                                ),
                                              ),

                                              // --- Puxador do Refrigerador ---
                                              Positioned(
                                                top: fridgeHeight * 0.35,
                                                left: 20,
                                                child: Container(
                                                  width: 12,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.black, width: 2),
                                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(-2, 0))],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- Área arrastável dos Imãs (FORA do RepaintBoundary do fundo) ---
                                Positioned(
                                  left: 0, top: 0,
                                  width: fridgeWidth, height: fridgeHeight,
                                  child: Stack(
                                    children: [
                                      // --- Texto de Vazio ---
                                      if (_magnets.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 80),
                                            child: Text(
                                              "Sua geladeira está vazia!\nViaje para ganhar imãs.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ..._magnets.map((magnet) => _buildDraggableMagnet(magnet, Size(fridgeWidth, fridgeHeight))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text("Compartilhar Geladeira", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _shareFridge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 120), // Espaço extra para evitar que a navegação inferior cubra o botão
              ],
            ),
          ),
    );
  }

  Widget _buildDraggableMagnet(FridgeMagnet magnet, Size fridgeSize) {
    const double magnetSize = 65;
    
    return Positioned(
      left: magnet.x * (fridgeSize.width - magnetSize),
      top: magnet.y * (fridgeSize.height - magnetSize),
      child: GestureDetector(
        onPanUpdate: _isEditing ? (details) => _updateMagnetPosition(magnet, details.delta, fridgeSize) : null,
        onTap: () => _showMagnetDetail(magnet),
        child: RepaintBoundary(
          child: Transform.rotate(
            angle: magnet.rotation * (math.pi / 180),
            child: ClayMagnetWidget(magnet: magnet, size: magnetSize),
          ),
        ),
      ),
    );
  }
}
