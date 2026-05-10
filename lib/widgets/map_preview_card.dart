import 'package:flutter/material.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://static.flashframe.io/blog/wp-content/uploads/2018/06/Lisbon-map-1024x538.png'), // Placeholder map image
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Simulated markers
          const Positioned(
            left: 100,
            top: 60,
            child: _MapMarker(number: "1", color: Colors.blue),
          ),
          const Positioned(
            left: 130,
            top: 40,
            child: _MapMarker(number: "2", color: Colors.blue),
          ),
          const Positioned(
            left: 180,
            top: 90,
            child: _MapMarker(number: "3", color: Colors.red),
          ),
          // Location label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Text("Lisboa", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String number;
  final Color color;

  const _MapMarker({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        number,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
