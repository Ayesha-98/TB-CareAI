class Patient {
  final String id;
  final String name;
  final String gender;
  final String phone;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.phone,
  });

  factory Patient.fromMap(String id, Map<String, dynamic> data) {
    return Patient(
      id: id,
      name: data['name'] ?? 'Unknown',
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
    );
  }
}
