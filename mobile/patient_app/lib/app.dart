import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart'; // ✅ ADD THIS IMPORT

// Patient screens
import 'patient/dashboard_screen.dart';
import 'patient/profile_screen.dart';
import 'patient/screening_screen.dart';
import 'patient/health_tips_screen.dart';
import 'patient/education_screen.dart';
import 'patient/diet_recommendation_screen.dart';
import 'patient/chat_bot_screen.dart';
import 'patient/nearby_hospitals_screen.dart';
import 'patient/exercise_plan.dart';
import 'patient/test_report.dart';
import 'patient/notifications_screen.dart';


import 'auth/splash_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/signin_screen.dart';
import 'auth/verify_email_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/forgot_password_screen.dart';


class TBApp extends StatelessWidget {
  const TBApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ WRAP MaterialApp with OverlaySupport.global
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'TB Care',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.grey[100],
          primarySwatch: Colors.teal,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/splash',

        // ✅ All route mappings
        routes: {
          // --- Authentication Flow ---
          '/splash' : (context) =>  SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/verify': (context) => const VerifyEmailScreen(),
          '/forgotPassword': (context) => const ForgotPasswordScreen(),

          '/dashboard': (context) => const PatientDashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/screening': (context) => const ScreeningScreen(),
          '/healthtips': (context) => const HealthTipsScreen(),
          '/education': (context) => const EducationScreen(),
          '/diet': (context) => const DietRecommendationScreen(),
          '/chatbot': (context) => const ChatBotScreen(),
          '/hospitals': (context) => const NearbyHospitalsScreen(),
          '/exercise' : (context) => const ExerciseScreen(),
          '/test-reports': (context) => const TestReportScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },

        // ❌ Fallback for unknown routes
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("Oops! Page not found or unavailable. Please go back."),
            ),
          ),
        ),
      ),
    );
  }
}