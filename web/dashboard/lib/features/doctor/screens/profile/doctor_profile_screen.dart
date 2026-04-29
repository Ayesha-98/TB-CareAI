import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/doctor_profile_model.dart';
import 'package:tbcare_main/features/doctor/services/doctor_profile_service.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/profile_image_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/quick_stats_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/profile_section_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/info_row_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/stat_card_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/activity_item_widget.dart';
import 'package:tbcare_main/features/doctor/screens/profile/components/settings_bottom_sheet.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final DoctorProfileService _profileService = DoctorProfileService();
  late Doctor _doctor;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;

  // Controllers for editing
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDoctorProfile();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final doctor = await _profileService.getCurrentDoctorProfileOnce();
      
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
          _populateControllers();
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load profile. Please try again.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile.'), backgroundColor: errorColor),
        );
      }
    }
  }

  void _populateControllers() {
    _nameController.text = _doctor.name;
    _phoneController.text = _doctor.phone;
    _specializationController.text = _doctor.specialization;
    _hospitalController.text = _doctor.hospital ?? '';
    _experienceController.text = _doctor.experience ?? '';
    _qualificationsController.text = _doctor.qualifications ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading 
          ? _buildLoadingWidget() 
          : _errorMessage != null 
              ? _buildErrorWidget()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: errorColor),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: errorColor, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDoctorProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: primaryColor),
    );
  }

  Widget _buildProfileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 70.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  QuickStatsWidget(
                    confirmedTBCount: _doctor.confirmedTBCount,
                    totalPatientsReviewed: _doctor.totalPatientsReviewed,
                    totalDiagnosisMade: _doctor.totalDiagnosisMade,
                  ),
                  const SizedBox(height: largePadding),
                  _buildPersonalInfo(),
                  const SizedBox(height: largePadding),
                  _buildProfessionalInfo(),
                  const SizedBox(height: largePadding),
                  _buildStatisticsSection(),
                  const SizedBox(height: largePadding),
                  _buildRecentActivity(),
                  const SizedBox(height: extraLargePadding),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _handleEditToggle,
          icon: Icon(
            _isEditing ? Icons.save : Icons.edit,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: _showSettingsMenu,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                ProfileImageWidget(
                  profileImageUrl: _doctor.profileImageUrl,
                  isEditing: _isEditing,
                  onTap: () {},
                ),
                const SizedBox(height: defaultPadding),
                Text(
                  _doctor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: headingSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: smallPadding),
                Text(
                  _doctor.specialization.isEmpty ? 'Add Specialization' : _doctor.specialization,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: bodySize,
                    fontStyle: _doctor.specialization.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (_doctor.hospital != null && _doctor.hospital!.isNotEmpty) ...[
                  const SizedBox(height: smallPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _doctor.hospital!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: captionSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return ProfileSectionWidget(
      title: 'Personal Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          InfoRowWidget(
            label: 'Name',
            value: _doctor.name.isEmpty ? 'Not specified' : _doctor.name,
            icon: Icons.person,
            controller: _nameController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Phone',
            value: _doctor.phone.isEmpty ? 'Not specified' : _doctor.phone,
            icon: Icons.phone,
            controller: _phoneController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Email',
            value: _doctor.email ?? 'Not provided',
            icon: Icons.email,
            isEditing: false,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Member Since',
            value: _formatDate(_doctor.createdAt),
            icon: Icons.calendar_today,
            isEditing: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return ProfileSectionWidget(
      title: 'Professional Information',
      icon: Icons.work_outline,
      child: Column(
        children: [
          InfoRowWidget(
            label: 'Specialization',
            value: _doctor.specialization.isEmpty ? 'Not specified' : _doctor.specialization,
            icon: Icons.medical_services,
            controller: _specializationController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Hospital/Clinic',
            value: _doctor.hospital ?? 'Not specified',
            icon: Icons.local_hospital,
            controller: _hospitalController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Experience',
            value: _doctor.experience ?? 'Not specified',
            icon: Icons.timeline,
            controller: _experienceController,
            isEditing: _isEditing,
          ),
          const SizedBox(height: defaultPadding),
          InfoRowWidget(
            label: 'Qualifications',
            value: _doctor.qualifications ?? 'Not specified',
            icon: Icons.school,
            controller: _qualificationsController,
            isEditing: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return ProfileSectionWidget(
      title: 'Performance Statistics',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  title: 'Final Verdicts',
                  value: _doctor.totalFinalVerdicts.toString(),
                  icon: Icons.gavel,
                  color: successColor,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                child: StatCardWidget(
                  title: 'Recommendations',
                  value: _doctor.totalRecommendationsGiven.toString(),
                  icon: Icons.recommend,
                  color: warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  title: 'Tests Requested',
                  value: _doctor.totalTestsRequested.toString(),
                  icon: Icons.science,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: defaultPadding),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return ProfileSectionWidget(
      title: 'Recent Activity',
      icon: Icons.history,
      child: Column(
        children: [
          ActivityItemWidget(
            title: 'Last Login',
            subtitle: 'Today at 9:30 AM',
            icon: Icons.login,
            color: primaryColor,
          ),
          const SizedBox(height: defaultPadding),
          ActivityItemWidget(
            title: 'Last Diagnosis',
            subtitle: '2 hours ago',
            icon: Icons.assignment_turned_in,
            color: successColor,
          ),
          const SizedBox(height: defaultPadding),
          ActivityItemWidget(
            title: 'Profile Updated',
            subtitle: _formatDate(_doctor.createdAt),
            icon: Icons.edit,
            color: warningColor,
          ),
        ],
      ),
    );
  }

  void _handleEditToggle() async {
    if (_isEditing) {
      await _saveProfile();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    try {
      final updatedDoctor = _doctor.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        specialization: _specializationController.text,
        hospital: _hospitalController.text.isEmpty ? null : _hospitalController.text,
        experience: _experienceController.text.isEmpty ? null : _experienceController.text,
        qualifications: _qualificationsController.text.isEmpty ? null : _qualificationsController.text,
      );

      await _profileService.updateDoctorProfile(updatedDoctor);
      
      if (mounted) {
        setState(() {
          _doctor = updatedDoctor;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsBottomSheet(
        onChangePassword: _changePassword,
        onExportData: _exportData,
        onPrivacySettings: _showPrivacySettings,
        onSignOut: _signOut,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _changePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon'),
        backgroundColor: warningColor,
      ),
    );
  }

  void _showPrivacySettings() {
    Navigator.pushNamed(context, '/privacy-settings');
  }

  Future<void> _signOut() async {
    try {
      await _profileService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/webLandingPage',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }
}