import 'package:flutter/material.dart';
import 'package:tb_project/patient/notification_service.dart'; // Single file import
import 'package:tb_project/core/app_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All notifications marked as read")),
                );
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading notifications..."),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "When you receive updates,\nthey will appear here",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await _notificationService.deleteNotification(notification.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification deleted"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, // ✅ Solid white background
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        if (!notification.isRead) {
                          await _notificationService.markAsRead(notification.id);
                          if (mounted) {
                            setState(() {});
                          }
                        }
                        _handleNotificationTap(notification);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getNotificationColor(notification.type).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: _getNotificationColor(notification.type),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: TextStyle(
                                            fontWeight: notification.isRead
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(notification.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notification.body,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "NEW",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read already handled in onTap
    if (notification.type == 'diagnosis' || notification.type == 'ai_result') {
      Navigator.pushNamed(context, '/screening');
    } else if (notification.type == 'recommendation') {
      Navigator.pushNamed(context, '/profile');
    } else if (notification.type == 'status') {
      Navigator.pushNamed(context, '/screening');
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return "${diff.inDays}d ago";
    } else if (diff.inDays > 0) {
      return "${diff.inDays}d ago";
    } else if (diff.inHours > 0) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'diagnosis':
        return Icons.medical_services;
      case 'ai_result':
        return Icons.science;
      case 'status':
        return Icons.update;
      case 'recommendation':
        return Icons.recommend;
      case 'general':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'diagnosis':
        return Colors.purple;
      case 'ai_result':
        return Colors.blue;
      case 'status':
        return Colors.orange;
      case 'recommendation':
        return Colors.green;
      case 'general':
        return primaryColor;
      default:
        return primaryColor;
    }
  }
}