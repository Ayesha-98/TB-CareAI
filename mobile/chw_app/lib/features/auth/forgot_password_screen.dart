import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/core/app_constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      setState(() {
        _message = '✅ Reset email sent. Check your inbox.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = '❌ ${e.message}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: secondaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 80, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  "Enter your registered email\nto receive a reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: secondaryColor.withOpacity(0.8)),
                ),
                const SizedBox(height: 30),
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: secondaryColor),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: secondaryColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: secondaryColor.withOpacity(0.05),
                      prefixIcon: Icon(Icons.email, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter email';
                      if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) {
                        _resetPassword();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      "Send Reset Email",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.startsWith("✅") ? Colors.green : Colors.red,
                      fontSize: 15,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
