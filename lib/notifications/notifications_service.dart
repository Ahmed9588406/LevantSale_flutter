import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../api/auth/auth_config.dart';
import '../firebase_options.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    developer.log('🔔 Background message received: ${message.messageId}');
    developer.log('📱 Notification title: ${message.notification?.title}');
    developer.log('📱 Notification body: ${message.notification?.body}');
    developer.log('📦 Data: ${message.data}');

    // Extract notification data
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'إشعار جديد';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    // Extract image URL
    final imageUrl =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['imageUrl']?.toString() ??
        message.data['image']?.toString();

    developer.log('🖼️ Image URL: $imageUrl');

    // Show notification using local notifications with image support
    await NotificationsService.showLocalNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      payload: jsonEncode(message.data),
    );

    developer.log('✅ Background notification displayed successfully');
  } catch (e, stackTrace) {
    developer.log('❌ Error handling background message: $e');
    developer.log('Stack trace: $stackTrace');
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool read;
  final String? imageUrl;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.imageUrl,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
      read: (json['read'] ?? json['isRead'] ?? false) == true,
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
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
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  static bool _initialized = false;

  /// Initialize Firebase and notification services
  static Future<void> initialize() async {
    if (_initialized) {
      developer.log('Notifications already initialized');
      return;
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('Firebase initialized successfully');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermission();

      // Configure Firebase Messaging
      await _configureFirebaseMessaging();

      _initialized = true;
      developer.log('Notifications service initialized successfully');
    } catch (e) {
      developer.log('Error initializing notifications: $e');
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    // Android initialization settings with app icon
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher', // Your app icon
        );

    // iOS initialization settings
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultChannel);

    developer.log('Local notifications initialized');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}');
    // You can navigate to specific screens based on payload here
    // Example: if payload contains route info, navigate to that route
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    // Request Firebase Messaging permissions
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    developer.log(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    // Android 13+ requires runtime notification permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      developer.log('Android notification permission: $status');
    }
  }

  /// Configure Firebase Messaging handlers
  static Future<void> _configureFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Configure foreground notification presentation
    // Set alert to false on Android to prevent duplicate notifications
    await messaging.setForegroundNotificationPresentationOptions(
      alert: Platform.isIOS, // Only show alert on iOS
      badge: true,
      sound: Platform.isIOS, // Only play sound on iOS (Android handles it)
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received: ${message.messageId}');
      // Show our custom notification with image support
      showRemoteMessage(message);
    });

    // Handle notification opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Notification opened app: ${message.messageId}');
      // Handle navigation based on notification data
      _handleNotificationNavigation(message);
    });

    // Check if app was opened from a notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'App opened from notification: ${initialMessage.messageId}',
      );
      _handleNotificationNavigation(initialMessage);
    }

    // Handle token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      developer.log('FCM token refreshed: $newToken');
      try {
        // Only send if user is logged in
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          await sendFcmTokenToBackend(fcmToken: newToken);
        }
      } catch (e) {
        developer.log('Error sending refreshed token: $e');
      }
    });

    // Get current token but don't send it yet
    // It will be sent after successful login
    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        developer.log('FCM token obtained: $token');
        // Store token locally for later use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    } catch (e) {
      developer.log('Error getting FCM token: $e');
    }
  }

  /// Handle notification navigation
  static void _handleNotificationNavigation(RemoteMessage message) {
    // Implement your navigation logic here based on message data
    // Example: Navigate to specific screen based on notification type
    final data = message.data;
    developer.log('Handling navigation with data: $data');

    // You can use a navigation service or global navigator key to navigate
    // Example:
    // if (data['type'] == 'message') {
    //   navigatorKey.currentState?.pushNamed('/messages');
    // }
  }

  /// Get FCM token
  static Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      developer.log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Show notification from RemoteMessage
  static Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'إشعار جديد';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    // Extract image URL from notification or data
    final imageUrl =
        notification?.android?.imageUrl ??
        notification?.apple?.imageUrl ??
        message.data['imageUrl']?.toString() ??
        message.data['image']?.toString();

    await showLocalNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      payload: jsonEncode(message.data),
    );
  }

  /// Show local notification with app icon and optional image
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
  }) async {
    // Try to download and cache the image if URL is provided
    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final String dir = (await getApplicationDocumentsDirectory()).path;
          final String imagePath =
              '$dir/notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File imageFile = File(imagePath);
          await imageFile.writeAsBytes(response.bodyBytes);

          final FilePathAndroidBitmap bigPicture = FilePathAndroidBitmap(
            imagePath,
          );
          bigPictureStyle = BigPictureStyleInformation(
            bigPicture,
            contentTitle: title,
            summaryText: body,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          );

          developer.log('Notification image downloaded: $imagePath');
        }
      } catch (e) {
        developer.log('Error downloading notification image: $e');
        // Continue without image
      }
    }

    // Android notification details with app icon and optional image
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation:
              bigPictureStyle ??
              BigTextStyleInformation(
                body,
                contentTitle: title,
                summaryText: 'Levantsale',
              ),
        );

    // iOS notification details with attachment
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // If image URL is provided for iOS, add attachment
    if (imageUrl != null && imageUrl.isNotEmpty && Platform.isIOS) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final String dir = (await getApplicationDocumentsDirectory()).path;
          final String imagePath =
              '$dir/notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File imageFile = File(imagePath);
          await imageFile.writeAsBytes(response.bodyBytes);

          iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: [DarwinNotificationAttachment(imagePath)],
          );
        }
      } catch (e) {
        developer.log('Error downloading iOS notification image: $e');
      }
    }

    // Combined notification details
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    developer.log(
      'Local notification shown: $title ${imageUrl != null ? "(with image)" : ""}',
    );
  }

  /// Get authorization headers with token
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
    } catch (e) {
      developer.log('Error getting auth headers: $e');
    }
    return headers;
  }

  static String get baseUrl => AuthConfig.baseUrl;

  /// Fetch notifications from backend
  static Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications');
      final res = await http.get(url, headers: await _headers());

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data
              .map(
                (e) => NotificationItem.fromJson(
                  (e as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
        } else if (data is Map && data['content'] is List) {
          return (data['content'] as List)
              .map(
                (e) => NotificationItem.fromJson(
                  (e as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
        } else {
          return <NotificationItem>[];
        }
      } else {
        throw Exception('Failed to fetch notifications (${res.statusCode})');
      }
    } catch (e) {
      developer.log('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Fetch unread notification count
  static Future<int> fetchUnreadCount() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/unread-count');
      final res = await http.get(url, headers: await _headers());

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        return (data['count'] ?? 0) is int
            ? data['count'] as int
            : int.tryParse('${data['count']}') ?? 0;
      }
      return 0;
    } catch (e) {
      developer.log('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllRead() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/read-all');
      final res = await http.put(url, headers: await _headers());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      developer.log('Error marking all as read: $e');
      return false;
    }
  }

  /// Mark specific notification as read
  static Future<bool> markRead(String id) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/$id/read');
      final res = await http.patch(url, headers: await _headers());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      developer.log('Error marking notification as read: $e');
      return false;
    }
  }

  /// Delete all notifications
  static Future<bool> deleteAll() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications');
      final res = await http.delete(url, headers: await _headers());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      developer.log('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Delete specific notification
  static Future<bool> deleteById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/notifications/$id');
      final res = await http.delete(url, headers: await _headers());
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      developer.log('Error deleting notification: $e');
      return false;
    }
  }

  /// Send FCM token to backend
  static Future<bool> sendFcmTokenToBackend({
    String? deviceId,
    String? fcmToken,
  }) async {
    try {
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null || authToken.isEmpty) {
        developer.log('❌ User not logged in, skipping FCM token registration');
        return false;
      }

      developer.log(
        '✅ User is logged in, proceeding with FCM token registration',
      );

      // Get FCM token
      final token = fcmToken ?? await getFcmToken();
      if (token == null || token.isEmpty) {
        developer.log('❌ No FCM token available');
        return false;
      }

      developer.log('📱 FCM Token to register: $token');

      // Generate device ID
      final generatedDeviceId =
          deviceId ??
          (Platform.isAndroid
              ? 'android_${DateTime.now().millisecondsSinceEpoch}'
              : Platform.isIOS
              ? 'ios_${DateTime.now().millisecondsSinceEpoch}'
              : 'flutter_device');

      developer.log('🔑 Device ID: $generatedDeviceId');

      final url = Uri.parse('$baseUrl/api/v1/notifications/token');
      final body = jsonEncode({
        'fcmToken': token,
        'deviceId': generatedDeviceId,
      });

      developer.log('🌐 Sending FCM token to: $url');
      developer.log('📤 Request body: $body');

      final res = await http.post(url, headers: await _headers(), body: body);
      final success = res.statusCode >= 200 && res.statusCode < 300;

      if (success) {
        developer.log('✅ FCM token sent to backend successfully!');
        developer.log('📊 Response status: ${res.statusCode}');
        developer.log('📄 Response body: ${res.body}');

        // Store that we've registered this token
        await prefs.setBool('fcm_token_registered', true);
        await prefs.setString('fcm_token', token);
        await prefs.setString('fcm_device_id', generatedDeviceId);

        developer.log('💾 FCM token saved locally');
        developer.log('💾 Stored FCM token: $token');
        developer.log('💾 Stored device ID: $generatedDeviceId');
      } else {
        developer.log('❌ Failed to send FCM token');
        developer.log('📊 Response status: ${res.statusCode}');
        developer.log('📄 Response body: ${res.body}');
      }

      return success;
    } catch (e, stackTrace) {
      developer.log('❌ Error sending FCM token to backend: $e');
      developer.log('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if FCM token needs to be registered
  static Future<bool> needsTokenRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final tokenRegistered = prefs.getBool('fcm_token_registered') ?? false;
      final storedFcmToken = prefs.getString('fcm_token');
      final currentFcmToken = await getFcmToken();

      developer.log('🔍 Checking if FCM token needs registration...');
      developer.log(
        '  - User logged in: ${authToken != null && authToken.isNotEmpty}',
      );
      developer.log('  - Token registered: $tokenRegistered');
      developer.log('  - Stored FCM token: $storedFcmToken');
      developer.log('  - Current FCM token: $currentFcmToken');

      // Need to register if:
      // 1. User is logged in AND
      // 2. Token not registered OR stored token differs from current token
      final needsRegistration =
          authToken != null &&
          authToken.isNotEmpty &&
          (!tokenRegistered || storedFcmToken != currentFcmToken);

      developer.log('  - Needs registration: $needsRegistration');

      return needsRegistration;
    } catch (e) {
      developer.log('❌ Error checking token registration status: $e');
      return false;
    }
  }

  /// Register FCM token if needed (call after login)
  static Future<void> registerTokenIfNeeded() async {
    try {
      developer.log('🔄 Checking if FCM token registration is needed...');
      if (await needsTokenRegistration()) {
        developer.log('✅ Registering FCM token after login...');
        final success = await sendFcmTokenToBackend();
        if (success) {
          developer.log('✅ FCM token registration completed successfully');
        } else {
          developer.log('❌ FCM token registration failed');
        }
      } else {
        developer.log('ℹ️ FCM token already registered or not needed');
      }
    } catch (e) {
      developer.log('❌ Error in registerTokenIfNeeded: $e');
    }
  }
}
