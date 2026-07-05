import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _tzInitialized = false;

  Future<void> init() async {
    // Initialize timezone data
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );
    
    // Request permissions for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    // Request exact alarm permission for Android 12+ (needed for scheduled notifications)
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> showWelcomeNotification(String userName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'welcome_channel',
      'Welcome Notifications',
      channelDescription: 'Notifications shown when user logs in',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique Notification ID
      'Welcome to EduQuiz! 🎉',
      'Hello $userName, you have successfully logged in.',
      platformChannelSpecifics,
    );
  }

  Future<void> showForegroundFCM(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fcm_channel',
      'FCM Notifications',
      channelDescription: 'Notifications shown when FCM message arrives in foreground',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCHEDULED RESULT NOTIFICATION — fires at quiz end_time
  // ═══════════════════════════════════════════════════════════════════
  Future<void> scheduleResultNotification({
    required int quizId,
    required String quizName,
    required DateTime scheduledTime,
  }) async {
    try {
      // Ensure timezone is initialized
      if (!_tzInitialized) {
        await init();
      }

      // Convert DateTime to UTC DateTime to avoid platform-specific local timezone lookup issues
      final utcTime = scheduledTime.toUtc();
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.utc(
        utcTime.year,
        utcTime.month,
        utcTime.day,
        utcTime.hour,
        utcTime.minute,
        utcTime.second,
      );

      // Don't schedule if time is already in the past
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.UTC))) {
        print('⏰ Result unlock time is already in the past, skipping scheduled notification.');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'result_unlock_channel',
        'Result Notifications',
        channelDescription: 'Notifications when quiz results become available',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Use quizId as notification ID so we can cancel/update if needed
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        quizId, // Unique per quiz
        '🏆 Your Result is Out!',
        'Results for "$quizName" are now available. Check your score now! 📊',
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );

      print('✅ Scheduled background result notification for "$quizName" at $scheduledTime');

      // ── Foreground Timer fallback: if the student has the app open ──
      final difference = scheduledTime.difference(DateTime.now());
      if (!difference.isNegative) {
        Timer(difference, () {
          showForegroundFCM(
            '🏆 Your Result is Out!',
            'Results for "$quizName" are now available. Check your score now! 📊',
          );
        });
        print('⏰ Set foreground timer for $difference');
      }
    } catch (e) {
      print('❌ Error scheduling result notification: $e');
    }
  }

  /// Cancel a previously scheduled result notification
  Future<void> cancelScheduledNotification(int quizId) async {
    await _flutterLocalNotificationsPlugin.cancel(quizId);
  }
}
