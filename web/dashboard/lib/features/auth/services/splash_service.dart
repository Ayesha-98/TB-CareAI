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
      // Fetch role from Firestore
      final doc = await _db.collection('users').doc(current.uid).get();
      final role = doc.data()?['role'] ?? 'Patient';

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
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
