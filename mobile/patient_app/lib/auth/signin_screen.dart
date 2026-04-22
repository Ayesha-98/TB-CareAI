import 'package:flutter/material.dart';
import 'package:tb_project/auth/services/signin_service.dart';
import 'package:tb_project/core/app_constants.dart';
import 'package:tb_project/auth/models/signin_model.dart';

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
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

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

  // ✅ UPDATED: Handle email login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final result = await _authService.signInWithEmail(email, password);

      if (result["success"] == true) {
        final user = result["user"] as UserModel;
        _navigateBasedOnRole(user.role);
      } else {
        // ✅ Check if user needs email verification
        if (result["needsVerification"] == true) {
          // Navigate to verification screen
          Navigator.pushReplacementNamed(
              context,
              '/verify',
              arguments: email // Pass email to verification screen
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["error"])),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 UPDATED: Simplified Google Auth for Patient
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();

      if (result["success"] == true) {
        final user = result["user"] as UserModel;
        final isNewUser = result["isNewUser"] ?? false;

        if (isNewUser) {
          // 🔥 NEW PATIENT USER: Show welcome message and go to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 Welcome! Your Patient account has been created.")),
          );
        }

        // 🔥 NAVIGATE: Direct to Patient dashboard
        _navigateBasedOnRole(user.role);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
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
                      const SizedBox(height: 40),
                      _buildWelcomeText(),
                      const SizedBox(height: 40),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 12),
                      _buildForgotPassword(),
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 24),
                      _buildOrDivider(),
                      const SizedBox(height: 24),
                      _buildGoogleSignInButton(),
                      const SizedBox(height: 32),
                      _buildSignUpText(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double screenHeight) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: screenHeight * 0.18,
            width: screenHeight * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withOpacity(0.1),
              border: Border.all(color: primaryColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
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
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your care journey',
          style: TextStyle(
            fontSize: 16,
            color: secondaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _styledField(
      controller: _emailController,
      hint: 'Enter your email',
      icon: Icons.email_outlined,
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
    return _styledField(
      controller: _passwordController,
      hint: 'Enter your password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffix: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 22,
          color: primaryColor,
        ),
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 8) return 'Password must be at least 8 characters';
        return null;
      },
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      width: double.infinity,
      height: 50,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: secondaryColor.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          suffixIcon: suffix,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.forgotPasswordRoute);
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
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

  Widget _buildGoogleSignInButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: Image.asset(
          'assets/images/google.png',
          height: 18,
          width: 18,
        ),
        label: Text(
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
        onPressed: _isLoading ? null : _handleGoogleLogin,
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
            fontSize: 15,
            color: secondaryColor.withOpacity(0.8),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppConstants.signupRoute),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}