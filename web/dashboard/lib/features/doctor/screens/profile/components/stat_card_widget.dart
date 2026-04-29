import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class StatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(defaultRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: smallPadding),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.8),
                    fontSize: captionSize,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: smallPadding),
          Text(
            value,
            style: const TextStyle(
              color: secondaryColor,
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}