import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    //  Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("✅ Firebase Initialized Successfully");
  } catch (e) {
    print('❌ Error Initializing Firebase: $e');
  }

  runApp(const TBCareApp());
}
