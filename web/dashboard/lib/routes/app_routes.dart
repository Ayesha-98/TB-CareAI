import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

// Core imports
import 'package:tbcare_main/core/app_constants.dart' hide bgColor, primaryColor;

// Existing screens
import 'package:tbcare_main/features/auth/splash_screen.dart';
import 'package:tbcare_main/features/auth/onboarding_screen.dart';
import 'package:tbcare_main/features/auth/signin_screen.dart';
import 'package:tbcare_main/features/auth/signup_screen.dart';
import 'package:tbcare_main/features/auth/verify_email_screen.dart';
import 'package:tbcare_main/features/auth/forgot_password_screen.dart';

// Existing web/doctor screens
import 'package:tbcare_main/features/landing/web_landing_screen.dart';
import 'package:tbcare_main/features/doctor/screens/main/main_screen.dart';


import '../features/doctor/screens/profile/doctor_profile_screen.dart';


// Patient screens
import 'package:tbcare_main/features/patient/dashboard_screen.dart' hide bgColor, secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/screening_screen.dart' hide secondaryColor, primaryColor, bgColor;
import 'package:tbcare_main/features/patient/profile_screen.dart' hide bgColor, secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/health_tips_screen.dart' hide secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/education_screen.dart' hide secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/diet_recommendation_screen.dart'
    hide secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/exercise_plan.dart' hide secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/chat_bot_screen.dart';
import 'package:tbcare_main/features/patient/nearby_hospitals_screen.dart' hide bgColor, secondaryColor, primaryColor;
import 'package:tbcare_main/features/patient/test_report.dart' hide bgColor, secondaryColor, primaryColor; // ✅ ADD THIS
import 'package:tbcare_main/features/patient/notifications_screen.dart' hide bgColor, secondaryColor, primaryColor; // ✅ ADD THIS

// New feature screens from main.dart (CHW and related)
import 'package:tbcare_main/features/chw/screens/chw_dashboard.dart' hide secondaryColor;
import 'package:tbcare_main/features/chw/screens/manage_patients_screen.dart';
import 'package:tbcare_main/features/chw/screens/patient_screening_screen.dart';
import 'package:tbcare_main/features/chw/screens/patient_followup_screen.dart';
import 'package:tbcare_main/features/chw/screens/flagged_patients_screen.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/features/chw/screens/doctor_notes_screen.dart';
import 'package:tbcare_main/features/chw/screens/lab_test_screen.dart';


