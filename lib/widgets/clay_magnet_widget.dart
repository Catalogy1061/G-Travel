import 'package:flutter/material.dart';
import 'package:g_route_app/models/fridge_model.dart';

class ClayMagnetWidget extends StatelessWidget {
  final FridgeMagnet magnet;
  final double size;

  const ClayMagnetWidget({
    Key? key,
    required this.magnet,
    this.size = 70.0,
  }) : super(key: key);

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.tryParse(hexColor, radix: 16) ?? 0xFFE87A30);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getColorFromHex(magnet.colorHex);
    
    // Calcula cores para o efeito claymorphism (luz e sombra)
    final hsl = HSLColor.fromColor(baseColor);
    final lightColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final shadowColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    return Hero(
      tag: 'magnet_${magnet.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            // Sombra externa
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(4, 6),
              blurRadius: 8,
            ),
            // Sombra interna escura (bottom right)
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 4),
              blurRadius: 10,
              spreadRadius: -2,
            ),
            // Luz interna clara (top left)
            BoxShadow(
              color: lightColor,
              offset: const Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            magnet.emoji,
            style: TextStyle(
              fontSize: size * 0.45,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(1, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
