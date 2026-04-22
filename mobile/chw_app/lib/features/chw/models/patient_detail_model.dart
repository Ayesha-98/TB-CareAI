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
  final String createdBy;
  final String chwName;
  final DateTime createdAt;
  final String? diagnosisStatus; // doctor updates later
  final String? imageUrl; // always null for now

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
    required this.createdBy,
    required this.chwName,
    required this.createdAt,
    this.diagnosisStatus,
    this.imageUrl,
  });

  Map<String, dynamic> toMap({bool isUpdate = false}) {
    final map = {
      "name": name,
      "age": age,
      "gender": gender,
      "phone": phone,
      "weight": weight,
      "comorbidities": comorbidities,
      "medicationHistory": medicationHistory,
      "appetite": appetite,
      "createdBy": createdBy,
      "chwName": chwName,
      "updatedAt": DateTime.now(),
      "imageUrl": null, // always null
    };

    if (!isUpdate) {
      map["createdAt"] = DateTime.now();
      map["diagnosisStatus"] = diagnosisStatus ?? "pending";
    }

    return map;
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
      createdBy: map["createdBy"] ?? "",
      chwName: map["chwName"] ?? "",
      createdAt: map["createdAt"]?.toDate() ?? DateTime.now(),
      diagnosisStatus: map["diagnosisStatus"],
      imageUrl: map["imageUrl"],
    );
  }
}
