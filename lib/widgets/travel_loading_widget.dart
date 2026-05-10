import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';
import 'dart:math' as math;

class TravelLoadingWidget extends StatefulWidget {
  final double size;
  final bool showIcons;

  const TravelLoadingWidget({
    super.key,
    this.size = 400,
    this.showIcons = true,
  });

  @override
  State<TravelLoadingWidget> createState() => _TravelLoadingWidgetState();
}

class _TravelLoadingWidgetState extends State<TravelLoadingWidget> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _cloudController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0EAFC).withOpacity(0.5),
            const Color(0xFFCFDEF3).withOpacity(0.5),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Fundo: Nuvens em Paralaxe (Realistic Feel)
            _buildCloudsLayer(),

            // 2. Montanhas com Gradiente (Melhorado)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: _buildMountainLandscape(),
            ),

            // 3. A Estrada / Horizonte
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildRoadLayer(),
            ),

            // 4. Elementos em Movimento (Os Ícones Premium)
            if (widget.showIcons) ...[
              _buildPremiumMovingElement(
                delay: 0.0,
                altitude: 140,
                icon: Icons.flight_takeoff_rounded,
                label: "Avião",
                color: AppTheme.primaryPurple,
              ),
              _buildPremiumMovingElement(
                delay: 0.4,
                altitude: 42,
                icon: Icons.directions_walk_rounded,
                label: "Viajante",
                color: AppTheme.primaryPurple,
              ),
              _buildPremiumMovingElement(
                delay: 0.6,
                altitude: 42,
                icon: Icons.luggage_rounded,
                label: "Mala",
                color: AppTheme.primaryPurple.withOpacity(0.8),
              ),
              _buildPremiumMovingElement(
                delay: 0.8,
                altitude: 90,
                icon: Icons.map_rounded,
                label: "Mapa",
                color: Colors.blueAccent,
              ),
            ],

            // 5. Partículas de Velocidade (Vento)
            _buildWindParticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudsLayer() {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, _) {
        return Stack(
          children: List.generate(6, (i) {
            double progress = (_cloudController.value + (i * 0.17)) % 1.0;
            return Positioned(
              top: 20.0 + (i * 15),
              left: MediaQuery.of(context).size.width * progress,
              child: Opacity(
                opacity: 0.3,
                child: Icon(Icons.cloud_rounded, color: Colors.white, size: 40 + (i * 10)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMountainLandscape() {
    return CustomPaint(
      painter: _ScenicMountainPainter(),
      child: Container(),
    );
  }

  Widget _buildRoadLayer() {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0),
            AppTheme.primaryPurple.withOpacity(0.4),
            AppTheme.primaryPurple.withOpacity(0),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumMovingElement({
    required double delay,
    required double altitude,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, _) {
        double progress = (_mainController.value + delay) % 1.0;
        double screenWidth = MediaQuery.of(context).size.width;

        // Movimento senoidal para o avião
        double verticalOffset = (altitude > 100) ? math.sin(progress * 20) * 8 : 0;
        
        // Movimento de "passo" para o viajante
        double stepOffset = (altitude < 50) ? (math.sin(progress * 40).abs() * 4) : 0;

        return Positioned(
          left: (screenWidth + 200) * progress - 150,
          bottom: altitude + verticalOffset + stepOffset,
          child: Opacity(
            opacity: _getFadeOpacity(progress),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 4),
                // Pequena sombra no chão
                if (altitude < 50)
                  Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWindParticles() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, _) {
        return Stack(
          children: List.generate(8, (i) {
            double progress = (_mainController.value * 2 + (i * 0.125)) % 1.0;
            return Positioned(
              top: 50 + (i * 30.0),
              right: MediaQuery.of(context).size.width * progress,
              child: Container(
                width: 30,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.5)],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _getFadeOpacity(double progress) {
    if (progress < 0.1) return progress * 10;
    if (progress > 0.9) return (1.0 - progress) * 10;
    return 1.0;
  }
}

class _ScenicMountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Camada 1: Montanhas Distantes
    paint.color = const Color(0xFFB0C4DE).withOpacity(0.4);
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Camada 2: Montanhas Médias (Gradiente)
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF778899).withOpacity(0.6), const Color(0xFF708090).withOpacity(0.8)],
    ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));
    
    path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.15, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.75);
    path.lineTo(size.width * 0.9, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
