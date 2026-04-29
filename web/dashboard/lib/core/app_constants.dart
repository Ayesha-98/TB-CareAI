import 'package:flutter/material.dart';

/// ====================
/// 🎨 App Colors
/// ====================
const Color primaryColor = Color(0xFF1B4D3E);   // Pthalo Green - main brand
const Color secondaryColor = Color(0xFF2E3B4E); // Slate/charcoal for surfaces
const Color bgColor = Color(0xFFF5F7F8);        // Soft light background

// Additional colors for better theming
const Color accentColor = Color(0xFF3A6EA5);    // Muted professional blue
const Color errorColor = Color(0xFFE74C3C);     // Standard error red
const Color successColor = Color(0xFF2ECC71);   // Medical green
const Color warningColor = Color(0xFFF39C12);

/// ====================
/// 📐 Spacing
/// ====================
const double defaultPadding = 16.0;
const double smallPadding = 8.0;
const double largePadding = 24.0;
const double extraLargePadding = 32.0;

/// ====================
/// ⭕ Border Radius
/// ====================
const double defaultRadius = 8.0;
const double smallRadius = 4.0;
const double largeRadius = 16.0;

/// ====================
/// 🔠 Text Sizes
/// ====================
const double headingSize = 24.0;
const double titleSize = 20.0;
const double bodySize = 16.0;
const double captionSize = 14.0;
const double smallSize = 12.0;

/// ====================
/// ℹ️ App Information
/// ====================
class AppConstants {
  static const String appName = 'TB-Care AI';
  static const String appDescription = 'AI-powered TB screening & guidance';
  static const String version = '1.0.0';

  // Route Names - 
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String signinRoute = '/login';
  static const String signupRoute = '/signup';
  static const String verifyEmailRoute = '/verify';
  static const String forgotPasswordRoute = '/forgot_password';
  static const String webLandingRoute = '/web_landing';

  // Existing routes
  static const String doctorRoute = '/doctor';
  static const String adminRoute = '/admin';
  static const String chwRoute = '/chw';
  static const String doctorProfileRoute = '/doctor_profile';

  static const String patientDashboardRoute = '/patient';
  static const String patientScreeningRoute = '/patient/screening';
  static const String patientProfileRoute = '/patient/profile';
  static const String patientHealthTipsRoute = '/patient/healthtips';
  static const String patientEducationRoute = '/patient/education';
  static const String patientDietRecommendationRoute = '/patient/diet';
  static const String patientExerciseTrackingRoute = '/patient/exercise';
  static const String patientChatBotRoute = '/patient/chatbot';
  static const String patientNearbyHospitalsRoute = '/patient/nearby-hospitals';
  static const String patientTestReports = '/patient/test_reports';

  // New routes from provided main.dart
  static const String chwDashboardRoute = '/CHW';
  static const String managePatientsRoute = '/add_patient';
  static const String chwScreeningRoute = '/chw_screening';
  static const String chwFollowupsRoute = '/chw_followups';
  static const String chwReferralsRoute = '/chw_referrals';
  static const String aiFlaggedRoute = '/ai_flagged';
  static const String patientsScreeningRoute = '/patient_screening';
  static const String doctorNotesRoute = '/doctor_notes';
  static const String labTestRoute = '/lab_test';
  static const String patientNotificationsRoute = '/notifications';


  // Legacy support - keeping old names for backward compatibility
  static const String loginRoute = signinRoute;
  static const String verifyRoute = verifyEmailRoute;


}

/// ====================
/// 📱 Breakpoints
/// ====================
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1800;
}

/// ====================
/// ⏱️ Animation Durations
/// ====================
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// ====================
/// 🖼️ Asset Paths
/// ====================
class AssetPaths {
  static const String logo = 'assets/images/logo light.png';
  static const String googleIcon = 'assets/google.png';
  static const String userDP = 'assets/user_dp.png';
  static const String splashBg = 'assets/splash_bg.png';

  // Icons
  static const String iconsPath = 'assets/icons/';
  static const String imagesPath = 'assets/images/';
}

/// ====================
/// ❌ Error Messages
/// ====================
class ErrorMessages {
  static const String networkError = 'Network connection failed';
  static const String authError = 'Authentication failed';
  static const String permissionError = 'Permission denied';
  static const String genericError = 'Something went wrong';
  static const String emailNotVerified = 'Please verify your email';
  static const String invalidCredentials = 'Invalid email or password';
}

/// ====================
/// ✅ Success Messages
/// ====================
class SuccessMessages {
  static const String loginSuccess = 'Login successful';
  static const String signupSuccess = 'Account created successfully';
  static const String emailSent = 'Verification email sent';
  static const String passwordReset = 'Password reset email sent';
}

/// ====================
/// 🎨 App Theme
/// ====================
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: bgColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: bgColor,
      onPrimary: Colors.white,        
      onSecondary: Colors.white,     
      onError: Colors.white,
      onBackground: secondaryColor,  
      onSurface: secondaryColor,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: headingSize,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: bodySize,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: captionSize,
        color: Colors.black54,
      ),
      labelLarge: TextStyle(
        fontSize: captionSize,
        fontWeight: FontWeight.w600,
        color: Colors.white, // buttons
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.black54),
      labelStyle: TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white, // input background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
        borderSide: BorderSide(color: secondaryColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
        borderSide: BorderSide(color: secondaryColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}
