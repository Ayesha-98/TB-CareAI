import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/auth/models/forgot_password_model.dart';

class ForgotPasswordService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ForgotPasswordModel> sendResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return ForgotPasswordModel(
        email: email,
        success: true,
        statusMessage: " Reset email sent. Check your inbox.",
      );
    } on FirebaseAuthException catch (e) {
      return ForgotPasswordModel(
        email: email,
        success: false,
        statusMessage: "❌ ${e.message}",
      );
    }
  }
}
