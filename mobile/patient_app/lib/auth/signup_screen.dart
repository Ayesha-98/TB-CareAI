import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tb_project/auth/services/signup_service.dart';
import 'package:tb_project/core/app_constants.dart';
import 'package:tb_project/core/location_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Patient';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  String? _detectedCity;
  bool _isCheckingLocation = false;

  final AuthService _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    // Check location silently on load
    _checkLocationSilently();
  }

  Future<void> _checkLocationSilently() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      String? city = await LocationService.getCurrentCity();
      setState(() {
        _detectedCity = city;
      });
    }
  }

  /// Show location dialog before sign-up
  Future<bool> _checkLocationBeforeSignUp() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      final shouldEnable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Text("Location Recommended"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TB Care AI uses your location to:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text("Show TB statistics in your area"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_hospital, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text("Connect you with nearby doctors"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.health_and_safety, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text("Provide region-specific health advice"),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "You can still sign up without location, but some features will be limited.",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Skip", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text("Enable Location"),
            ),
          ],
        ),
      );

      if (shouldEnable == true) {
        setState(() {
          _isCheckingLocation = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }

    if (serviceEnabled) {
      setState(() {
        _isCheckingLocation = true;
      });
      String? city = await LocationService.getCurrentCity();
      setState(() {
        _detectedCity = city;
        _isCheckingLocation = false;
      });
      if (city != null && city != "Unknown" && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Location detected: $city"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    return serviceEnabled;
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      hintText: hint,
      filled: true,
      fillColor: secondaryColor.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Check location before sign-up
    await _checkLocationBeforeSignUp();

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;

    final error = await _authService.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      status: "Active",
      flagged: false,
      detectedCity: _detectedCity,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pushNamed(context, '/verify');
    }
  }

  // Handle Google Sign Up
  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);

    // Check location before Google sign-up
    await _checkLocationBeforeSignUp();

    try {
      final result = await _authService.signInWithGoogle();

      if (result["success"] == true) {
        final user = result["user"];
        final isNewUser = result["isNewUser"] ?? false;

        if (isNewUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome! Your Patient account has been created.")),
          );
        }

        _navigateBasedOnRole(user.role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign up failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateBasedOnRole(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        Navigator.pushReplacementNamed(context, AppConstants.patientRoute);
        break;
      case 'doctor':
        Navigator.pushReplacementNamed(context, AppConstants.doctorRoute);
        break;
      case 'chw':
        Navigator.pushReplacementNamed(context, AppConstants.chwRoute);
        break;
      case 'admin':
        Navigator.pushReplacementNamed(context, AppConstants.adminRoute);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown user role")),
        );
    }
  }

  Widget _buildLocationStatus() {
    if (_isCheckingLocation) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Detecting your location...",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (_detectedCity != null && _detectedCity != "Unknown") {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Location detected: $_detectedCity",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Enable location for better TB care recommendations",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleField() {
    return TextFormField(
      readOnly: true,
      initialValue: 'Patient',
      style: const TextStyle(color: secondaryColor),
      decoration: _inputDecoration('Role', Icons.verified_user).copyWith(
        hintText: 'Patient',
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.black26)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.black26)),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: _isGoogleLoading
            ? SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
          ),
        )
            : Image.asset('assets/images/google.png', height: 18, width: 18),
        label: _isGoogleLoading
            ? Text(
          'Signing up...',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        )
            : Text(
          'Continue with Google',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Enter your full name";
    final trimmed = value.trim();
    if (!trimmed.contains(' ')) return "Enter both first & last name";
    if (trimmed.length < 5 || trimmed.length > 40) return "Must be 5–40 characters";
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(trimmed)) return "Only letters & spaces allowed";
    final lower = trimmed.toLowerCase();
    const reserved = ['admin','root','superuser','patient','user','chw','doctor'];
    if (reserved.any((word) => lower.contains(word))) {
      return "This name is not allowed";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email required";
    final trimmed = value.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(trimmed)) return "Enter a valid email";

    const allowedDomains = [
      'gmail.com','yahoo.com','hotmail.com','outlook.com','icloud.com'
    ];
    final domain = trimmed.split('@').last.toLowerCase();
    if (!allowedDomains.contains(domain)) {
      return "Email domain not allowed";
    }

    final username = trimmed.split('@').first.toLowerCase();

    const blacklistedUsernames = [
      'test', 'demo', 'fake', 'dummy', 'temp', 'temporary', 'example',
      'sample', 'admin', 'user', 'guest', 'noone', 'nothing', 'empty',
      'null', 'undefined', 'unknown', 'anonymous', 'invalid', 'wrong',
      'incorrect', 'error', 'false', 'true', 'yes', 'no', 'ok', 'hello',
      'hi', 'hey', 'welcome', 'mail', 'email', 'contact', 'support',
      'help', 'info', 'service', 'web', 'site', 'website', 'page',
      'home', 'default', 'backup', 'tempuser', 'testuser', 'demoaccount',
      'fakemail', 'dummymail', 'abcd', 'abc', 'xyz', 'qwerty', 'asdf',
      'zxcv', '1234', '1111', '0000', 'aaaa', 'bbbb', 'cccc', 'dddd',
      'eeee', 'ffff', 'adminuser', 'rootuser', 'superuser', 'master',
      'owner', 'manager', 'operator', 'system', 'server', 'localhost',
      'domain', 'company', 'business', 'organization', 'institution',
      'tbcare', 'tbcareai', 'doctor', 'patient', 'chw', 'nurse', 'staff',
      'medical', 'health', 'hospital', 'clinic', 'pharmacy', 'lab'
    ];

    if (blacklistedUsernames.contains(username)) {
      return "This email username is not allowed";
    }

    if (username.length < 4) {
      return "Email username must be at least 4 characters";
    }

    final sequentialRegex = RegExp(r'(.)\1{3,}');
    if (sequentialRegex.hasMatch(username)) {
      return "Email contains suspicious pattern";
    }

    final numberOnlyRegex = RegExp(r'^\d+$');
    if (numberOnlyRegex.hasMatch(username)) {
      return "Number-only usernames are not allowed";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "At least 8 characters required";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Must include an uppercase letter";
    if (!RegExp(r'[a-z]').hasMatch(value)) return "Must include a lowercase letter";
    if (!RegExp(r'[0-9]').hasMatch(value)) return "Must include a number";
    if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Must include a special character";
    }

    final name = _nameController.text.trim().toLowerCase();
    final pass = value.toLowerCase();
    final nameParts = name.split(RegExp(r'\s+'));
    for (var part in nameParts) {
      if (part.isNotEmpty && pass.contains(part)) {
        return "Password cannot contain your name";
      }
    }

    final emailPrefixRaw = _emailController.text.trim().split('@')[0].toLowerCase();
    final emailPrefix = emailPrefixRaw.replaceAll(RegExp(r'[^a-z]'), '');
    if (emailPrefix.isNotEmpty && pass.contains(emailPrefix)) {
      return "Password cannot contain your email";
    }

    const blacklist = [
      'password','pass','qwerty','123456','111111','abc123',
      'letmein','welcome','iloveyou','test','login','admin',
      'user','root',
      'tb','tbcare','tbcarea','careai','doctor','dr','tbcareai','tbcare-ai',
      'chw','patient','nurse','health','medical','clinic','hospital','system',
      '2020','2021','2022','2023','2024','2025',
      '1234','4321','0000','9999',
    ];
    for (var word in blacklist) {
      if (pass.contains(word)) {
        return 'Password too weak (contains "$word")';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).size.width * 0.06;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(screenHeight),
                    const SizedBox(height: 30),
                    Text('Create Your Account',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const SizedBox(height: 32),

                    // ✅ Location Status Widget
                    _buildLocationStatus(),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: secondaryColor),
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: secondaryColor),
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: secondaryColor),
                      decoration: _inputDecoration('Password', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: secondaryColor,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleField(),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign Up', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOrDivider(),
                    const SizedBox(height: 24),

                    _buildGoogleSignUpButton(),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ",
                            style: TextStyle(color: secondaryColor)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, AppConstants.loginRoute),
                          child: Text('Sign In',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double screenHeight) {
    return Container(
      height: screenHeight * 0.18,
      width: screenHeight * 0.18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withOpacity(0.1),
        border: Border.all(color: primaryColor, width: 1),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Image.asset(
            'assets/images/logo light.png',
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}