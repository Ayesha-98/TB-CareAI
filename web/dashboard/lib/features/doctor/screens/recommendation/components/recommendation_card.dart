import 'package:flutter/material.dart';
import '../../../models/patient_model.dart';
import '../../../../../core/app_constants.dart';
import '../recommendation_detail_screen.dart';

class PatientRecommendationCard extends StatelessWidget {
  final PatientModel patient;

  const PatientRecommendationCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    // Light theme colors - removed isDarkMode logic
    final cardColor = Colors.white;
    final surfaceColor = bgColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecommendationDetailScreen(patient: patient),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.95),
                ],
              ),
              border: Border.all(
                color: primaryColor.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Header Section
                  Row(
                    children: [
                      // Premium Avatar Design
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.8),
                              primaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: patient.photoUrl.isNotEmpty
                                ? NetworkImage(patient.photoUrl)
                                : null,
                            backgroundColor: surfaceColor,
                            child: patient.photoUrl.isEmpty
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: primaryColor,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Enhanced Patient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    color: secondaryColor,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                "Age: ${patient.age} • ${patient.gender}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: secondaryColor.withOpacity(0.7),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated Arrow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}