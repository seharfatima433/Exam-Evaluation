import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMSenderService {
  static const String _serviceAccountJson = r'''
{
  "type": "dummy"
}
  ''';

  // ── Cached Access Token to avoid re-generating every call ────────
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  static Future<String?> _getAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _cachedToken;
    }

    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      _cachedToken = authClient.credentials.accessToken.data;
      _tokenExpiry = authClient.credentials.accessToken.expiry;
      authClient.close();
      return _cachedToken;
    } catch (e) {
      print("❌ Error generating FCM Access Token: $e");
      rethrow;
    }
  }

  /// Sends FCM notification to a specific device token. Returns null on success or error string.
  static Future<String?> _sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      String? accessToken = await _getAccessToken();
      if (accessToken == null) {
        return "Failed to generate OAuth 2.0 access token. Check internet connection and service account JSON.";
      }

      const projectId = 'eduquiz-6ed21';
      const url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "token": token,
            "notification": {
              "title": title,
              "body": body,
            },
            "data": data ?? {"click_action": "FLUTTER_NOTIFICATION_CLICK"},
            "android": {
              "priority": "high",
              "notification": {
                "channel_id": "high_importance_channel",
                "sound": "default",
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print("✅ FCM sent to token: $title");
        return null;
      } else {
        final err = "FCM HTTP Error ${response.statusCode}: ${response.body}";
        print("❌ $err");
        return err;
      }
    } catch (e) {
      final err = "FCM Exception: $e";
      print("❌ $err");
      return err;
    }
  }

  /// Sends FCM notification to all subscribers of a specific topic. Returns null on success or error string.
  static Future<String?> _sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      String? accessToken = await _getAccessToken();
      if (accessToken == null) {
        return "Failed to generate OAuth 2.0 access token. Check internet connection and service account JSON.";
      }

      const projectId = 'eduquiz-6ed21';
      const url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "topic": topic,
            "notification": {
              "title": title,
              "body": body,
            },
            "data": data ?? {"click_action": "FLUTTER_NOTIFICATION_CLICK"},
            "android": {
              "priority": "high",
              "notification": {
                "channel_id": "high_importance_channel",
                "sound": "default",
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print("✅ FCM sent to topic '$topic': $title");
        return null;
      } else {
        final err = "FCM Topic HTTP Error ${response.statusCode}: ${response.body}";
        print("❌ $err");
        return err;
      }
    } catch (e) {
      final err = "FCM Topic Exception: $e";
      print("❌ $err");
      return err;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. WELCOME NOTIFICATION — on login (sent to self device token)
  // ═══════════════════════════════════════════════════════════════════
  static Future<String?> sendWelcomeNotification(String userName) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        return "Could not retrieve device FCM Token. Make sure Google Play Services are running and updated.";
      }
      return await _sendToToken(
        token: fcmToken,
        title: 'Welcome to EduQuiz! 🎉',
        body: 'Hello $userName, you have successfully logged in😎',
        data: {"type": "welcome", "click_action": "FLUTTER_NOTIFICATION_CLICK"},
      );
    } catch (e) {
      final err = "Welcome notification failed: $e";
      print("❌ $err");
      return err;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. QUIZ SCHEDULED NOTIFICATION — to all students of the course (Topic)
  // ═══════════════════════════════════════════════════════════════════
  static Future<String?> sendQuizScheduledNotification({
    required int courseId,
    required String quizName,
    required String courseName,
    required String quizDate,
    required String startTime,
    required String endTime,
    bool isPoll = false,
  }) async {
    final type = isPoll ? 'Poll' : 'Quiz';
    return await _sendToTopic(
      topic: 'course_$courseId',
      title: '📝 New $type Scheduled!',
      body: '$quizName for "$courseName" on $quizDate ($startTime - $endTime). Be ready!',
      data: {
        "type": "quiz_scheduled",
        "quiz_name": quizName,
        "course_name": courseName,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. RESULT UNLOCKED NOTIFICATION — to a specific student (Token)
  // ═══════════════════════════════════════════════════════════════════
  static Future<String?> sendResultUnlockedNotification({
    required String quizName,
    String? courseName,
    String? score,
    String? percentage,
  }) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        return "Could not retrieve device FCM Token. Make sure Google Play Services are running and updated.";
      }

      String body = 'Your result for "$quizName" is now available!';
      if (score != null && percentage != null) {
        body = 'You scored $score ($percentage%) in "$quizName". Check your detailed results now!';
      }

      return await _sendToToken(
        token: fcmToken,
        title: '🏆 Result Released!',
        body: body,
        data: {
          "type": "result_unlocked",
          "quiz_name": quizName,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
      );
    } catch (e) {
      final err = "Result unlocked notification failed: $e";
      print("❌ $err");
      return err;
    }
  }

  static Future<void> clearFCMData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> topics = prefs.getStringList('fcm_topics') ?? [];
      for (final topic in topics) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        print("📢 Unsubscribed from FCM topic: $topic");
      }
      await prefs.remove('fcm_topics');
      print("✅ FCM session cleared and topics unsubscribed.");
    } catch (e) {
      print("❌ Error clearing FCM data: $e");
    }
  }
}
