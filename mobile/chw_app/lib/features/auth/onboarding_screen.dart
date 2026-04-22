import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Section
                Container(
                  height: screenHeight * 0.30,
                  width: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    size: 100,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // App Title
                Text(
                  'TB-CareAI',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "Let's get started!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor, // 🔹 using secondary instead of white
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Screen your cough. Get expert care.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryColor.withOpacity(0.7), // softer text
                  ),
                ),
                const SizedBox(height: 48),

                // Login Button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppConstants.signinRoute),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign Up Button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppConstants.signupRoute),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16, color: primaryColor),
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