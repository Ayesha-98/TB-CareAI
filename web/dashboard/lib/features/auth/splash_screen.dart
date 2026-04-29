import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbcare_main/core/app_constants.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCheckingAuth = false;

  // Use Amar's Continue button approach
  void _handleContinue() {
    _checkUserStatus();
  }

  // Use Ayesha's authentication logic
  Future<void> _checkUserStatus() async {
    if (_isCheckingAuth) return;

    setState(() => _isCheckingAuth = true);

    try {
      final user = _auth.currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, AppConstants.onboardingRoute);
        return;
      }

      await user.reload();

      // Check email verification
      if (!user.emailVerified) {
        Navigator.pushReplacementNamed(context, AppConstants.verifyEmailRoute);
        return;
      }

      // Get user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
        return;
      }

      final userData = userDoc.data()!;
      final role = userData['role'];
      final status = userData['status'] ?? 'Active';
      final verified = userData['verified'] ?? true;

      // Check if account is deactivated (Ayesha's logic)
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

      // Check verification for CHW users (Ayesha's logic)
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

      // ✅ Handle DOCTOR STATUSES (Ayesha's logic)
      if (role == 'Doctor') {
        if (status == 'Needs Qualification') {
          // Should not happen here, but just in case
          Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
          return;
        } else if (status == 'Pending Approval') {
          // Show message and stay on login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your doctor application is pending admin approval. Please check back later.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            await Future.delayed(const Duration(seconds: 3));
            Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
          }
          return;
        } else if (status == 'Rejected') {
          // Show message and stay on login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your doctor application has been rejected. Please contact admin for more information.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            await Future.delayed(const Duration(seconds: 3));
            Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
          }
          return;
        } else if (status == 'Active' && verified) {
          Navigator.pushReplacementNamed(context, AppConstants.doctorRoute);
          return;
        }
      }

      // Handle all roles (combined logic)
      switch (role) {
        case 'Patient':
          Navigator.pushReplacementNamed(context, AppConstants.patientDashboardRoute);
          break;
        case 'Doctor':
          Navigator.pushReplacementNamed(context, AppConstants.doctorRoute);
          break;
        case 'CHW':
          Navigator.pushReplacementNamed(context, AppConstants.chwRoute);
          break;
        case 'Admin':
          Navigator.pushReplacementNamed(context, AppConstants.adminRoute);
          break;
        default:
          Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
      }

    } catch (e) {
      // If anything fails, go to onboarding
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.onboardingRoute);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF212332), // Amar's dark background
      body: Container(
        // Amar's gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF212332),
              Color(0xFF2A2D3E),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo placeholder - Amar's design
              Container(
                height: screenHeight * 0.2,
                width: screenWidth * 0.4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2697FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  size: 100,
                  color: Color(0xFF2697FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TB-CareAI',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2697FF), // primaryColor
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI-powered TB screening & guidance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // Continue Button - Amar's design with loading state
              _isCheckingAuth
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: const CircularProgressIndicator(
                  color: Color(0xFF2697FF),
                  strokeWidth: 2,
                ),
              )
                  : ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2697FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),

              // Optional: Add a sign out option for testing
              if (_auth.currentUser != null && !_isCheckingAuth) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await _auth.signOut();
                    setState(() {});
                  },
                  child: Text(
                    'Not ${_auth.currentUser?.email}? Sign out',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}