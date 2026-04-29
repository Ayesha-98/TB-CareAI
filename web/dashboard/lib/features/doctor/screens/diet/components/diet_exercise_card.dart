import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../../models/patient_model.dart';

class DietExerciseCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onDietTap;
  final VoidCallback onExerciseTap;

  const DietExerciseCard({
    super.key,
    required this.patient,
    required this.onDietTap,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileInfo(),
                const Spacer(),
                _buildActionButtons(),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileInfo(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline_rounded,
            color: primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              patient.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: secondaryColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, size: 14, color: secondaryColor.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  patient.gender,
                  style: TextStyle(color: secondaryColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Icon(Icons.cake_outlined, size: 14, color: secondaryColor.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  "Age ${patient.age}",
                  style: TextStyle(color: secondaryColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: onDietTap,
          icon: const Icon(Icons.restaurant_menu_outlined, size: 20),
          label: const Text(
            "Diet Plan",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: successColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onExerciseTap,
          icon: const Icon(Icons.fitness_center_outlined, size: 20),
          label: const Text(
            "Exercise Plan",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: warningColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}