import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==================== NOTIFICATION MODEL ====================
class NotificationModel {
  String id;
  String title;
  String body;
  String type; // 'diagnosis', 'ai_result', 'status', 'recommendation', 'general'
  DateTime timestamp;
  bool isRead;
  String? screeningId; // Reference to which screening this notification belongs to

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.screeningId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'screeningId': screeningId,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      screeningId: map['screeningId'],
    );
  }
}

// ==================== NOTIFICATION SERVICE ====================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================= INITIALIZATION METHODS =================

  /// Initialize notification service
  Future<void> initialize() async {
    print('🚀 Initializing Notification Service for Patient...');

    // Request permissions
    await _requestPermissions();

    // Get and save FCM token
    await _getToken();

    // Setup message handlers
    _setupMessageHandlers();

    print('✅ Notification Service Initialized for Patient');
  }

  /// Request permissions for notifications
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

  /// Get and save FCM token
  Future<void> _getToken() async {
    try {
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

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        final String userId = user.uid;

        print('💾 Saving token for user: $userId');

        // Get user role from Firestore first
        final userDoc = await _firestore.collection('users').doc(userId).get();
        String userRole = 'unknown';

        if (userDoc.exists) {
          userRole = userDoc.data()?['role'] ?? 'unknown';
          print('📋 User role from Firestore: $userRole');
        }

        // 1. Save to users collection
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'role': userRole,
        }, SetOptions(merge: true));
        print('✅ Token saved to users collection');

        // 2. Save to role-specific collection
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
        } else if (userRole == 'Patient') {
          await _firestore.collection('patients').doc(userId).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Token saved to patients collection');
        }
      } else {
        print('❌ No user logged in, cannot save token');
      }
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // ================= FCM MESSAGE HANDLERS =================

  /// Setup message handlers
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

  /// Handle message navigation
  void _handleMessage(RemoteMessage message) {
    print('📨 Handling message: ${message.notification?.title}');

    if (message.data['type'] == 'broadcast') {
      print('📢 Broadcast message: ${message.notification?.body}');
    }
  }

  /// Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    print('🔔 Should show notification: ${message.notification?.title}');
  }

  // ================= NOTIFICATION HISTORY METHODS =================

  /// 💾 Save a notification to Firestore
  Future<void> saveNotification({
    required String title,
    required String body,
    required String type,
    String? screeningId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ No user logged in, cannot save notification');
        return;
      }

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        screeningId: screeningId,
      );

      await _firestore
          .collection('patients')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());

      print('✅ Notification saved: $title');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// 📥 Get all notifications for current patient
  Stream<List<NotificationModel>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ No user logged in, returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection('patients')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// 🔢 Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('patients')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ✅ Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('patients')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// ✅ Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('patients')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// 🗑️ Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('patients')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// 🗑️ Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('patients')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ All notifications deleted');
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
    }
  }

  // ================= USER SESSION METHODS =================

  /// Call after login
  Future<void> onUserLogin() async {
    print('👤 User logged in - getting token...');
    await _getToken();
  }

  /// Call on logout
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
          } else if (role == 'Patient') {
            await _firestore.collection('patients').doc(user.uid).update({
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

  /// Manual test method
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