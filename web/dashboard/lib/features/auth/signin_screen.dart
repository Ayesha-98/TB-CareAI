import 'package:flutter/material.dart';
import 'package:tbcare_main/features/auth/services/signin_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/auth/doctor_qualification_screen.dart';
import 'package:tbcare_main/features/auth/models/signin_model.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        Navigator.pushReplacementNamed(context, AppConstants.webLandingRoute);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await _authService.signInWithEmail(email, password);

    setState(() => _isLoading = false);

    if (result["success"] == true) {
      final user = result["user"] as UserModel;

      // ✅ Check for Pending Approval FIRST (before any other checks)
      if (result["needsApproval"] == true) {
        _showPendingApprovalDialog(user.role);
        return;
      }

      // Check for Rejected
      if (result["isRejected"] == true) {
        _showRejectedDialog();
        return;
      }

      // Check for Needs Qualification
      if (result["needsQualification"] == true) {
        if (user.role.toLowerCase() == 'doctor') {
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
        } else {
          _navigateBasedOnRole(user.role);
        }
        return;
      }

      // Normal login
      _navigateBasedOnRole(user.role);
    } else {
      // Handle errors
      final error = result["error"]?.toString().toLowerCase() ?? "";
      final needsVerification = result["needsVerification"] ?? false;

      if (needsVerification) {
        _showEmailVerificationDialog(email);
      } else if (error.contains("user-not-found") || error.contains("wrong-password") || error.contains("invalid-credential")) {
        // ✅ Show generic message for credential errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"] ?? "Login failed")),
        );
      }
    }
  }
// ✅ NEW: Dialog for Google-linked accounts
  void _showGoogleLinkedAccountDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Google Account Detected"),
        content: const Text("This email is registered with Google. Please sign in with Google instead."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: const Text("Sign in with Google"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();

      if (result["success"] == true) {
        final user = result["user"] as UserModel?;

        // Handle all status cases
        final needsQualification = result["needsQualification"] ?? false;
        final needsApproval = result["needsApproval"] ?? false;
        final isRejected = result["isRejected"] ?? false;
        final canProceed = result["canProceed"] ?? false;
        final needsRoleSelection = result["needsRoleSelection"] ?? false;
        final userRole = user?.role.toLowerCase() ?? '';

        // Check for role selection needed (for new Google users)
        if (needsRoleSelection && user != null) {
          _showRoleSelectionForGoogle(user);
          return;
        }

        // Check if user is CHW - they should go directly to dashboard
        if (userRole == 'chw') {
          Navigator.pushReplacementNamed(context, AppConstants.chwRoute);
          return;
        }

        if (needsQualification && user != null) {
          // Only DOCTOR needs qualification
          if (userRole == 'doctor') {
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
          } else {
            // Other roles shouldn't need qualification
            _navigateBasedOnRole(user.role);
          }
        } else if (needsApproval) {
          _showPendingApprovalDialog(user?.role ?? "User");
        } else if (isRejected) {
          _showRejectedDialog();
        } else if (canProceed && user != null) {
          _navigateBasedOnRole(user.role);
        } else if (user != null) {
          _navigateBasedOnRole(user.role);
        } else {
          Navigator.pushReplacementNamed(context, AppConstants.webLandingRoute);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["error"] ?? "Google login failed")),
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

  void _showRoleSelectionDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Account Type"),
        content: const Text("This email is registered with Google. Please sign in with Google to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: const Text("Sign in with Google"),
          ),
        ],
      ),
    );
  }

  void _showRoleSelectionForGoogle(UserModel user) {
    String selectedRole = 'Patient'; // Default

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Select Your Role"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Please select your role to continue with Google sign-in:"),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['Patient', 'Doctor', 'CHW', 'Admin'].map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedRole = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _authService.signOut(); // Sign out if cancelled
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Complete Google sign up with selected role
                  final result = await _authService.completeGoogleSignUp(
                    uid: user.uid,
                    name: user.name,
                    email: user.email,
                    role: selectedRole,
                  );

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

  void _showEmailVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Email Verification Required"),
        content: const Text("Please verify your email address to continue. A verification email has been sent."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showGoogleSignInSuggestion(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Google Account Detected"),
        content: const Text("This email is registered with Google. Please sign in with Google instead."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleGoogleLogin();
            },
            child: const Text("Sign in with Google"),
          ),
        ],
      ),
    );
  }

  void _showPendingApprovalDialog(String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Application Under Review"),
        content: Text(
            "Your $role account is pending admin approval. "
                "You will receive an email once approved."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Application Rejected"),
        content: const Text(
            "Your application has been rejected. "
                "Please contact admin for more information."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ---- KEEP AMAR'S UI BELOW (NO CHANGES TO VISUAL STRUCTURE) ----

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
                        "Welcome to TB-Care AI",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      Text(
                        "Advanced Screening & Patient Management",
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
                      "Sign In",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: smallPadding),
                    Text(
                      "Please enter your details to continue.",
                      style: TextStyle(
                        fontSize: bodySize,
                        color: secondaryColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: extraLargePadding),
                    _buildLoginForm(),
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
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: smallPadding),
              Text(
                "Sign in to continue",
                style: TextStyle(
                  fontSize: bodySize,
                  color: secondaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: extraLargePadding),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmailField(),
          const SizedBox(height: defaultPadding),
          _buildPasswordField(),
          const SizedBox(height: smallPadding),
          _buildForgotPassword(),
          const SizedBox(height: largePadding),
          _buildLoginButton(),
          const SizedBox(height: largePadding),
          _buildOrDivider(),
          const SizedBox(height: largePadding),
          _buildGoogleSignInButton(),
          const SizedBox(height: largePadding),
          _buildSignUpText(),
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter valid email';
        }
        return null;
      },
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.forgotPasswordRoute);
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
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
          'Sign In',
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

  Widget _buildSignUpText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: secondaryColor.withOpacity(0.7),
            fontSize: bodySize,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.signupRoute),
          child: const Text(
            'Sign Up',
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