import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/auth/auth_config.dart';
import '../firebase_options.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
      read: (json['read'] ?? json['isRead'] ?? false) == true,
    );
  }
}

class NotificationsService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        'default_channel',
        'General Notifications',
        description: 'Default channel for notifications',
        importance: Importance.high,
      );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        // If Firebase initialization fails, skip gracefully
        // This allows the app to run without Firebase configured
        print('Firebase initialization skipped: $e');
        return;
      }

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_defaultChannel);

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _requestPermission();

      FirebaseMessaging.onMessage.listen(showRemoteMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await sendFcmTokenToBackend(fcmToken: newToken);
        } catch (_) {}
      });

      // Send current token once on init
      try {
        final t = await FirebaseMessaging.instance.getToken();
        if (t != null && t.isNotEmpty) {
          await sendFcmTokenToBackend(fcmToken: t);
        }
      } catch (_) {}

      _initialized = true;
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {}
    // Android 13+ requires runtime notification permission
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  static Future<String?> getFcmToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final androidDetails = AndroidNotificationDetails(
      _defaultChannel.id,
      _defaultChannel.name,
      channelDescription: _defaultChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'إشعار';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = token.startsWith('Bearer')
            ? token
            : 'Bearer $token';
      }
    } catch (_) {}
    return headers;
  }

  static String get baseUrl => AuthConfig.baseUrl;

  static Future<List<NotificationItem>> fetchNotifications() async {
    final url = Uri.parse('$baseUrl/api/v1/notifications');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map(
              (e) =>
                  NotificationItem.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList();
      } else if (data is Map && data['content'] is List) {
        return (data['content'] as List)
            .map(
              (e) =>
                  NotificationItem.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList();
      } else {
        return <NotificationItem>[];
      }
    } else {
      throw Exception('Failed to fetch notifications (${res.statusCode})');
    }
  }

  static Future<int> fetchUnreadCount() async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/unread-count');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return (data['count'] ?? 0) is int
          ? data['count'] as int
          : int.tryParse('${data['count']}') ?? 0;
    }
    return 0;
  }

  static Future<bool> markAllRead() async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/read-all');
    final res = await http.put(url, headers: await _headers());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> markRead(String id) async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/$id/read');
    final res = await http.put(url, headers: await _headers());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> deleteAll() async {
    final url = Uri.parse('$baseUrl/api/v1/notifications');
    final res = await http.delete(url, headers: await _headers());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> deleteById(String id) async {
    final url = Uri.parse('$baseUrl/api/v1/notifications/$id');
    final res = await http.delete(url, headers: await _headers());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> sendFcmTokenToBackend({
    String? deviceId,
    String? fcmToken,
  }) async {
    final token = fcmToken ?? await getFcmToken();
    if (token == null || token.isEmpty) return false;
    final url = Uri.parse('$baseUrl/api/v1/notifications/token');
    final body = jsonEncode({
      'fcmToken': token,
      'deviceId':
          deviceId ??
          (Platform.isAndroid
              ? 'android'
              : Platform.isIOS
              ? 'ios'
              : 'flutter_device'),
    });
    final res = await http.post(url, headers: await _headers(), body: body);
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (!NotificationsService._initialized) {
      await NotificationsService.initialize();
    }
    await NotificationsService.showRemoteMessage(message);
  } catch (_) {}
}
