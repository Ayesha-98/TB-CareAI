import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBGgY4oqDvib8egJ8AXU5WIHEUlfzU49zQ',
          appId: '1:1056630945037:web:188a97c12c63392971ec44',
          messagingSenderId: '1056630945037',
          projectId: 'tbcareappmain',
          authDomain: 'tbcareappmain.firebaseapp.com',
          storageBucket: 'tbcareappmain.firebasestorage.app',
          measurementId: 'G-LXVPB3WZFM',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    print("Firebase Initialized Successfully");
  } catch (e) {
    print('Error Initializing Firebase : $e');
  }

  runApp(const TBCareApp());
}
