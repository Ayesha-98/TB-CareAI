import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tb_project/auth/models/signup_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ✅ NEW: Get current city from device location
  Future<String?> _getCurrentCity() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Convert lat/lng to city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        // Try to get city, then subAdministrativeArea, then administrativeArea
        String city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            "Unknown";
        print('✅ Detected city: $city');
        return city;
      }
      return null;
    } catch (e) {
      print('❌ Failed to get location: $e');
      return null;
    }
  }

  /// ✅ ADD THIS - Log user signup
  Future<void> _logUserSignup(String userId, String email, String role) async {
    try {
      await _db.collection('signup_logs').add({
        'userId': userId,
        'email': email,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
        'signupDate': DateTime.now().toIso8601String().split('T')[0],
      });
      print('✅ Signup logged for $email ($role)');
    } catch (e) {
      print('❌ Failed to log signup: $e');
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

  /// Sign up user with validation
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String status = "Active",
    bool flagged = false,
    String? detectedCity,
  }) async {
    try {
      // Validation before hitting Firebase
      if (name.trim().isEmpty) return "Name is required.";
      if (!_isValidEmail(email)) return "Enter a valid email.";
      if (!_isValidPassword(password, name)) {
        return "Password must be at least 8 characters, "
            "include an uppercase letter, number, special character, "
            "and not contain your name/email.";
      }

      // Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.sendEmailVerification();
      final uid = userCredential.user!.uid;

      // ✅ Get current city
      String? city = await _getCurrentCity();

      // Create UserModel
      UserModel user = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        verified: false,
        status: status,
        flagged: flagged,
      );

      // Save to Firestore with city
      await _db.collection('users').doc(uid).set({
        ...user.toMap(),
        'city': city ?? 'Unknown',  // ✅ Add detected city
        'locationDetectedAt': FieldValue.serverTimestamp(),
      });

      // Log signup
      await _logUserSignup(uid, email, role);

      // ✅ Add admin audit log for registration
      await _addAdminAuditLog(
        action: 'USER_REGISTERED',
        actor: {
          'id': uid,
          'name': name,
          'email': email,
          'role': role,
        },
        registrar: {
          'id': uid,
          'name': name,
          'role': role,
        },
        details: 'New $role registered via Email/Password. Email verification sent. City: ${city ?? "Unknown"}',
      );

      // CHW special collection
      if (role == "CHW") {
        await _db.collection('chws').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'city': city ?? 'Unknown',  // ✅ Add city to CHW collection
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unknown error: $e';
    }
  }

  /// Email regex
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return regex.hasMatch(email);
  }

  /// Strong password validation
  bool _isValidPassword(String password, String nameOrEmail) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    final lower = password.toLowerCase();
    if (lower.contains(nameOrEmail.toLowerCase())) return false;

    return true;
  }

  /// Google Sign-In method
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
        // ✅ Get current city for new user
        String? city = await _getCurrentCity();

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
          "city": city ?? 'Unknown',  // ✅ Add detected city
          "locationDetectedAt": FieldValue.serverTimestamp(),
        });

        // Log signup
        await _logUserSignup(user.uid, user.email ?? '', 'Patient');

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
          details: 'New Patient registered via Google Sign-In. City: ${city ?? "Unknown"}',
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
            flagged: false,
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

  /// Sign-Out method
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