// lib/features/chw/widgets/notification_drawer.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tb_project/core/app_constants.dart';

class NotificationDrawer extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationDrawer({Key? key, required this.onClose}) : super(key: key);

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDrawer() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
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

    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: _closeDrawer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('broadcast_notifications')
                    .orderBy('sentAt', descending: true)
                    .limit(30)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text('Error loading notifications'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final message = data['message'] ?? '';
                      final audience = data['audience'] ?? 'all';
                      final sentAt = data['sentAt'] as Timestamp?;

                      // Get audience details - FIXED to match your data
                      String audienceLabel;
                      Color audienceColor;
                      IconData audienceIcon;

                      // Your data uses "chw" (singular) not "chws" (plural)
                      if (audience == 'chw') {
                        audienceLabel = 'CHWs';
                        audienceColor = Colors.green;
                        audienceIcon = Icons.medical_services_outlined;
                      } else {
                        switch (audience) {
                          case 'patients':
                            audienceLabel = 'Patients';
                            audienceColor = Colors.blue;
                            audienceIcon = Icons.person_outline;
                            break;
                          case 'doctors':
                            audienceLabel = 'Doctors';
                            audienceColor = Colors.purple;
                            audienceIcon = Icons.local_hospital_outlined;
                            break;
                          case 'admins':
                            audienceLabel = 'Admins';
                            audienceColor = Colors.orange;
                            audienceIcon = Icons.admin_panel_settings_outlined;
                            break;
                          default:
                            audienceLabel = 'All';
                            audienceColor = primaryColor;
                            audienceIcon = Icons.group_outlined;
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: audienceColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                audienceIcon,
                                color: audienceColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Message
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Footer with audience and time
                                  Row(
                                    children: [
                                      // Audience tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: audienceColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          audienceLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: audienceColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Time
                                      Text(
                                        _formatTimestamp(sentAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Broadcast messages from admin',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}