// lib/features/chw/widgets/slide_arrow_drawer.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tb_project/core/app_constants.dart';

import 'notification_drawer.dart';

class SlideArrowDrawer extends StatefulWidget {
  final Widget child;

  const SlideArrowDrawer({Key? key, required this.child}) : super(key: key);

  @override
  State<SlideArrowDrawer> createState() => _SlideArrowDrawerState();
}

class _SlideArrowDrawerState extends State<SlideArrowDrawer> with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  bool _hasUnreadNotifications = false;
  int _unreadCount = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // For draggable arrow
  Offset _arrowPosition = Offset(20, 200); // Default position
  bool _isDragging = false;

  // For 1-hour timer
  DateTime? _notificationAppearedTime;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _checkForNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _checkForNotifications() {
    // Listen for new notifications
    FirebaseFirestore.instance
        .collection('broadcast_notifications')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final latestNotification = snapshot.docs.first;
        final sentAt = (latestNotification.data()['sentAt'] as Timestamp?)?.toDate();

        // Check if this is a new notification (within last hour)
        if (sentAt != null) {
          final now = DateTime.now();
          final difference = now.difference(sentAt);

          // Only show if notification is less than 1 hour old
          if (difference.inHours < 1) {
            setState(() {
              _hasUnreadNotifications = true;
              _notificationAppearedTime = now;
            });
            _startHideTimer();
          } else {
            setState(() {
              _hasUnreadNotifications = false;
            });
          }
        }
      }
    });

    // Also listen for unread count
    FirebaseFirestore.instance
        .collection('broadcast_notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadCount = snapshot.docs.length;
      });
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(hours: 1), () {
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = false;
        });
      }
    });
  }

  void _toggleDrawer() {
    // Mark notifications as read when opening drawer
    _markNotificationsAsRead();

    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('broadcast_notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();

      // Hide arrow after marking as read
      setState(() {
        _hasUnreadNotifications = false;
      });
      _hideTimer?.cancel();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        _animationController.reverse();
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,

        // Draggable notification arrow (only shows if there are unread notifications)
        if (_hasUnreadNotifications)
          Positioned(
            left: _arrowPosition.dx,
            top: _arrowPosition.dy,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _arrowPosition = Offset(
                    _arrowPosition.dx + details.delta.dx,
                    _arrowPosition.dy + details.delta.dy,
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              onTap: _toggleDrawer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, // CHANGED: from 48 to 36
                height: 36, // CHANGED: from 48 to 36
                decoration: BoxDecoration(
                  color: _isDragging
                      ? primaryColor.withOpacity(0.8)
                      : primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        _isDrawerOpen
                            ? Icons.close
                            : Icons.notifications,
                        color: Colors.white,
                        size: 18, // CHANGED: from 24 to 18
                      ),
                    ),
                    // Unread count badge
                    if (_unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2), // CHANGED: from 4 to 2
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5), // CHANGED: from 2 to 1.5
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16, // CHANGED: from 20 to 16
                            minHeight: 16, // CHANGED: from 20 to 16
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8, // CHANGED: from 10 to 8
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // Drawer overlay when open
        if (_isDrawerOpen)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  width: 320,
                  color: Colors.transparent,
                  child: _buildDrawerContent(),
                ),
              ),
            ),
          ),

        // Backdrop when drawer is open
        if (_isDrawerOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerContent() {
    return NotificationDrawer(onClose: _closeDrawer); // CHANGED: Use the widget directly
  }

  String _getAudienceLabel(String audience) {
    switch (audience) {
      case 'patients': return 'Patients';
      case 'chws': return 'CHWs';
      case 'doctors': return 'Doctors';
      case 'admins': return 'Admins';
      default: return 'All';
    }
  }
}