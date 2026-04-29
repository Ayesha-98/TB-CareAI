import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > Breakpoints.tablet) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
        margin: const EdgeInsets.all(largePadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(largeRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Side - Hero/Branding
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(largeRadius),
                    bottomLeft: Radius.circular(largeRadius),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(largePadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        size: 80,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: extraLargePadding),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: smallPadding),
                    Text(
                      AppConstants.appDescription,
                      style: TextStyle(
                        fontSize: bodySize,
                        color: secondaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Side - Actions
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(extraLargePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: defaultPadding),
                    Text(
                      "Sign in to access your dashboard and manage patients efficiently.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bodySize,
                        color: secondaryColor.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildLoginButton(context),
                    const SizedBox(height: defaultPadding),
                    _buildSignupButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: largePadding),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.1),
            // Logo Section
            Container(
              padding: const EdgeInsets.all(largePadding),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 64,
                color: primaryColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: smallPadding),
            Text(
              AppConstants.appDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                color: secondaryColor.withOpacity(0.7),
              ),
            ),
            SizedBox(height: screenHeight * 0.15),
            const Text(
              "Let's get started!",
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: smallPadding),
            Text(
              "Screen your cough. Get expert care.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                color: secondaryColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: screenHeight * 0.08),
            _buildLoginButton(context),
            const SizedBox(height: defaultPadding),
            _buildSignupButton(context),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, AppConstants.signinRoute),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: bodySize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.pushNamed(context, AppConstants.signupRoute),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: bodySize,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}