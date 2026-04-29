import 'package:cloud_firestore/cloud_firestore.dart';

class DietRecommendationModel {
  final String? activityLevel;
  final num? age;
  final String? allergies;
  final String? appetite;
  final bool approved;
  final String dietPlan;
  final String? diseases;
  final String? foodPreference;
  final String? gender;
  final DateTime? generatedAt;
  final String? symptoms;
  final num? weight;

  DietRecommendationModel({
    this.activityLevel,
    this.age,
    this.allergies,
    this.appetite,
    this.approved = false,
    required this.dietPlan,
    this.diseases,
    this.foodPreference,
    this.gender,
    this.generatedAt,
    this.symptoms,
    this.weight,
  });

  factory DietRecommendationModel.fromMap(Map<String, dynamic> map) {
    DateTime? getTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
      return null;
    }

    return DietRecommendationModel(
      activityLevel: map['activityLevel'],
      age: parseNum(map['age']),
      allergies: map['allergies'],
      appetite: map['appetite'],
      approved: map['approved'] ?? false,
      dietPlan: map['dietPlan'] ?? '',
      diseases: map['diseases'],
      foodPreference: map['foodPreference'],
      gender: map['gender'],
      generatedAt: getTimestamp(map['generatedAt']),
      symptoms: map['symptoms'],
      weight: parseNum(map['weight']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityLevel': activityLevel,
      'age': age,
      'allergies': allergies,
      'appetite': appetite,
      'approved': approved,
      'dietPlan': dietPlan,
      'diseases': diseases,
      'foodPreference': foodPreference,
      'gender': gender,
      'generatedAt': generatedAt,
      'symptoms': symptoms,
      'weight': weight,
    };
  }
}
