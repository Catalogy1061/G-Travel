import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'package:g_route_app/globals.dart';
import 'package:g_route_app/screens/tabs/financeiro_screen.dart';
import 'package:g_route_app/screens/tabs/roteiro_screen.dart';
import 'package:g_route_app/screens/tabs/dicas_screen.dart';
import 'package:g_route_app/screens/tabs/perfil_screen.dart';
import 'package:g_route_app/screens/tabs/tickets_screen.dart';
import 'package:g_route_app/screens/tabs/comercio_local_screen.dart';
import 'package:g_route_app/screens/tabs/emergencies_screen.dart';
import 'package:g_route_app/screens/tabs/hospedagem_screen.dart';
import 'package:g_route_app/screens/tabs/logistics_screen.dart';
import 'package:g_route_app/screens/tabs/settings_screen.dart';
import 'package:g_route_app/screens/tabs/geladeira_screen.dart';
import 'package:g_route_app/widgets/map_preview_card.dart';
import 'package:g_route_app/widgets/exchange_rate_card.dart';
import 'package:g_route_app/widgets/hybrid_map_widget.dart';
import 'package:g_route_app/widgets/weather_widget.dart';
import 'package:g_route_app/widgets/tips_carousel_widget.dart';
import 'package:g_route_app/theme/theme_manager.dart';
import 'package:g_route_app/screens/auth/login_screen.dart';
import 'package:g_route_app/services/location_service.dart';
import 'package:g_route_app/services/cache_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:g_route_app/screens/tabs/map_page.dart';
import 'package:g_route_app/screens/criar_roteiro_screen.dart' as g_route_app_criar;
import 'package:g_route_app/services/roteiro_service.dart';
import 'package:g_route_app/services/image_service.dart';

