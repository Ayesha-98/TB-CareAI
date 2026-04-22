import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  Future<void> _navigateUser() async {
    // Keep splash visible for a moment
    await Future.delayed(const Duration(seconds: 2));

    final user = _auth.currentUser;

    if (user == null) {
      // Not logged in → go to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await user.reload();
    final current = _auth.currentUser;

    if (current == null || !current.emailVerified) {
      // If no valid user or email not verified
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      // Fetch user data from Firestore
      final doc = await _db.collection('users').doc(current.uid).get();

      if (!doc.exists) {
        // User document doesn't exist
        await _auth.signOut();
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final userData = doc.data()!;
      final role = userData['role'] ?? 'Patient';
      final status = userData['status'] ?? 'Active';

      // ✅ ADDED: Check if account is deactivated
      if (status == 'Deactivated') {
        await _auth.signOut();

        // Show deactivation message and redirect to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your account has been deactivated by administrator. Please contact admin to restore access.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );

          // Wait a bit for user to read the message, then redirect
          await Future.delayed(Duration(seconds: 3));
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }



      // Navigate based on role
      if (role == 'Patient') {
        Navigator.pushReplacementNamed(context, '/patient');
      } else if (role == 'CHW') {
        Navigator.pushReplacementNamed(context, '/CHW');
      } else if (role == 'Doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else {
        Navigator.pushReplacementNamed(context, '/login'); // fallback
      }
    } catch (e) {
      // If any error occurs, sign out and go to login
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Checking account status...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}