import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tbcare_main/features/auth/models/signup_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();  // Only for mobile


  /// ✅ Log user signup with location (NEW)
  Future<void> _logUserSignup(String userId, String email, String role, String? city) async {
    try {
      await _db.collection('signup_logs').add({
        'userId': userId,
        'email': email,
        'role': role,
        'city': city ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'signupDate': DateTime.now().toIso8601String().split('T')[0],
      });
      print('✅ Signup logged for $email ($role) from city: ${city ?? "Unknown"}');
    } catch (e) {
      print('❌ Failed to log signup: $e');
    }
  }

  /// ✅ Add Admin Audit Log
  Future<void> _addAdminAuditLog({
    required String action,
    required Map<String, dynamic> actor,
    Map<String, dynamic>? target,
    Map<String, dynamic>? registrar,
    String? details,
    Map<String, dynamic>? changes,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      await _db.collection('admin_audit_logs').add({
        'action': action,
        'actor': {
          'id': actor['id'],
          'name': actor['name'],
          'email': actor['email'],
          'role': actor['role'],
          'city': actor['city'] ?? 'Unknown',
        },
        'target': target != null ? {
          'id': target['id'],
          'name': target['name'],
          'email': target['email'],
          'role': target['role'],
        } : null,
        'registrar': registrar != null ? {
          'id': registrar['id'],
          'name': registrar['name'],
          'role': registrar['role'],
        } : null,
        'details': details ?? '',
        'changes': changes,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      print('✅ Admin audit log added: $action');
    } catch (e) {
      print('❌ Failed to add admin audit log: $e');
    }
  }

  /// Email/Password Sign up user with validation
  Future<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String status = "Active",
    bool flagged = false,
    String? city,
  }) async {
    try {
      // ✅ Validation: City is required
      if (city == null || city.isEmpty || city == 'Unknown') {
        return {"error": "Please select your city before signing up."};
      }

      // Validation before hitting Firebase
      if (name.trim().isEmpty) return {"error": "Name is required."};
      if (!_isValidEmail(email)) return {"error": "Enter a valid email."};
      if (!_isValidPassword(password, name)) {
        return {
          "error":
          "Password must be at least 8 characters, include an uppercase letter, number, special character, and not contain your name/email."
        };
      }

      // Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user!;
      await user.sendEmailVerification();

      final uid = user.uid;

      // Doctor gets Needs Qualification, others get Active
      String userStatus = role == "Doctor" ? "Needs Qualification" : "Active";
      bool verified = role == "Doctor" ? false : true;

      // Create UserModel
      UserModel userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        verified: verified,
        status: userStatus,
        flagged: flagged,
      );

      // Save to Firestore with city
      await _db.collection('users').doc(uid).set({
        ...userModel.toMap(),
        'city': city,
        'locationDetectedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User saved to users collection with city: $city');

      // ✅ Log signup to signup_logs collection
      await _logUserSignup(uid, email, role, city);
      print('✅ Signup logged to signup_logs collection');

      // Create CHW profile if needed
      if (role == "CHW") {
        await _db.collection('chws').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivity': null,
          'status': userStatus,
          'flagged': flagged,
          'city': city,
        });
        print('✅ CHW profile created with city: $city');
      }

      // Add admin audit log for registration
      await _addAdminAuditLog(
        action: 'USER_REGISTERED',
        actor: {
          'id': uid,
          'name': name,
          'email': email,
          'role': role,
          'city': city,
        },
        registrar: {
          'id': uid,
          'name': name,
          'role': role,
        },
        details: 'New $role registered via Email/Password. Email verification sent. City: $city',
      );
      print('✅ Admin audit log added');

      // Return success info
      return {
        "uid": uid,
        "role": role,
        "email": email,
        "name": name,
        "status": userStatus,
        "verified": verified,
        "success": true,
        "city": city,
      };
    } on FirebaseAuthException catch (e) {
      return {"error": e.message ?? "Authentication failed"};
    } on FirebaseException catch (e) {
      return {"error": e.message ?? "Firebase error occurred"};
    } catch (e) {
      return {"error": "Unknown error: $e"};
    }
  }

  /// Unified Google Auth (Sign-up & Sign-in) - FIXED FOR WEB
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        // Web flow: use Firebase popup auth
        final googleProvider = GoogleAuthProvider();
        userCred = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile flow: use GoogleSignIn package
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return {"success": false, "error": "Sign-in cancelled"};

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await _auth.signInWithCredential(credential);
      }

      final user = userCred.user;
      if (user == null) return {"success": false, "error": "Authentication failed"};

      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final isNewUser = !doc.exists;

      if (isNewUser) {
        // NEW USER: Return role selection flag
        return {
          "success": true,
          "user": UserModel(
              uid: user.uid,
              name: user.displayName ?? "",
              email: user.email ?? "",
              role: "",
              verified: false,
              status: "Active",
              flagged: false
          ),
          "isNewUser": true,
          "needsRoleSelection": true,
        };
      } else {
        // Existing user - Check status
        final userData = doc.data()!;
        final userRole = userData['role'];
        final userStatus = userData['status'];
        final isVerified = userData['verified'] ?? false;

        // Check if account is deactivated
        if (userData['status'] == 'Deactivated') {
          await _auth.signOut();
          return {"success": false, "error": "Your account has been deactivated by administrator. Please contact admin to restore access."};
        }

        // Handle ALL doctor statuses properly
        if (userRole == "Doctor") {
          if (userStatus == "Needs Qualification") {
            return {
              "success": true,
              "user": UserModel.fromMap(userData, user.uid),
              "isNewUser": false,
              "needsQualification": true,
            };
          } else if (userStatus == "Pending Approval") {
            return {
              "success": true,
              "user": UserModel.fromMap(userData, user.uid),
              "isNewUser": false,
              "needsApproval": true,
            };
          } else if (userStatus == "Rejected") {
            return {
              "success": true,
              "user": UserModel.fromMap(userData, user.uid),
              "isNewUser": false,
              "isRejected": true,
            };
          } else if (isVerified && userStatus == "Active") {
            return {
              "success": true,
              "user": UserModel.fromMap(userData, user.uid),
              "isNewUser": false,
              "canProceed": true,
            };
          }
        }

        // Default case for other roles or unknown statuses
        return {
          "success": true,
          "user": UserModel.fromMap(userData, user.uid),
          "isNewUser": false,
          "canProceed": true,
        };
      }
    } on FirebaseAuthException catch (e) {
      return {"success": false, "error": e.message ?? "Google sign-in failed"};
    } catch (e) {
      return {"success": false, "error": "Google sign-in failed: $e"};
    }
  }

  /// Complete Google Sign Up with role selection
  Future<Map<String, dynamic>> completeGoogleSignUp({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? city,
  }) async {
    try {
      // ✅ Validation: City is required
      if (city == null || city.isEmpty || city == 'Unknown') {
        return {"success": false, "error": "Please select your city before completing sign up."};
      }

      String userStatus = role == "Doctor" ? "Needs Qualification" : "Active";
      bool verified = role == "Doctor" ? false : true;

      // Save to users collection with city
      await _db.collection('users').doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "role": role,
        "verified": verified,
        "status": userStatus,
        "flagged": false,
        "createdAt": FieldValue.serverTimestamp(),
        "authProvider": "google",
        "city": city,
        "locationDetectedAt": FieldValue.serverTimestamp(),
      });
      print('✅ User saved to users collection with city: $city');

      // ✅ Log signup to signup_logs collection
      await _logUserSignup(uid, email, role, city);
      print('✅ Signup logged to signup_logs collection');

      // Create CHW profile if needed
      if (role == "CHW") {
        await _db.collection('chws').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActivity': null,
          'status': userStatus,
          'flagged': false,
          'city': city,
        });
        print('✅ CHW profile created with city: $city');
      }

      // Add admin audit log for registration
      await _addAdminAuditLog(
        action: 'USER_REGISTERED',
        actor: {
          'id': uid,
          'name': name,
          'email': email,
          'role': role,
          'city': city,
        },
        registrar: {
          'id': uid,
          'name': name,
          'role': role,
        },
        details: 'New $role registered via Google Sign-Up. City: $city',
      );
      print('✅ Admin audit log added');

      return {
        "success": true,
        "user": UserModel(
          uid: uid,
          name: name,
          email: email,
          role: role,
          verified: verified,
          status: userStatus,
          flagged: false,
        ),
        "needsQualification": role == "Doctor",
      };
    } catch (e) {
      return {"success": false, "error": "Failed to complete sign up: $e"};
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  // Email regex
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return regex.hasMatch(email);
  }

  // Strong password validation
  bool _isValidPassword(String password, String nameOrEmail) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    final lower = password.toLowerCase();
    if (lower.contains(nameOrEmail.toLowerCase())) return false;

    return true;
  }
}