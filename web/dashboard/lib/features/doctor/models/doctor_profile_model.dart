class Doctor {
  final String uid;
  final String name;
  final String phone;
  final String specialization;
  final int confirmedTBCount;
  final DateTime createdAt;
  final List<String> patientsReviewed;
  final int totalDiagnosisMade;
  final int totalFinalVerdicts;
  final int totalPatientsReviewed;
  final int totalRecommendationsGiven;
  final int totalTestsRequested;
  final String? profileImageUrl;
  final String? email;
  final String? hospital;
  final String? experience;
  final String? qualifications;
  final double? rating;
  final int? reviewCount;

  Doctor({
    required this.uid,
    required this.name,
    required this.phone,
    required this.specialization,
    required this.confirmedTBCount,
    required this.createdAt,
    required this.patientsReviewed,
    required this.totalDiagnosisMade,
    required this.totalFinalVerdicts,
    required this.totalPatientsReviewed,
    required this.totalRecommendationsGiven,
    required this.totalTestsRequested,
    this.profileImageUrl,
    this.email,
    this.hospital,
    this.experience,
    this.qualifications,
    this.rating,
    this.reviewCount,
  });

  factory Doctor.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Doctor(
      uid: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      specialization: data['specialization'] ?? '',
      confirmedTBCount: data['confirmedTBCount'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      patientsReviewed: List<String>.from(data['patientsReviewed'] ?? []),
      totalDiagnosisMade: data['totalDiagnosisMade'] ?? 0,
      totalFinalVerdicts: data['totalFinalVerdicts'] ?? 0,
      totalPatientsReviewed: data['totalPatientsReviewed'] ?? 0,
      totalRecommendationsGiven: data['totalRecommendationsGiven'] ?? 0,
      totalTestsRequested: data['totalTestsRequested'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
      email: data['email'],
      hospital: data['hospital'],
      experience: data['experience'],
      qualifications: data['qualifications'],
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'specialization': specialization,
      'confirmedTBCount': confirmedTBCount,
      'createdAt': createdAt,
      'patientsReviewed': patientsReviewed,
      'totalDiagnosisMade': totalDiagnosisMade,
      'totalFinalVerdicts': totalFinalVerdicts,
      'totalPatientsReviewed': totalPatientsReviewed,
      'totalRecommendationsGiven': totalRecommendationsGiven,
      'totalTestsRequested': totalTestsRequested,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (email != null) 'email': email,
      if (hospital != null) 'hospital': hospital,
      if (experience != null) 'experience': experience,
      if (qualifications != null) 'qualifications': qualifications,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
    };
  }

  Doctor copyWith({
    String? uid,
    String? name,
    String? phone,
    String? specialization,
    int? confirmedTBCount,
    DateTime? createdAt,
    List<String>? patientsReviewed,
    int? totalDiagnosisMade,
    int? totalFinalVerdicts,
    int? totalPatientsReviewed,
    int? totalRecommendationsGiven,
    int? totalTestsRequested,
    String? profileImageUrl,
    String? email,
    String? hospital,
    String? experience,
    String? qualifications,
    double? rating,
    int? reviewCount,
  }) {
    return Doctor(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      confirmedTBCount: confirmedTBCount ?? this.confirmedTBCount,
      createdAt: createdAt ?? this.createdAt,
      patientsReviewed: patientsReviewed ?? this.patientsReviewed,
      totalDiagnosisMade: totalDiagnosisMade ?? this.totalDiagnosisMade,
      totalFinalVerdicts: totalFinalVerdicts ?? this.totalFinalVerdicts,
      totalPatientsReviewed: totalPatientsReviewed ?? this.totalPatientsReviewed,
      totalRecommendationsGiven: totalRecommendationsGiven ?? this.totalRecommendationsGiven,
      totalTestsRequested: totalTestsRequested ?? this.totalTestsRequested,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      email: email ?? this.email,
      hospital: hospital ?? this.hospital,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}