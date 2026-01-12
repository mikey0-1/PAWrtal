import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('>>> Background message received: ${message.messageId}');
  debugPrint('>>> Title: ${message.notification?.title}');
  debugPrint('>>> Body: ${message.notification?.body}');
  debugPrint('>>> Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final FirebaseMessaging _firebaseMessaging;
  final GetStorage _storage = GetStorage();

  String? _currentFCMToken;
  bool _isInitialized = false;

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  /// Get current FCM token

  String? get fcmToken => _currentFCMToken;

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  Future<void> initializeNotifications() async {
    try {
      // Only initialize FCM on mobile platforms
      if (!kIsWeb) {
        await _initializeFCM();
      } else {}

      // Initialize local notifications (works on both mobile and web)
      await _initializeLocalNotifications();

      _isInitialized = true;
    } catch (e) {}
  }

  Future<void> _initializeFCM() async {
    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permissions (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _currentFCMToken = await _firebaseMessaging.getToken();

        // Store token locally
        if (_currentFCMToken != null) {
          _storage.write('fcm_token', _currentFCMToken);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _currentFCMToken = newToken;
          _storage.write('fcm_token', newToken);
          // TODO: Update token in Appwrite when user is logged in
        });

        // Set up message handlers
        _setupMessageHandlers();
      } else {}
    } catch (e) {}
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationTapFromBackground);

    // Check for initial notification (app opened from terminated state)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and navigate
      try {
        // Payload format: "type:value" (e.g., "appointment:abc123")
        final parts = response.payload!.split(':');
        if (parts.length >= 2) {
          final type = parts[0];
          final id = parts[1];
          _navigateToScreen(type, id);
        }
      } catch (e) {}
    }
  }

  void _handleNotificationTapFromBackground(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'PAWrtal',
      body: message.notification?.body ?? 'You have a new notification',
      payload: _createPayloadFromData(message.data),
      data: message.data,
    );
  }

  String _createPayloadFromData(Map<String, dynamic> data) {
    // Create simple payload format: "type:id"
    final type = data['type'] ?? 'unknown';
    final id = data['appointmentId'] ?? data['messageId'] ?? '';
    return '$type:$id';
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    // Determine notification importance based on type
    var importance = Importance.high;
    var priority = Priority.high;

    if (data != null) {
      final type = data['type'];
      if (type == 'new_appointment' || type == 'appointment') {
        importance = Importance.max;
        priority = Priority.max;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'pawrtal_channel',
      'PAWrtal Notifications',
      channelDescription: 'Notifications for appointments and messages',
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'appointment' || type == 'new_appointment') {
      final appointmentId = data['appointmentId'];
      if (appointmentId != null) {
        _navigateToScreen('appointment', appointmentId);
      }
    } else if (type == 'message') {
      final conversationId = data['conversationId'];
      if (conversationId != null) {
        _navigateToScreen('message', conversationId);
      }
    }
  }

  void _navigateToScreen(String type, String id) {
    // Use GetX navigation
    switch (type) {
      case 'appointment':
      case 'new_appointment':
        // Navigate to appointments screen
        // Get.toNamed('/appointments', arguments: {'appointmentId': id});
        break;
      case 'message':
        // Navigate to messages screen
        // Get.toNamed('/messages', arguments: {'conversationId': id});
        break;
      default:
    }
  }

  /// Request notification permissions (call after login)
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Get fresh FCM token (call after login)
  Future<String?> getFreshToken() async {
    if (kIsWeb) {
      return null;
    }

    try {
      _currentFCMToken = await _firebaseMessaging.getToken();
      if (_currentFCMToken != null) {
        _storage.write('fcm_token', _currentFCMToken);
      }
      return _currentFCMToken;
    } catch (e) {
      return null;
    }
  }

  /// Clear notification token (call on logout)
  Future<void> clearToken() async {
    try {

      if (!kIsWeb) {
        // Delete the token from Firebase
        await _firebaseMessaging.deleteToken();
      }

      // Clear local storage
      _currentFCMToken = null;
      _storage.remove('fcm_token');
      _storage.remove('push_target_id'); // Also remove push target ID

    } catch (e) {
      // Still clear local storage even if deleteToken fails
      _currentFCMToken = null;
      _storage.remove('fcm_token');
      _storage.remove('push_target_id');
    }
  }

  /// Manual notification for testing
  Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from PAWrtal',
      payload: 'test:123',
    );
  }
}
