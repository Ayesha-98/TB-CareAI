import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/routes/app_routes.dart';

class TBCareApp extends StatelessWidget {
  const TBCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        debugShowCheckedModeBanner: false,
        navigatorKey: AppRoutes.navigatorKey,

        // Start with WebLanding for web (your current flow requirement)
        initialRoute: AppConstants.webLandingRoute,

        // Use centralized route generator
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class AuthStateProvider extends ChangeNotifier {
  bool _isInitialized = false;
  String? _userRole;
  String? _userId;

  bool get isInitialized => _isInitialized;
  String? get userRole => _userRole;
  String? get userId => _userId;

  void setInitialized() {
    _isInitialized = true;
    notifyListeners();
  }

  void setUserData(String userId, String role) {
    _userId = userId;
    _userRole = role;
    _isInitialized = true;
    notifyListeners();
  }

  void clearUserData() {
    _userId = null;
    _userRole = null;
    _isInitialized = false;
    notifyListeners();
  }
}
