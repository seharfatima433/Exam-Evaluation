import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/local_quiz_db.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalQuizDb().db;
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        // Keep status bar icons in sync with current theme
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
