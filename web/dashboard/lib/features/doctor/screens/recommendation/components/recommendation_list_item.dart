import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/recommendation_model.dart';

class RecommendationListItem extends StatelessWidget {
  final RecommendationModel recommendation;

  const RecommendationListItem({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: secondaryColor.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  recommendation.createdAt.toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Doctor Notes",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Medical Advice Section
          _buildAdviceSection(
            title: "Medical Advice",
            content: recommendation.medicalAdvice,
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF007EE5),
          ),

          // Lifestyle Advice Section
          _buildAdviceSection(
            title: "Lifestyle Advice",
            content: recommendation.lifestyleAdvice,
            icon: Icons.eco_rounded,
            color: const Color(0xFF26C485),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: secondaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 12, color: secondaryColor.withOpacity(0.5)),
                ),
                const SizedBox(width: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(recommendation.addedBy)
                      .get(),
                  builder: (context, snapshot) {
                    String doctorName = "Doctor";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      doctorName = data['name'] ?? "Doctor";
                    }
                    
                    return Text(
                      "Added by Dr. $doctorName",
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    final bool isEmpty = content.isEmpty || content.toLowerCase() == "no advice";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty ? "No specific advice provided" : content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: secondaryColor.withOpacity(isEmpty ? 0.4 : 0.8),
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}