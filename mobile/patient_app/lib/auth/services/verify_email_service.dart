import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks whether the user has verified their email.
  Future<bool> checkVerification() async {
    User? user = _auth.currentUser;
    await user?.reload();
    user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Resends the verification email.
  Future<void> resendVerification() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No logged in user found.");
    await user.reload();
    if (user.emailVerified) {
      throw Exception("Email is already verified.");
    }
    await user.sendEmailVerification();
  }
}
