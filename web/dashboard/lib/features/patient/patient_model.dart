class PatientModel {
  String name;
  int age;
  List<String> screeningResults;

  PatientModel({
    required this.name,
    required this.age,
    required this.screeningResults,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'screeningResults': screeningResults,
    };
  }

  static PatientModel fromMap(Map<String, dynamic> map) {
    return PatientModel(
      name: map['name'],
      age: map['age'],
      screeningResults: List<String>.from(map['screeningResults'] ?? []),
    );
  }
}
