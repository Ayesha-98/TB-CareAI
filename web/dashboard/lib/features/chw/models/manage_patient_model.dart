class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final int weight;
  final String comorbidities;
  final String medicationHistory;
  final String appetite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String language;
  final String symptoms; // Changed from dynamic to String
  final String? imageUrl;
  final String diagnosisStatus;
  final String address;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.weight,
    required this.comorbidities,
    required this.medicationHistory,
    required this.appetite,
    required this.createdAt,
    required this.updatedAt,
    this.language = "English",
    this.symptoms = "none", // Default to "none" as string
    this.imageUrl,
    this.diagnosisStatus = "Pending",
    this.address = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": id,                 // Firestore key for uid
      "name": name,
      "age": age,
      "gender": gender,
      "phone": phone,
      "weight": weight,
      "comorbidities": comorbidities,
      "medicationHistory": medicationHistory,
      "appetite": appetite,
      "language": language,
      "symptoms": symptoms,      // Now a string, not map
      "imageUrl": imageUrl,
      "diagnosisStatus": diagnosisStatus,
      "address": address,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map, String id) {
    return Patient(
      id: id,
      name: map["name"] ?? "",
      age: map["age"] ?? 0,
      gender: map["gender"] ?? "Unknown",
      phone: map["phone"] ?? "",
      weight: map["weight"] ?? 0,
      comorbidities: map["comorbidities"] ?? "",
      medicationHistory: map["medicationHistory"] ?? "",
      appetite: map["appetite"] ?? "Normal",
      language: map["language"] ?? "English",
      symptoms: map["symptoms"] ?? "none", // Ensure it's string
      imageUrl: map["imageUrl"],
      diagnosisStatus: map["diagnosisStatus"] ?? "Pending",
      address: map["address"] ?? "",
      createdAt: (map["createdAt"] ).toDate(),
      updatedAt: (map["updatedAt"] ).toDate(),
    );
  }

}