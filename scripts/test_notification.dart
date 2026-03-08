import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../lib/notifications/notifications_service.dart';

/// Test screen to verify notification functionality
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  String _status = 'Initializing...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      _addLog('Initializing notification service...');
      await NotificationsService.initialize();
      _addLog('✅ Notification service initialized');

      _addLog('Getting FCM token...');
      final token = await NotificationsService.getFcmToken();
      setState(() {
        _fcmToken = token;
        _status = token != null ? 'Ready' : 'No token';
      });
      _addLog('✅ FCM Token: ${token?.substring(0, 20)}...');

      // Send token to backend
      _addLog('Sending token to backend...');
      final sent = await NotificationsService.sendFcmTokenToBackend();
      _addLog(sent ? '✅ Token sent to backend' : '❌ Failed to send token');

      setState(() {
        _status = 'Ready';
      });
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      _addLog('Showing test local notification...');
      await NotificationsService.showLocalNotification(
        title: 'Test Notification',
        body: 'This is a test notification from Leventsale app',
        payload: '{"type": "test", "timestamp": "${DateTime.now()}"}',
      );
      _addLog('✅ Local notification shown');
    } catch (e) {
      _addLog('❌ Error showing notification: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      _addLog('Fetching notifications from backend...');
      final notifications = await NotificationsService.fetchNotifications();
      _addLog('✅ Fetched ${notifications.length} notifications');

      for (var notif in notifications.take(3)) {
        _addLog('  - ${notif.title}');
      }
    } catch (e) {
      _addLog('❌ Error fetching notifications: $e');
    }
  }

  Future<void> _getUnreadCount() async {
    try {
      _addLog('Getting unread count...');
      final count = await NotificationsService.fetchUnreadCount();
      _addLog('✅ Unread notifications: $count');
    } catch (e) {
      _addLog('❌ Error getting unread count: $e');
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      // In a real app, you'd use Clipboard.setData
      _addLog('Token copied to clipboard (simulated)');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token copied!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: const Color(0xFF1DAF52),
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _status == 'Ready' ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _status == 'Ready' ? Colors.green : Colors.orange,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _status == 'Ready' ? Icons.check_circle : Icons.info,
                      color: _status == 'Ready' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_fcmToken != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'FCM Token:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fcmToken!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: _copyToken,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Platform: ${Platform.isAndroid
                      ? 'Android'
                      : Platform.isIOS
                      ? 'iOS'
                      : 'Other'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // Test Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _testLocalNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Local Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DAF52),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchNotifications,
                    icon: const Icon(Icons.download),
                    label: const Text('Fetch Notifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getUnreadCount,
                    icon: const Icon(Icons.badge),
                    label: const Text('Get Unread Count'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _initializeNotifications,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reinitialize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logs:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