class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final bool isWeb = kIsWeb;
    final bool isMobile = UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

    switch (settings.name) {
    // Entry point - WebLanding for web, Splash for mobile
      case '/':
        if (isWeb) {
          return _buildRoute(
            const WebLandingScreen(),
            settings,
            transitionType: RouteTransition.fade,
          );
        } else {
          return _buildRoute(
            SplashScreen(),
            settings,
            transitionType: RouteTransition.fade,
          );
        }

    // Splash - triggered from WebLanding
      case AppConstants.splashRoute:
        return _buildRoute(
          SplashScreen(),
          settings,
          transitionType: RouteTransition.fade,
        );

    // Onboarding
      case AppConstants.onboardingRoute:
        return _buildRoute(
          const OnboardingScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Auth routes
      case AppConstants.signinRoute:
        return _buildRoute(
          const SignInScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

      case AppConstants.signupRoute:
        return _buildRoute(
          const SignUpScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

      case AppConstants.verifyEmailRoute:
        return _buildRoute(
          const VerifyEmailScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

      case AppConstants.forgotPasswordRoute:
        return _buildRoute(
          const ForgotPasswordScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Web Landing
      case AppConstants.webLandingRoute:
        return _buildRoute(
          const WebLandingScreen(),
          settings,
          transitionType: RouteTransition.fade,
        );

    // Doctor dashboard and patients screens
      case AppConstants.doctorRoute:
        return _buildRoute(
          const MainScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

      case AppConstants.doctorProfileRoute:
        return _buildRoute(
          const DoctorProfileScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // ✅ PATIENT DASHBOARD ROUTES

    // Main Patient Dashboard
      case AppConstants.patientDashboardRoute:
        return _buildRoute(
          const PatientDashboardScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Screening
      case AppConstants.patientScreeningRoute:
        return _buildRoute(
          const ScreeningScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Profile
      case AppConstants.patientProfileRoute:
        return _buildRoute(
          const ProfileScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Health Tips
      case AppConstants.patientHealthTipsRoute:
        return _buildRoute(
          const HealthTipsScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Education
      case AppConstants.patientEducationRoute:
        return _buildRoute(
          const EducationScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Diet Recommendation
      case AppConstants.patientDietRecommendationRoute:
        return _buildRoute(
          const DietRecommendationScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Exercise
      case AppConstants.patientExerciseTrackingRoute:
        return _buildRoute(
          const ExerciseScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Chatbot
      case AppConstants.patientChatBotRoute:
        return _buildRoute(
          const ChatBotScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // Patient Nearby Hospitals
      case AppConstants.patientNearbyHospitalsRoute:
        return _buildRoute(
          const NearbyHospitalsScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // ✅ PATIENT TEST REPORTS & NOTIFICATIONS (ADD THESE)
      case AppConstants.patientTestReports:
        return _buildRoute(
          const TestReportScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

      case '/notifications':
        return _buildRoute(
          const NotificationsScreen(),
          settings,
          transitionType: RouteTransition.slideFromRight,
        );

    // CHW routes (new from main.dart)
      case AppConstants.chwRoute: // existing route: '/chw'
        return _buildRoute(
          const CHWDashboard(),
          settings,
        );

      case AppConstants.chwDashboardRoute: // mapped to '/CHW' from main.dart
        return _buildRoute(
          const CHWDashboard(),
          settings,
        );

      case AppConstants.managePatientsRoute: // '/add_patient'
        return _buildRoute(
          const ManagePatientsScreen(),
          settings,
        );

      case AppConstants.chwScreeningRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientScreeningScreen(
            patientId: args['patientId'],
            //screeningId: args['screeningId'],
            patientName: args['patientName'],
          ),
        );

      case AppConstants.chwFollowupsRoute: // '/chw_followups'
        return _buildRoute(
          const FollowUpScreen(),
          settings,
        );

      case AppConstants.aiFlaggedRoute: // '/ai_flagged'
        final screening = settings.arguments as Screening;
        return _buildRoute(
          FlaggedPatientsScreen(screening: screening),
          settings,
        );

      case AppConstants.doctorNotesRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          DoctorNotesScreen(
            patientId: args['patientId'],
            screeningId: args['screeningId'],
            patientName: args['patientName'],
          ),
          settings,
        );

      case AppConstants.labTestRoute:
        return _buildRoute(
          const LabTestScreen(),
          settings,
        );



    // Default/fallback - Not found
      default:
        return _buildRoute(
          NotFoundScreen(routeName: settings.name ?? 'Unknown'),
          settings,
        );
    }
  }

  static Route<dynamic> _buildRoute(
      Widget child,
      RouteSettings settings, {
        RouteTransition transitionType = RouteTransition.material,
      }) {
    switch (transitionType) {
      case RouteTransition.fade:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );

      case RouteTransition.slideFromRight:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case RouteTransition.slideFromBottom:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case RouteTransition.material:
      default:
        return MaterialPageRoute(builder: (_) => child, settings: settings);
    }
  }

  // Navigation helper methods for patient routes
  static void navigateToPatientDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.patientDashboardRoute,
          (route) => false,
    );
  }

  static void navigateToPatientScreening(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientScreeningRoute,
    );
  }

  static void navigateToPatientProfile(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientProfileRoute,
    );
  }

  static void navigateToPatientHealthTips(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientHealthTipsRoute,
    );
  }

  static void navigateToPatientEducation(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientEducationRoute,
    );
  }

  static void navigateToPatientDiet(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientDietRecommendationRoute,
    );
  }

  static void navigateToPatientExercise(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientExerciseTrackingRoute,
    );
  }

  static void navigateToPatientChatbot(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientChatBotRoute,
    );
  }

  static void navigateToPatientNearbyHospitals(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppConstants.patientNearbyHospitalsRoute,
    );
  }

  // ✅ ADD THESE NAVIGATION METHODS
  static void navigateToTestReports(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/test-reports',
    );
  }

  static void navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/notifications',
    );
  }

  // Existing navigation methods...
  static void navigateToWebLanding(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.webLandingRoute,
          (route) => false,
    );
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.signinRoute,
          (route) => false,
    );
  }

  static void navigateToDoctorDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.doctorRoute,
          (route) => false,
    );
  }

  static void navigateToOnboarding(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.onboardingRoute,
          (route) => false,
    );
  }
}

// Enum for different route transition types
enum RouteTransition {
  material,
  fade,
  slideFromRight,
  slideFromBottom,
}

// Placeholder screens for development
class PlaceholderDashboard extends StatelessWidget {
  final String title;

  const PlaceholderDashboard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppConstants.webLandingRoute,
                (route) => false,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Coming Soon',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This dashboard is under development',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.webLandingRoute,
                    (route) => false,
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen for mobile dashboard redirects on web
class MobileDashboardRedirect extends StatelessWidget {
  final String dashboardType;

  const MobileDashboardRedirect({super.key, required this.dashboardType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: Text('$dashboardType Dashboard'),
      ),
      body: Center(
        child: Card(
          color: secondaryColor,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '$dashboardType Dashboard',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This dashboard is optimized for mobile devices.\nPlease use the mobile app for the best experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppConstants.webLandingRoute,
                            (route) => false,
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Could open app store links or show QR code
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Get App'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 404 Not Found screen
class NotFoundScreen extends StatelessWidget {
  final String routeName;

  const NotFoundScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Route "$routeName" does not exist',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                kIsWeb ? AppConstants.webLandingRoute : AppConstants.splashRoute,
                    (route) => false,
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}