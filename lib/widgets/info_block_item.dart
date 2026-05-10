import 'package:flutter/material.dart';
import 'package:g_route_app/theme/app_theme.dart';

class InfoBlockItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final Color iconColor;
  final bool isActive;

  const InfoBlockItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.iconColor,
    this.isActive = false,
  });

  @override
  State<InfoBlockItem> createState() => _InfoBlockItemState();
}

class _InfoBlockItemState extends State<InfoBlockItem> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _active ? Colors.green.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Switch(
            value: _active,
            onChanged: (val) => setState(() => _active = val),
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Text(
            widget.price,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
