import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tbcare_main/core/app_constants.dart';

class Breakpoints {
  static const double tablet = 900;
  static const double desktop = 1200;
}

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _hoveredIndex = -1;

  Future<void> _handleSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.signinRoute,
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > Breakpoints.desktop;
    final isTablet = screenSize.width > Breakpoints.tablet && !isDesktop;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(screenSize),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(isDesktop),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? screenSize.width * 0.1 : defaultPadding,
                vertical: largePadding,
              ),
              child: _buildDashboardGrid(isDesktop, isTablet),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    final isWideScreen = screenSize.width > 800;
    final isMediumScreen = screenSize.width > 600;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: isWideScreen ? 32 : 16,
      title: Row(
        children: [
          Icon(Icons.local_hospital_rounded, color: primaryColor, size: 32),
          const SizedBox(width: 12),
          Text(
            'TB-Care AI',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: isWideScreen ? 24 : 20,
            ),
          ),
          const Spacer(),
          if (!isMediumScreen && currentUser != null)
            IconButton(
              icon: const Icon(Icons.person, color: primaryColor),
              onPressed: () => _showUserMenu(context),
              tooltip: 'User Menu',
            ),
        ],
      ),
      actions: [
        if (currentUser != null && isMediumScreen)
          Container(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  radius: 18,
                  child: Text(
                    currentUser!.email?[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isWideScreen)
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.6),
                            fontSize: 11,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currentUser!.email ?? 'User',
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Sign Out',
                  child: IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: secondaryColor,
                      size: 22,
                    ),
                    onPressed: _handleSignOut,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                radius: 32,
                child: Text(
                  currentUser!.email?[0].toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentUser!.email ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/splash_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            primaryColor.withOpacity(0.9),
            BlendMode.srcOver,
          ),
          onError: (_, __) {},
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.dashboard_rounded,
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Your Dashboard',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 48 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Select your role below to access the appropriate tools, patient records, and diagnostic features.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(bool isDesktop, bool isTablet) {
    // For desktop: fixed width with centering, for mobile: full width
    if (isDesktop) {
      // Center the grid with fixed max width - increased for 3 cards
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1350), // Increased for 3 cards
          child: _buildGridContent(isDesktop, isTablet),
        ),
      );
    }
    return _buildGridContent(isDesktop, isTablet);
  }

  Widget _buildGridContent(bool isDesktop, bool isTablet) {
    // Changed to 3 columns for desktop, 2 for tablet, 1 for mobile
    int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    double aspectRatio = isDesktop ? 1.1 : (isTablet ? 1.0 : 1.4);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: aspectRatio,
      padding: const EdgeInsets.all(8),
      children: [
        // CHW Dashboard (First)
        _buildCard(
          index: 0,
          title: 'CHW Dashboard',
          description: 'Community Health Worker Tools & Patient Management',
          icon: Icons.health_and_safety_outlined,
          route: AppConstants.onboardingRoute,
          isImplemented: true,
        ),
        // Patient Dashboard (Second)
        _buildCard(
          index: 1,
          title: 'Patient Dashboard',
          description: 'TB Management, Recovery Tools & Health Tracking',
          icon: Icons.personal_injury,
          route: AppConstants.onboardingRoute,
          isImplemented: true,
        ),
        // Doctor Dashboard
        _buildCard(
          index: 2,
          title: 'Doctor Dashboard',
          description: 'Patient Management & AI Diagnostics',
          icon: Icons.medical_services_outlined,
          route: AppConstants.onboardingRoute,
          isImplemented: true,
        ),
      ],
    );
  }

  Widget _buildCard({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required String route,
    required bool isImplemented,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0, isHovered ? -8 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(largeRadius),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(isHovered ? 0.15 : 0.05),
              blurRadius: isHovered ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isHovered ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isImplemented) {
                Navigator.pushNamed(context, route);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Coming Soon!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(largeRadius),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? primaryColor
                          : primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: isHovered ? Colors.white : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor.withOpacity(0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isImplemented)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  if (isImplemented)
                    AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        'Click to Access',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
      child: Column(
        children: [
          Text(
            '© 2024 TB-Care AI. All rights reserved.',
            style: TextStyle(
              color: secondaryColor.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced Screening & Patient Management System',
            style: TextStyle(
              color: secondaryColor.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}