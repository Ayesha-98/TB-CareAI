// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification service
  Future<void> initialize() async {
    print('🚀 Initializing Notification Service...');

    // Request permissions
    await _requestPermissions();

    // Get and save FCM token
    await _getToken();

    // Setup message handlers
    _setupMessageHandlers();

    print('✅ Notification Service Initialized');
  }

  // Request permissions for notifications
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
      } else {
        print('❌ User declined notification permissions');
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  // Get and save FCM token
  Future<void> _getToken() async {
    try {
      // Get token
      String? token = await _fcm.getToken();

      if (token != null) {
        print('📱 FCM Token obtained: ${token.substring(0, 20)}...');
        await _saveTokenToFirestore(token);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Save token to Firestore - CRITICAL FIX
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        final String userId = user.uid;

        print('💾 Saving token for user: $userId');
        print('📱 Full token: $token');

        // Get user role from Firestore first
        final userDoc = await _firestore.collection('users').doc(userId).get();
        String userRole = 'unknown';

        if (userDoc.exists) {
          userRole = userDoc.data()?['role'] ?? 'unknown';
          print('📋 User role from Firestore: $userRole');
        }

        // 1. Save to users collection (ALWAYS do this)
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'role': userRole, // Keep existing role
        }, SetOptions(merge: true));
        print('✅ Token saved to users collection');

        // 2. Save to role-specific collection based on role
        if (userRole == 'CHW') {
          await _firestore.collection('chws').doc(userId).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Token saved to chws collection');
        } else if (userRole == 'Doctor') {
          await _firestore.collection('doctors').doc(userId).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Token saved to doctors collection');
        }

        // 3. VERIFY the token was saved
        final verifyUser = await _firestore.collection('users').doc(userId).get();
        if (verifyUser.exists) {
          final savedToken = verifyUser.data()?['fcmToken'];
          print('🔍 VERIFICATION - Token in users collection: ${savedToken != null ? '✅ Present' : '❌ Missing'}');

          if (savedToken == token) {
            print('✅ Token verified successfully!');
          } else {
            print('⚠️ Token mismatch! Saved: $savedToken, Original: $token');
          }
        }

      } else {
        print('❌ No user logged in, cannot save token');
      }
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 FOREGROUND message received: ${message.notification?.title}');
      print('📨 Message data: ${message.data}');

      if (message.notification != null) {
        _showInAppNotification(message);
      }
    });

    // Handle when app is opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 APP OPENED from background: ${message.notification?.title}');
      _handleMessage(message);
    });

    // Handle when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📨 APP OPENED from terminated: ${message.notification?.title}');
        _handleMessage(message);
      }
    });
  }

  // Handle message navigation
  void _handleMessage(RemoteMessage message) {
    print('📨 Handling message: ${message.notification?.title}');

    if (message.data['type'] == 'broadcast') {
      print('📢 Broadcast message: ${message.notification?.body}');
      // You can add navigation logic here
    }
  }

  // Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    print('🔔 Should show notification: ${message.notification?.title}');
    // You can show a dialog or snackbar here
  }

  // Call after login
  Future<void> onUserLogin() async {
    print('👤 User logged in - getting token...');
    await _getToken();
  }

  // Call on logout
  Future<void> onUserLogout() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Remove token from Firestore on logout
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });

        // Also remove from role-specific collection
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          if (role == 'CHW') {
            await _firestore.collection('chws').doc(user.uid).update({
              'fcmToken': FieldValue.delete(),
            });
          } else if (role == 'Doctor') {
            await _firestore.collection('doctors').doc(user.uid).update({
              'fcmToken': FieldValue.delete(),
            });
          }
        }

        print('✅ Token removed from Firestore');
      }

      // Delete token from device
      await _fcm.deleteToken();
      print('✅ FCM token deleted from device');

    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // Manual test method
  Future<void> testToken() async {
    String? token = await _fcm.getToken();
    print('📱 Current token: $token');
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }
}

// Background handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 BACKGROUND message: ${message.notification?.title}');
  print('📨 Background data: ${message.data}');
}