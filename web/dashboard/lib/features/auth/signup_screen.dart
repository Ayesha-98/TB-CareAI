import 'package:flutter/material.dart';
import 'package:tbcare_main/features/auth/services/signup_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/auth/doctor_qualification_screen.dart';
import 'models/signup_model.dart';

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
  String _selectedRole = 'Doctor';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  String? _selectedCity;
  bool _needsCityForGoogle = false;
  UserModel? _pendingGoogleUser;

  final AuthService _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pakistani cities list
  final List<String> _pakistaniCities = [
    'Islamabad',
    'Karachi',
    'Lahore',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Gujranwala',
    'Sialkot',
    'Bahawalpur',
    'Sargodha',
    'Sheikhupura',
    'Rahim Yar Khan',
    'Jhang',
    'Dera Ghazi Khan',
    'Hyderabad',
    'Sukkur',
    'Larkana',
    'Nawabshah',
    'Mirpur Khas',
    'Peshawar',
    'Abbottabad',
    'Mardan',
    'Swat',
    'Dera Ismail Khan',
    'Kohat',
    'Quetta',
    'Gwadar',
    'Turbat',
    'Khuzdar',
    'Gilgit',
    'Skardu',
    'Muzaffarabad',
    'Mirpur',
  ];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email/Password Sign Up
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if city is selected
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your city")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;

    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      city: _selectedCity,
    );

    setState(() => _isLoading = false);

    if (result == null || result["error"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?["error"] ?? "Sign up failed")),
      );
      return;
    }

    final uid = result["uid"];
    final userRole = result["role"] ?? role;
    final userStatus = result["status"] ?? "Active";

    if (userStatus == "Rejected") {
      _showRejectedDialog(userRole);
      return;
    }

    if (userRole.toLowerCase() == 'doctor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorQualificationScreen(
            doctorId: uid,
            name: name,
            email: email,
            password: '',
          ),
        ),
      );
    } else {
      _navigateBasedOnRole(userRole);
    }
  }

  // Google Auth
  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();

      if (result["success"] == true) {
        final user = result["user"] as UserModel;
        final needsRoleSelection = result["needsRoleSelection"] ?? false;
        final needsQualification = result["needsQualification"] ?? false;
        final needsApproval = result["needsApproval"] ?? false;
        final isRejected = result["isRejected"] ?? false;
        final canProceed = result["canProceed"] ?? false;

        if (isRejected) {
          _showRejectedDialog(user.role);
          return;
        }

        if (needsRoleSelection) {
          // ✅ Store user and show city selection first
          setState(() {
            _pendingGoogleUser = user;
            _needsCityForGoogle = true;
          });
          _showCitySelectionForGoogle();
          return;
        }

        if (user.role.toLowerCase() == 'doctor') {
          if (needsQualification) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorQualificationScreen(
                  doctorId: user.uid,
                  name: user.name,
                  email: user.email,
                  password: '',
                ),
              ),
            );
          } else if (needsApproval) {
            _showPendingApprovalDialog();
          } else if (canProceed) {
            _navigateBasedOnRole(user.role);
          } else {
            _navigateBasedOnRole(user.role);
          }
        } else {
          _navigateBasedOnRole(user.role);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Application Under Review"),
        content: const Text("Your doctor account is pending admin approval. You will receive an email once approved."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog(String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Account Rejected"),
        content: Text(
            role.toLowerCase() == 'doctor'
                ? "Your doctor application has been rejected. Please contact admin for more information."
                : "Your $role account has been rejected. Please contact admin for more information."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _navigateBasedOnRole(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        Navigator.pushReplacementNamed(context, AppConstants.patientDashboardRoute);
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
        Navigator.pushReplacementNamed(context, AppConstants.signinRoute);
    }
  }

  void _showRoleSelectionDialog(UserModel user) {
    String selectedRole = 'Patient';
    String? selectedCity;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white, // ✅ ADD THIS - makes dialog white
            title: const Text("Complete Your Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Please select your role and city to continue:"),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  items: ['Patient', 'Doctor', 'CHW', 'Admin'].map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    hintText: 'Select your city',
                  ),
                  items: _pakistaniCities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedCity = newValue;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _authService.signOut();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCity == null || selectedCity!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select your city")),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  setState(() => _isLoading = true);

                  final result = await _authService.completeGoogleSignUp(
                    uid: user.uid,
                    name: user.name,
                    email: user.email,
                    role: selectedRole,
                    city: selectedCity,
                  );

                  setState(() => _isLoading = false);

                  if (result["success"] == true) {
                    final completedUser = result["user"] as UserModel;
                    final needsQualification = result["needsQualification"] ?? false;

                    if (selectedRole == 'Doctor' && needsQualification) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorQualificationScreen(
                            doctorId: completedUser.uid,
                            name: completedUser.name,
                            email: completedUser.email,
                            password: '',
                          ),
                        ),
                      );
                    } else {
                      _navigateBasedOnRole(selectedRole);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result["error"] ?? "Failed to complete sign up")),
                    );
                  }
                },
                child: const Text("Continue"),
              ),
            ],
          );
        },
      ),
    );
  }


  void _showCitySelectionForGoogle() {
    String selectedRole = _selectedRole; // Use current selected role from form
    String? selectedCity;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.person_add, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Complete Your Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Please select your role and city to continue:"),
                const SizedBox(height: 16),
                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Patient', 'Doctor', 'CHW', 'Admin'].map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // City Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    hintText: 'Select your city',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _pakistaniCities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      selectedCity = newValue;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _authService.signOut();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCity == null || selectedCity!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select your city")),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  final result = await _authService.completeGoogleSignUp(
                    uid: _pendingGoogleUser!.uid,
                    name: _pendingGoogleUser!.name,
                    email: _pendingGoogleUser!.email,
                    role: selectedRole,
                    city: selectedCity,
                  );

                  setState(() => _isLoading = false);

                  if (result["success"] == true) {
                    final completedUser = result["user"] as UserModel;
                    final needsQualification = result["needsQualification"] ?? false;

                    if (selectedRole == 'Doctor' && needsQualification) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorQualificationScreen(
                            doctorId: completedUser.uid,
                            name: completedUser.name,
                            email: completedUser.email,
                            password: '',
                          ),
                        ),
                      );
                    } else {
                      _navigateBasedOnRole(selectedRole);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result["error"] ?? "Failed to complete sign up")),
                    );
                  }

                  setState(() {
                    _pendingGoogleUser = null;
                    _needsCityForGoogle = false;
                  });
                },
                child: const Text("Continue"),
              ),
            ],
          );
        },
      ),
    );
  }
  // Validators
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Enter your full name";
    final trimmed = value.trim();
    if (!trimmed.contains(' ')) return "Enter both first & last name";
    if (trimmed.length < 5 || trimmed.length > 40) return "Must be 5–40 characters";
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(trimmed)) return "Only letters & spaces allowed";
    final lower = trimmed.toLowerCase();
    const reserved = ['admin','root','superuser','patient','user','chw','doctor','tbcare','tbcareai'];
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
      'incorrect', 'error', 'false', 'true', 'hello',
      'hey', 'welcome', 'mail', 'email', 'contact', 'support',
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

    for (var blacklistedWord in blacklistedUsernames) {
      if (username.contains(blacklistedWord)) {
        return "Email contains restricted words";
      }
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
      'password','pass','qwerty','123456','111111','abc123','letmein','welcome',
      'iloveyou','test','login','admin','user','root','tb','tbcare','tbcarea',
      'careai','doctor','dr','tbcareai','tbcare-ai','chw','patient','nurse',
      'health','medical','clinic','hospital','system','2020','2021','2022',
      '2023','2024','2025','1234','4321','0000','9999',
    ];
    for (var word in blacklist) {
      if (pass.contains(word)) {
        return 'Password too weak (contains "$word")';
      }
    }
    return null;
  }

  // UI BUILD METHODS
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
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: primaryColor,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/splash_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(extraLargePadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo light.png',
                          height: 120,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_hospital_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: extraLargePadding),
                      const Text(
                        "Join TB-Care AI Today",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      Text(
                        "Create your account for advanced healthcare services",
                        style: TextStyle(
                          fontSize: titleSize,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(extraLargePadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: smallPadding),
                    Text(
                      "Create your account to get started.",
                      style: TextStyle(
                        fontSize: bodySize,
                        color: secondaryColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: extraLargePadding),
                    _buildSignUpForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(150),
              const SizedBox(height: extraLargePadding),
              const Text(
                "Create Account!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: smallPadding),
              Text(
                "Sign up to start your journey",
                style: TextStyle(
                  fontSize: bodySize,
                  color: secondaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: extraLargePadding),
              _buildSignUpForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameField(),
          const SizedBox(height: defaultPadding),
          _buildEmailField(),
          const SizedBox(height: defaultPadding),
          _buildPasswordField(),
          const SizedBox(height: defaultPadding),
          _buildRoleSelector(),
          const SizedBox(height: defaultPadding),
          _buildCitySelector(),
          const SizedBox(height: largePadding),
          _buildSignUpButton(),
          const SizedBox(height: largePadding),
          _buildOrDivider(),
          const SizedBox(height: largePadding),
          _buildGoogleSignInButton(),
          const SizedBox(height: largePadding),
          _buildSignInText(),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/images/tbcare logo 2.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.local_hospital_rounded,
          size: 60,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      style: const TextStyle(fontSize: bodySize),
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person_outline, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: _validateName,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: bodySize),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: bodySize),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: secondaryColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildRoleSelector() {
    final List<String> roles = ['Patient', 'Doctor', 'CHW', 'Admin'];

    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.work_outline, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: roles.map((String role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedRole = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }

  Widget _buildCitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'City',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            hintText: 'Select your city',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _pakistaniCities.map((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCity = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your city';
            }
            return null;
          },
        ),
      ],
    );
  }
  Widget _buildSignUpButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: secondaryColor.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: secondaryColor.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: secondaryColor.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        icon: _isGoogleLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: primaryColor,
          ),
        )
            : Image.asset(
          'assets/images/google.png',
          height: 24,
          width: 24,
          errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 24),
        ),
        label: _isGoogleLoading
            ? const Text(
          'Signing in...',
          style: TextStyle(
            color: secondaryColor,
            fontSize: bodySize,
            fontWeight: FontWeight.w600,
          ),
        )
            : const Text(
          'Continue with Google',
          style: TextStyle(
            color: secondaryColor,
            fontSize: bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: secondaryColor.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
      ),
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: secondaryColor.withOpacity(0.7),
            fontSize: bodySize,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.signinRoute),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: bodySize,
            ),
          ),
        ),
      ],
    );
  }
}