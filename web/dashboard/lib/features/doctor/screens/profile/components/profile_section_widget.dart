import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class ProfileSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const ProfileSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: largePadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: smallPadding),
              Text(
                title,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          child,
        ],
      ),
    );
  }
}