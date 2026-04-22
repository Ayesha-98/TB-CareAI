import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/chw/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initAppFlow();
  }

  Future<void> _initAppFlow() async {
    await Future.delayed(const Duration(seconds: 2));
    await _checkUserStatusManually();
  }

  Future<void> _checkUserStatusManually() async {
    try {
      await _checkUserStatus().timeout(const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
      }
    }
  }

  Future<void> _checkUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppConstants.onboardingRoute);
      return;
    }

    await user.reload();
    if (!user.emailVerified) {
      Navigator.pushReplacementNamed(context, AppConstants.verifyEmailRoute);
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
      return;
    }

    final userData = userDoc.data()!;
    final role = userData['role'];
    final status = userData['status'] ?? 'Active';

    if (status == 'Deactivated') {
      await _auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deactivated by administrator. Please contact admin to restore access.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
      }
      return;
    }

    switch (role) {
      case 'CHW':
        try {
          await NotificationService().initialize();
          print('✅ Notification service initialized for CHW');
        } catch (e) {
          print('❌ Failed to initialize notifications: $e');
        }
        Navigator.pushReplacementNamed(context, AppConstants.chwRoute);
        break;
      case 'Doctor':
        try {
          await NotificationService().initialize();
          print('✅ Notification service initialized for Doctor');
        } catch (e) {
          print('❌ Failed to initialize notifications: $e');
        }
        Navigator.pushReplacementNamed(context, AppConstants.doctorRoute);
        break;
      case 'Patient':
        try {
          await NotificationService().initialize();
          print('✅ Notification service initialized for Patient');
        } catch (e) {
          print('❌ Failed to initialize notifications: $e');
        }
        Navigator.pushReplacementNamed(context, AppConstants.patientRoute);
        break;
      case 'Admin':
        Navigator.pushReplacementNamed(context, AppConstants.adminRoute);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Top space - pushes logo down from status bar
              const SizedBox(height: 100),

              // Logo and branding section
              Column(
                children: [
                  // Logo with scale and shadow
                  Transform.scale(
                    scale: 1.1,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // App name
                  Text(
                    'TB-CareAI',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline with subtle background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'AI-Powered TB Screening',
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Loading indicator section
              Column(
                children: [
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Preparing your dashboard...',
                    style: TextStyle(
                      fontSize: 15,
                      color: secondaryColor.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Footer - always at bottom
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor.withOpacity(0.35),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2025 TB-CareAI Initiative',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor.withOpacity(0.35),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              // Bottom padding
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}