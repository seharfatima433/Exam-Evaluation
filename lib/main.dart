import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/local_quiz_db.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase initialize ──────────────────────────────────────────
  await Supabase.initialize(
    url: 'https://kvmltsrwtyzqknwjlypi.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2bWx0c3J3dHl6cWtud2pseXBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwOTg2OTAsImV4cCI6MjA5NDY3NDY5MH0.yS71hBwm9b3ZBXIOQxEYoB6vFlTwaajjBo_R-ti3ZIs',
  );

  LocalQuizDb().db.catchError((_) {});
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