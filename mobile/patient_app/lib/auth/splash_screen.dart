import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tb_project/core/app_constants.dart';
import 'package:tb_project/patient/notification_service.dart';

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
      // Add timeout to prevent infinite loading
      await _checkUserStatus().timeout(const Duration(seconds: 10));
    } catch (e) {
      // If anything fails, go to login
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
    final verified = userData['verified'] ?? true;

    // Check if account is deactivated
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

    // Check verification for CHW users
    if (role == 'CHW' && verified == false) {
      await _auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is pending admin approval. You will be notified once approved.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
      }
      return;
    }

    // ✅ FIXED: Handle ALL roles, not just CHW
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
      // If unknown role, go to login
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content - Centered
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with enhanced design
                    Container(
                      height: screenHeight * 0.24,
                      width: screenWidth * 0.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.15),
                            primaryColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Title with better typography
                    const Text(
                      'TB-CareAI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle with improved styling
                    Text(
                      "AI-powered TB Screening & Guidance",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Enhanced Progress Indicator
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer - Positioned at bottom
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Loading text
                  Text(
                    'Checking account status...',
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Copyright text
                  Text(
                    '© 2025 TB-CareAI Initiative',
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}