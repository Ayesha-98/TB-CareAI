class RecentActivity {
  final String name;
  final String status;
  final DateTime? date;
  final int? screenings;
  final int? followUps;
  final int? referrals;
  final int? confirmed;
  final int? aiFlagged;
  final int? patients;
  final int? total;
  final int? completed;
  final int? pending;
  final dynamic statusColor; // keep dynamic since UI assigns Color

  RecentActivity({
    required this.name,
    required this.status,
    this.date,
    this.statusColor,
    this.patients,
    this.screenings,
    this.followUps,
    this.referrals,
    this.confirmed,
    this.aiFlagged,
    this.total,
    this.completed,
    this.pending,
  });

  factory RecentActivity.fromMap(Map<String, dynamic> data) {
    return RecentActivity(
      name: data['name'] ?? 'Unknown',
      status: data['status'] ?? 'New (Not Screened)',
      date: data['date'],
      statusColor: data['statusColor'],
    );
  }
}

class PatientWithScreening {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String status;
  final DateTime? lastScreeningDate;
  final Map<String, dynamic>? latestScreening;

  PatientWithScreening({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.status,
    this.lastScreeningDate,
    this.latestScreening,
  });

  factory PatientWithScreening.fromMap(Map<String, dynamic> data) {
    return PatientWithScreening(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? 'Unknown',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'not_screened',
      lastScreeningDate: data['lastScreeningDate'],
      latestScreening: data['latestScreening'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'status': status,
      'lastScreeningDate': lastScreeningDate,
      'latestScreening': latestScreening,
    };
  }
}