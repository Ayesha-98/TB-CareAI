import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/core/app_constants.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isVerifying = false;
  bool _isCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _startAutoVerificationCheck();
  }

  void _startAutoVerificationCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      User? user = _auth.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        _autoCheckTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        }
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isVerifying = true);

    User? user = _auth.currentUser;
    await user?.reload();
    user = _auth.currentUser;

    if (user != null && user.emailVerified) {
      _autoCheckTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email is not verified yet.")),
      );
    }

    setState(() => _isVerifying = false);
  }

  Future<void> _resendVerification() async {
    if (_isCooldown) return;

    setState(() {
      _isCooldown = true;
      _cooldownSeconds = 30;
    });

    try {
      User? user = _auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found. Please log in again.")),
        );
        return;
      }

      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your email is already verified.")),
        );
        return;
      }

      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email resent.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        timer.cancel();
        setState(() {
          _isCooldown = false;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(extraLargePadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(largeRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: largePadding),
                const Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: headingSize,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: defaultPadding),
                Text(
                  "A verification link has been sent to your email.\nPlease verify before signing in.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodySize,
                    color: secondaryColor.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: extraLargePadding),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _isVerifying ? null : _checkVerification,
                    label: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "I have verified",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: bodySize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(defaultRadius),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                TextButton(
                  onPressed: _isCooldown ? null : _resendVerification,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                  child: Text(
                    _isCooldown
                        ? "Wait $_cooldownSeconds s..."
                        : "Resend Email",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: bodySize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
