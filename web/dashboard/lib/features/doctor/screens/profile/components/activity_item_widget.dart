import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class ActivityItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActivityItemWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: secondaryColor.withOpacity(0.7),
                  fontSize: captionSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}