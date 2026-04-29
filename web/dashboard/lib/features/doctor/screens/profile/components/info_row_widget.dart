import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final TextEditingController? controller;
  final bool isEditing;

  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.controller,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEditable = controller != null && isEditing;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 18,
        ),
        const SizedBox(width: smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: secondaryColor.withOpacity(0.7),
                  fontSize: captionSize,
                ),
              ),
              const SizedBox(height: 4),
              isEditable
                  ? TextFormField(
                      controller: controller,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: bodySize,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(defaultRadius),
                          borderSide: const BorderSide(
                            color: secondaryColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(defaultRadius),
                          borderSide: const BorderSide(
                            color: secondaryColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(defaultRadius),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        color: secondaryColor,
                        fontSize: bodySize,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}