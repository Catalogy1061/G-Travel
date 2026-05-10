import 'dart:async';
import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class TipsCarouselWidget extends StatefulWidget {
  final List<String>? dynamicTips;

  const TipsCarouselWidget({super.key, this.dynamicTips});

  @override
  State<TipsCarouselWidget> createState() => _TipsCarouselWidgetState();
}

class _TipsCarouselWidgetState extends State<TipsCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  List<String> get _tips => widget.dynamicTips ?? [
    "DICA: Use o cartão Wise para taxas de câmbio menores.",
    "DICA: Baixe o mapa offline antes de sair do hotel.",
    "DICA: O ticket do metrô é mais barato no pacote de 10.",
    "DICA: Evite comer perto de pontos turísticos.",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _tips.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The total height of the white box
    const double boxHeight = 110;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. The White Background Card
        Container(
          width: double.infinity,
          height: boxHeight,
          margin: const EdgeInsets.only(top: 20), // Space for the image to pop out at the top
          padding: const EdgeInsets.fromLTRB(20, 15, 170, 15), // Increased right padding for more text safety
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "DICAS INTELIGENTES",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryPurple,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 45,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _tips.length,
                  onPageChanged: (int page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    return Text(
                      _tips[index],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 2. The HD Image (Popping Out)
        Positioned(
          right: -15, // Pushed further to the right edge
          bottom: -5, // Anchored slightly below the bottom edge
          child: Image.asset(
            'assets/travel_banner.png',
            height: 170, // Significantly taller than the box to force it to pop out the top
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                'https://cdn3d.iconscout.com/3d/premium/thumb/travel-suitcase-5606132-4663955.png',
                height: 150,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      ],
    );
  }
}

