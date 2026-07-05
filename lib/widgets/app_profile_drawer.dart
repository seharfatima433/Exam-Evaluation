import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/theme_controller.dart';
import '../views/login_screen.dart';
import '../views/student_screen.dart'; // NsctScreen
import '../views/student_results_screen.dart';
import '../services/fcm_sender_service.dart';

class AppProfileDrawer extends StatelessWidget {
  final String name;
  final String initials;
  final String role; // 'student' or 'teacher'
  final String? extraInfo; // Roll No or Teacher ID
  final int userId;

  const AppProfileDrawer({
    super.key,
    required this.name,
    required this.initials,
    required this.role,
    this.extraInfo,
    required this.userId,
  });

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.red),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText1
                    : AppTheme.text1,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkText3
                : AppTheme.text3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText3
                    : AppTheme.text3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_session');
              await FCMSenderService.clearFCMData();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const LoginScreen(),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStudent = role.toLowerCase() == 'student';

    return Drawer(
      width: 290,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dynamic Profile Header with Gradient ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGrad,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar Badge with Initials
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Animated human Lottie inside Header
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Lottie.asset(
                          isStudent
                              ? 'assets/lottie/student.json'
                              : 'assets/lottie/teacher.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isStudent ? 'Student Account' : 'Teacher Account',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (extraInfo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      isStudent ? 'Roll No: $extraInfo' : 'Teacher ID: $extraInfo',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.80),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Menu Items ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: Text(
                      'PORTAL NAVIGATOR',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                      ),
                    ),
                  ),

                  // Standard dashboard item
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard Home',
                    subtitle: 'Main overview',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  if (isStudent) ...[
                    // NSCT Preparation Items for student only
                    _DrawerItem(
                      icon: Icons.school_rounded,
                      label: 'NSCT Preparation',
                      subtitle: 'Syllabus & Material',
                      color: AppTheme.violet,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NsctScreen()),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.analytics_rounded,
                      label: 'My Results',
                      subtitle: 'Grading history & stats',
                      color: AppTheme.greenDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentResultsScreen(
                              studentId: userId,
                              studentName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                    child: Text(
                      'PREFERENCES & SYSTEM',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                      ),
                    ),
                  ),

                  // Theme Selector
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, child) {
                      final isLight = mode == ThemeMode.light;
                      return _DrawerItem(
                        icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        label: isLight ? 'Dark Mode' : 'Light Mode',
                        subtitle: 'Toggle screen theme',
                        color: AppTheme.amber,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          toggleTheme();
                        },
                      );
                    },
                  ),

                  // Sign out
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    subtitle: 'Safely end your session',
                    color: AppTheme.red,
                    onTap: () {
                      _confirmLogout(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer branding
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduQuiz Pro',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                          ),
                        ),
                        Text(
                          'AI-Powered Academics',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? AppTheme.darkText4 : AppTheme.text4,
            ),
          ],
        ),
      ),
    );
  }
}
