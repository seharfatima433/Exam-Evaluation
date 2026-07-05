import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart'; // ✅ Add this import
import 'services/local_quiz_db.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';
import 'views/splash_screen.dart';

// ── FCM Background Handler (must be top-level) ──────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Notifications Service
  try {
    await NotificationService().init();
  } catch (e) {
    print("❌ Local Notification Init Error: $e");
  }

  // ── Bypass self-signed / untrusted SSL certs (dev server) ───────
  HttpOverrides.global = _DevHttpOverrides();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Request FCM permissions explicitly
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    print("❌ FCM Permission Error: $e");
  }
  
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Foreground FCM messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message received: ${message.notification?.title}");
    if (message.notification != null) {
      // Show notification using our NotificationService
      NotificationService().showForegroundFCM(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
      );
    }
  });

  // ── Get FCM Token ────────────────────────────────────────────────
  try {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print("==============================");
    print("✅ FCM TOKEN: $fcmToken");
    print("==============================");
  } catch (e) {
    print("❌ FCM Token Error: $e");
  }

  // ── Supabase initialize ──────────────────────────────────────────
  await Supabase.initialize(
    url: 'https://kvmltsrwtyzqknwjlypi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bWx0c3J3dHl6cWtud2pseXBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwOTg2OTAsImV4cCI6MjA5NDY3NDY5MH0.yS71hBwm9b3ZBXIOQxEYoB6vFlTwaajjBo_R-ti3ZIs',
  );

  // ── Initialize Local Notifications ───────────────────────────────
  await NotificationService().init();

  LocalQuizDb().db.catchError((e) => LocalQuizDb().db);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const App());
}

// Shortcut — poori app mein kahi bhi use karo
final supabase = Supabase.instance.client;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              mode == ThemeMode.dark ? Brightness.light : Brightness.light,
        ));
        return MaterialApp(
          title: 'AI Based Evaluation',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}