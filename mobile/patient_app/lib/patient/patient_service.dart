// Later connect this with Firebase
import 'patient_model.dart';

class PatientService {
  static PatientModel getMockPatient() {
    return PatientModel(
      name: "Ali Hurr",
      age: 22,
      screeningResults: ["Normal", "TB Suspected"],
    );
  }
}
