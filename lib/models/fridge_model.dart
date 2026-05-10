import 'package:flutter/material.dart';

class FridgeMagnet {
  final String id;
  final String destination;
  final String emoji;
  final String colorHex;
  double x; // 0.0 a 1.0 (percentual da largura)
  double y; // 0.0 a 1.0 (percentual da altura)
  final double rotation;

  FridgeMagnet({
    required this.id,
    required this.destination,
    required this.emoji,
    required this.colorHex,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'destination': destination,
    'emoji': emoji,
    'color_hex': colorHex,
    'x': x,
    'y': y,
    'rotation': rotation,
  };

  factory FridgeMagnet.fromJson(Map<String, dynamic> json) => FridgeMagnet(
    id: json['id'],
    destination: json['destination'],
    emoji: json['emoji'] ?? '📍',
    colorHex: json['color_hex'] ?? '#E87A30',
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
  );
}
