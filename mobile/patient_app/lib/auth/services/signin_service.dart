import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tb_project/auth/models/signin_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ✅ ADD THIS FUNCTION - Log user login
  Future<void> _logUserLogin(String userId, String email, String role, String authProvider) async {
    try {
      await _db.collection('login_logs').add({
        'userId': userId,
        'email': email,
        'role': role,
        'authProvider': authProvider,
        'timestamp': FieldValue.serverTimestamp(),
        'loginDate': DateTime.now().toIso8601String().split('T')[0],
      });
      print('✅ Login logged for $email ($role)');
    } catch (e) {
      print('❌ Failed to log login: $e');
    }
  }

  /// ✅ NEW: Add Admin Audit Log
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

  /// Email/Password Sign-In
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;

      if (user == null) {
        return {"success": false, "error": "Authentication failed"};
      }

      // Check if email is verified
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        return {
          "success": false,
          "error": "Please verify your email address to continue",
          "needsVerification": true,
          "email": email
        };
      }

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return {"success": false, "error": "User profile not found"};
      }

      final userData = doc.data()!;

      // Check if account is deactivated
      if (userData['status'] == 'Deactivated') {
        return {"success": false, "error": "Your account has been deactivated by administrator. Please contact admin to restore access."};
      }

      final userRole = userData['role'] ?? 'Patient';

      // Log login
      await _logUserLogin(user.uid, user.email ?? email, userRole, 'email');

      // ✅ Add admin audit log for login
      await _addAdminAuditLog(
        action: 'LOGIN',
        actor: {
          'id': user.uid,
          'name': userData['name'] ?? user.email ?? 'Unknown',
          'email': user.email ?? email,
          'role': userRole,
        },
        details: 'Patient logged in successfully via email',
      );

      return {
        "success": true,
        "user": UserModel.fromMap(userData, user.uid)
      };
    } on FirebaseAuthException catch (e) {
      return {"success": false, "error": e.message ?? "Authentication failed"};
    } catch (e) {
      return {"success": false, "error": "Login failed: $e"};
    }
  }

  /// Simplified Google Auth for Patient
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {"success": false, "error": "Sign-in cancelled"};

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return {"success": false, "error": "Authentication failed"};

      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final isNewUser = !doc.exists;

      if (isNewUser) {
        // NEW USER: Auto-create as Patient with Active status
        await docRef.set({
          "uid": user.uid,
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "role": "Patient",
          "verified": true,
          "status": "Active",
          "flagged": false,
          "createdAt": FieldValue.serverTimestamp(),
          "authProvider": "google",
        });

        // Log login for new user
        await _logUserLogin(user.uid, user.email ?? '', 'Patient', 'google');

        // ✅ Add admin audit log for registration
        await _addAdminAuditLog(
          action: 'USER_REGISTERED',
          actor: {
            'id': user.uid,
            'name': user.displayName ?? user.email ?? 'Unknown',
            'email': user.email ?? '',
            'role': 'Patient',
          },
          registrar: {
            'id': user.uid,
            'name': user.displayName ?? user.email ?? 'Unknown',
            'role': 'Patient',
          },
          details: 'New Patient registered via Google Sign-In',
        );

        return {
          "success": true,
          "user": UserModel(
              uid: user.uid,
              name: user.displayName ?? "",
              email: user.email ?? "",
              role: "Patient",
              verified: true,
              status: "Active",
              flagged: false
          ),
          "isNewUser": true,
        };
      } else {
        // EXISTING USER: Simple status check
        final userData = doc.data()!;
        final userRole = userData['role'];
        final userStatus = userData['status'];

        if (userData['status'] == 'Deactivated') {
          await _auth.signOut();
          return {"success": false, "error": "Your account has been deactivated by administrator. Please contact admin to restore access."};
        }

        if (userRole != "Patient") {
          await _auth.signOut();
          return {"success": false, "error": "This account is not registered as a Patient. Please use the appropriate app."};
        }

        if (userStatus != "Active") {
          await _auth.signOut();
          return {"success": false, "error": "Your account is not active. Please contact administrator."};
        }

        // Log login for existing user
        await _logUserLogin(user.uid, user.email ?? '', userRole, 'google');

        // ✅ Add admin audit log for login
        await _addAdminAuditLog(
          action: 'LOGIN',
          actor: {
            'id': user.uid,
            'name': userData['name'] ?? user.email ?? 'Unknown',
            'email': user.email ?? '',
            'role': userRole,
          },
          details: 'Patient logged in successfully via Google',
        );

        return {
          "success": true,
          "user": UserModel.fromMap(userData, user.uid),
          "isNewUser": false,
        };
      }
    } on FirebaseAuthException catch (e) {
      return {"success": false, "error": e.message ?? "Google sign-in failed"};
    } catch (e) {
      return {"success": false, "error": "Google sign-in failed: $e"};
    }
  }

  /// Sign-Out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Get user data for audit log
      try {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        await _addAdminAuditLog(
          action: 'LOGOUT',
          actor: {
            'id': user.uid,
            'name': userData?['name'] ?? user.displayName ?? user.email ?? 'Unknown',
            'email': user.email ?? '',
            'role': userData?['role'] ?? 'Patient',
          },
          details: 'Patient logged out',
        );
      } catch (e) {
        print('Failed to log logout: $e');
      }
    }
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}