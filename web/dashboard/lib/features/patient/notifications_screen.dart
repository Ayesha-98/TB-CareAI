import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notification_model.dart';
import 'package:tbcare_main/core/app_constants.dart';

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
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All notifications marked as read")),
                );
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
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    "When you receive updates,\nthey will appear here",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await _notificationService.deleteNotification(notification.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification deleted")),
                    );
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: notification.isRead
                      ? Colors.white
                      : primaryColor.withOpacity(0.1),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(notification.type),
                      child: Icon(_getNotificationIcon(notification.type),
                          color: Colors.white, size: 20),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        if (!notification.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      if (!notification.isRead) {
                        await _notificationService.markAsRead(notification.id);
                        if (mounted) {
                          setState(() {});
                        }
                      }
                      // Optional: Navigate to relevant screen based on notification type
                      _handleNotificationTap(notification);
                    },
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
    // You can add navigation logic here based on notification type
    // For example:
    // if (notification.type == 'diagnosis') {
    //   Navigator.pushNamed(context, '/screenings');
    // } else if (notification.type == 'ai_result') {
    //   Navigator.pushNamed(context, '/screenings');
    // }

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tapped: ${notification.title}")),
    );
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