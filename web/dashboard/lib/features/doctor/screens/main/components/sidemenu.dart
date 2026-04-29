import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/core/app_constants.dart'; 
import 'package:tbcare_main/core/responsive.dart';
import 'package:tbcare_main/features/doctor/screens/diet/diet_exercise_screen.dart';
import 'package:tbcare_main/features/doctor/screens/recommendation/recommendation_screen.dart';
import 'package:tbcare_main/features/doctor/screens/screening/screening_daignosis_screen.dart';
import '../../patients/patients_screen.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/web_landing', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDrawerMode = !Responsive.isDesktop(context);

    // Modern polished gradient or solid primary color
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 15,
               offset: const Offset(4, 0),
             ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding,
        ),
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(defaultPadding, defaultPadding, defaultPadding, largePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDrawerMode)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(16), // Rounded square
                       border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    child: Image.asset(
                      "assets/images/logo light.png",
                      height: 60, 
                      width: 60,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DrawerListTile(
                      title: 'Dashboard',
                      svgSrc: "assets/icons/hospital.svg",
                      press: () => onItemSelected(0),
                      isSelected: selectedIndex == 0,
                    ),
                    DrawerListTile(
                      title: 'Patients',
                      svgSrc: "assets/icons/activity.svg",
                      press: () => onItemSelected(1),
                      isSelected: selectedIndex == 1,
                    ),
                    DrawerListTile(
                      title: 'Screening & Diagnosis',
                      svgSrc: "assets/icons/graph-up.svg",
                      press: () => onItemSelected(2),
                      isSelected: selectedIndex == 2,
                    ),
                    DrawerListTile(
                      title: 'Recommendation',
                      svgSrc: "assets/icons/recommendation.svg",
                      press: () => onItemSelected(3),
                      isSelected: selectedIndex == 3,
                    ),
                    DrawerListTile(
                      title: 'Diet & Exercise',
                      svgSrc: "assets/icons/stats-report.svg",
                      press: () => onItemSelected(4),
                      isSelected: selectedIndex == 4,
                    ),
                  ],
                ),
              ),
            ),

            // Logout button at bottom - Refined size
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1), // Subtle styling instead of jarring red
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    "Logout", 
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerListTile extends StatefulWidget {
  const DrawerListTile({
    super.key,
    required this.title,
    required this.svgSrc,
    required this.press,
    this.isSelected = false,
  });

  final String title, svgSrc;
  final VoidCallback press;
  final bool isSelected;

  @override
  State<DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8), // Add spacing between items
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white.withOpacity(0.2) // Highlight selected
              : _isHovered
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12), // More rounded
          border: widget.isSelected 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
        ),
        child: ListTile(
          onTap: widget.press,
          horizontalTitleGap: 12.0,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              widget.svgSrc,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              height: 18,
              width: 18,
            ),
          ),
          title: Text(
            widget.title,
            maxLines: 1, // Enforce single line
            overflow: TextOverflow.ellipsis, // Ellipsis if too long
            style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.8),
              fontSize: 14, // Slightly smaller to fit "Screening & Diagnosis"
              fontWeight: (widget.isSelected || _isHovered) ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }
}