import 'package:g_route_app/services/user_service.dart';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:g_route_app/models/itinerary_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  TripItinerary? _itinerarioIA;
  bool _isInitialLoading = true;
  final List<Widget> _dynamicScreens = [];

  @override
  void initState() {
    super.initState();
    LocationService.updateLocation();
    _loadItinerario();
  }

  String get _userFirstName {
    final fullName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? "Viajante";
    return fullName.split(' ').first;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Bom dia";
    if (hour >= 12 && hour < 18) return "Boa tarde";
    return "Boa noite";
  }

  Future<void> _loadItinerario() async {
    if (mounted) setState(() => _isInitialLoading = true);
    
    try {
      final cachedRoteiro = await CacheService.getData(CacheService.KEY_ACTIVE_ITINERARY);
      
      if (cachedRoteiro != null) {
        final roteiroId = cachedRoteiro['id'].toString();
        final itinerario = await RoteiroService.getItinerarioCompleto(roteiroId);
        
        if (mounted) {
          setState(() {
            _itinerarioIA = itinerario;
            _isInitialLoading = false;
          });
        }
      } else {
        // Se não tem no cache, tentamos buscar no banco (caso o app tenha sido fechado)
        final roteiros = await RoteiroService.fetchRoteiros();
        if (roteiros.isNotEmpty && mounted) {
          // Só pegamos o mais recente se ele for "ativo" (opcional: validar data)
          final roteiroId = roteiros.first['id'].toString();
          final itinerario = await RoteiroService.getItinerarioCompleto(roteiroId);
          
          if (mounted) {
            setState(() {
              _itinerarioIA = itinerario;
              _isInitialLoading = false;
            });
            CacheService.saveData(CacheService.KEY_ACTIVE_ITINERARY, roteiros.first);
          }
        } else {
          if (mounted) {
            setState(() {
              _itinerarioIA = null;
              _isInitialLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar itinerário: $e');
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  List<Widget> _buildScreens() {
    return [
      InicioDashboard(
        greeting: _getGreeting(), 
        firstName: _userFirstName,
        itinerarioIA: _itinerarioIA,
        isLoading: _isInitialLoading,
        onGoToRoteiros: () => setState(() => _currentIndex = 1),
        onRefresh: _loadItinerario,
      ),
      RoteiroScreen(onRefresh: _loadItinerario),
      const MapPage(),
      FinanceiroScreen(itinerarioIA: _itinerarioIA),
      const PerfilScreen(),
      DicasScreen(itinerarioIA: _itinerarioIA),
      const TicketsScreen(),
      const ComercioLocalScreen(),
      EmergenciesScreen(itinerarioIA: _itinerarioIA),
      LogisticsScreen(itinerarioIA: _itinerarioIA),
      HospedagemScreen(itinerarioIA: _itinerarioIA),
      const GeladeiraScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 2 ? null : _buildAppBar(),
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, Color(0xFF9042F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: UserService.userAvatarUrl != null 
                          ? CachedNetworkImageProvider(
                              UserService.userAvatarUrl!,
                            ) 
                          : null,
                      child: UserService.userAvatarUrl == null
                          ? const Icon(Icons.person, color: AppTheme.primaryPurple, size: 35)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userFirstName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _itinerarioIA != null 
                            ? "${_itinerarioIA!.destinoInfo.nomeOficial} • ${_itinerarioIA!.configuracaoUsuario.perfil}" 
                            : "Plano Premium",
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Categorized List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                physics: const BouncingScrollPhysics(), // 60fps smooth scrolling
                children: [
                  _buildDrawerHeader("MINHA VIAGEM"),
                  _buildDrawerItem(Icons.route_outlined, "Roteiro Inteligente", 1),
                  _buildDrawerItem(Icons.lightbulb_rounded, "Dicas e Hacks", 5),
                  _buildDrawerItem(Icons.account_balance_wallet_rounded, "Financeiro", 3),
                  
                  const SizedBox(height: 15),
                  _buildDrawerHeader("EXPLORAR"),
                  _buildDrawerItem(Icons.commute_rounded, "Transporte e Logística", 9),
                  _buildDrawerItem(Icons.confirmation_number_rounded, "Tickets e Ingressos", 6),
                  _buildDrawerItem(Icons.hotel_rounded, "Hospedagem", 10),
                  _buildDrawerItem(Icons.storefront_rounded, "Comércio Local", 7),
                  _buildDrawerItem(Icons.kitchen_rounded, "Minha Geladeira", 11),
                  
                  const SizedBox(height: 15),
                  _buildDrawerHeader("SUPORTE"),
                  _buildDrawerItem(Icons.emergency_rounded, "Emergências Locais", 8),
                  
                  const SizedBox(height: 15),
                  _buildDrawerHeader("CONTA"),
                  _buildDrawerItem(Icons.settings_rounded, "Ajustes", 11),
                  
                  // Logout Button
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                      title: const Text(
                        "Sair",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () async {
                        await UserService.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Dark Mode Toggle Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    themeNotifier.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                title: const Text("Modo Escuro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) {
                    themeNotifier.toggleTheme();
                  },
                  activeColor: AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: RepaintBoundary(child: _buildModernBottomBar()),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: Globals.sosActive,
        builder: (context, isActive, child) {
          if (!isActive) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showSOSMenu(context),
            backgroundColor: Colors.red,
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  void _showSOSMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "CENTRAL DE EMERGÊNCIA",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red),
            ),
            const SizedBox(height: 25),
            if (_itinerarioIA != null)
              ..._itinerarioIA!.guiaLocal.saudeEmergencia.telefones.entries.map((e) {
                final label = e.key;
                final number = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSOSOption(
                    context, 
                    label.toLowerCase().contains('pol') ? Icons.phone_in_talk : Icons.medical_services, 
                    "Ligar para $label ($number)", 
                    label.toLowerCase().contains('pol') ? Colors.blue[800]! : Colors.red[700]!
                  ),
                );
              }).toList()
            else ...[
              _buildSOSOption(context, Icons.phone_in_talk, "Ligar para Polícia (190)", Colors.blue[800]!),
              const SizedBox(height: 12),
              _buildSOSOption(context, Icons.medical_services, "Ambulância (192)", Colors.red[700]!),
            ],
            const SizedBox(height: 12),
            _buildSOSOption(context, Icons.share_location, "Compartilhar Localização Real", AppTheme.primaryPurple),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSOption(BuildContext context, IconData icon, String label, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pop(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0.5,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      centerTitle: true,
      title: Image.asset(
        'assets/Logo.png',
        height: 50,
        fit: BoxFit.contain,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 8, top: 5),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textGrey.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int targetIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: AppTheme.textDark, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() => _currentIndex = targetIndex);
          Navigator.pop(context); // Close drawer smoothly
        },
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPremiumNavItem(Icons.home_rounded, "Início", 0),
                    _buildPremiumNavItem(Icons.route_outlined, "Roteiro", 1),
                    const SizedBox(width: 60), // Space for central button
                    _buildPremiumNavItem(Icons.account_balance_wallet_rounded, "Finanças", 3),
                    _buildPremiumNavItem(Icons.person_rounded, "Perfil", 4),
                  ],
                ),
              ),
            ),
          ),
          // True Floating Central Button
          Positioned(
            top: -25, // Baixado conforme solicitado
            left: 0,
            right: 0,
            child: Center(child: _buildPremiumCentralItem(Icons.map_rounded, 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 75, // Aumentado para melhor área de toque
        color: Colors.transparent, // Garante que toda a área seja clicável
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.only(bottom: isSelected ? 2 : 0), // Subtle jump effect
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey.withOpacity(0.6),
                size: isSelected ? 26 : 24, // Size animation
                shadows: isSelected 
                  ? [Shadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                  : [],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? 10 : 9,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.visible),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCentralItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10), // Aumenta área lateral
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 60 : 55, // Slightly smaller to fit label
            height: isSelected ? 60 : 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, Color(0xFF9042F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(isSelected ? 0.6 : 0.3),
                  blurRadius: isSelected ? 20 : 12,
                  offset: Offset(0, isSelected ? 8 : 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 30 : 26,
              shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Mapa",
            style: TextStyle(
              fontSize: isSelected ? 12 : 11, // Increased size
              color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class InicioDashboard extends StatefulWidget {
  final String greeting;
  final String firstName;
  final VoidCallback onGoToRoteiros;
  final TripItinerary? itinerarioIA;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  
  const InicioDashboard({
    super.key,
    this.greeting = "Olá",
    this.firstName = "Viajante",
    this.itinerarioIA,
    this.isLoading = false,
    required this.onGoToRoteiros,
    required this.onRefresh,
  });

  @override
  State<InicioDashboard> createState() => _InicioDashboardState();
}

class _InicioDashboardState extends State<InicioDashboard> {
  Map<String, dynamic>? _roteiroAtivo;
  TripItinerary? _itinerarioIA;
  bool _isLoading = true;
  String? _dynamicImageUrl;
  String? _countryFlagUrl;

  @override
  void initState() {
    super.initState();
    _loadVisuals();
  }

  @override
  void didUpdateWidget(InicioDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itinerarioIA != oldWidget.itinerarioIA) {
      _loadVisuals();
    }
  }

  Future<void> _loadVisuals() async {
    if (widget.itinerarioIA == null) return;

    final visuals = await ImageService.getCityVisuals(
      widget.itinerarioIA!.destinoInfo.nomeOficial,
    );

    if (mounted) {
      setState(() {
        _dynamicImageUrl = visuals['image'];
        _countryFlagUrl = visuals['flag'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.itinerarioIA;
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppTheme.primaryPurple,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "${widget.greeting}, ${widget.firstName}!",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 5),
                Text(
                  it != null 
                    ? "Sua jornada em ${it.destinoInfo.nomeOficial} continua..."
                    : "Para onde vamos hoje?",
                  style: const TextStyle(fontSize: 14, color: AppTheme.textGrey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 25),
                
                // --- QUICK ACTIONS BAR (NOVO) ---
                _buildQuickActions(),
                
                const SizedBox(height: 30),
                RepaintBoundary(
                  child: TipsCarouselWidget(
                    dynamicTips: it != null 
                      ? (List<String>.from(it.dicasLocais)..add("ALERTA: ${it.guiaLocal.seguranca.bairrosPerigosos.join(', ')}"))
                      : null,
                  )
                ),
                const SizedBox(height: 25),
                
                Row(
                  children: [
                    Expanded(
                      child: WeatherWidget(
                        temp: it?.destinoInfo.climaEsperado.tempMedia,
                        description: it?.destinoInfo.climaEsperado.descricao,
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExchangeRateCard(
                        currency: it?.configuracaoUsuario.moedaOrigem,
                        timezone: it?.destinoInfo.fusoHorario,
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // --- SEÇÃO DINÂMICA (SKELETON OU CARD) ---
                if (widget.isLoading)
                  _buildSkeletonCard()
                else if (it != null)
                  _buildActiveRoteiroCard(it)
                else
                  _buildCreateRoteiroButton(),
                  
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _quickActionItem(Icons.emergency_rounded, "SOS", Colors.redAccent),
          _quickActionItem(Icons.currency_exchange_rounded, "Câmbio", Colors.blueAccent),
          _quickActionItem(Icons.confirmation_number_rounded, "Tickets", Colors.orangeAccent),
          _quickActionItem(Icons.translate_rounded, "Tradutor", Colors.teal),
          _quickActionItem(Icons.hotel_rounded, "Hoteis", Colors.indigoAccent),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20, left: 20,
            child: Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          Positioned(
            bottom: 20, left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 25, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 10),
                Container(width: 200, height: 15, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoteiroCard(TripItinerary it) {
    final destino = it.destinoInfo.nomeOficial;
    
    return GestureDetector(
      onTap: widget.onGoToRoteiros,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade300, 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
          ],
          image: _dynamicImageUrl != null 
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  _dynamicImageUrl!,
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              )
            : null,
        ),
        child: Stack(
          children: [
            // Loader da Imagem
            if (_dynamicImageUrl == null)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
              
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flight_takeoff, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "PRÓXIMA VIAGEM",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bandeira do País (Canto Superior Direito)
            if (_countryFlagUrl != null)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(_countryFlagUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destino,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ver detalhes do roteiro",
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRoteiroButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const g_route_app_criar.CriarRoteiroScreen()),
        );
        if (result == true) {
          widget.onRefresh(); // Recarrega se um roteiro foi criado
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, Color(0xFF9042F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Criar Novo Roteiro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Planeje sua próxima aventura",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
