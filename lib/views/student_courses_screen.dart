import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_theme.dart';
import '../utils/theme_controller.dart';
import '../services/student_service.dart';
import '../widgets/app_profile_drawer.dart';
import '../widgets/premium_app_bar.dart';
import 'student_course_detail_screen.dart';
import 'student_results_screen.dart';
import 'student_screen.dart'; // NsctScreen, NsctSyllabusScreen, NsctMaterialScreen
import 'login_screen.dart';
import '../services/fcm_sender_service.dart';

// ══════════════════════════════════════════════════════════════════
// STUDENT COURSES SCREEN — enrolled courses list
// ══════════════════════════════════════════════════════════════════
class StudentCoursesScreen extends StatefulWidget {
  final String studentName;
  final int studentId;
  final String? rollNo;

  const StudentCoursesScreen({
    super.key,
    required this.studentName,
    required this.studentId,
    this.rollNo,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = StudentService();
  List<StudentCourse> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    Map<String, dynamic> result;
    if (widget.rollNo != null && widget.rollNo!.isNotEmpty) {
      result = await _service.fetchMyCourses(widget.rollNo!);
    } else {
      result = await _service.fetchStudentCoursesByUserId(widget.studentId);
    }
    if (!mounted) return;
    if (result['success'] == true) {
      final list = result['data'] as List<StudentCourse>;
      setState(() { _courses = list; _loading = false; });
      
      // ── Subscribe to Course Notification Topics ──
      try {
        final List<String> topicsToStore = [];
        for (final course in list) {
          final topicName = 'course_${course.id}';
          FirebaseMessaging.instance.subscribeToTopic(topicName);
          topicsToStore.add(topicName);
          debugPrint('📢 Student subscribed to FCM topic: $topicName');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('fcm_topics', topicsToStore);
      } catch (e) {
        debugPrint('❌ Error subscribing to FCM course topics: $e');
      }
    } else {
      setState(() { _error = result['message'] as String?; _loading = false; });
    }
  }

  String get _initials {
    final p = widget.studentName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppProfileDrawer(
        name: widget.studentName,
        initials: _initials,
        role: 'student',
        extraInfo: widget.rollNo,
        userId: widget.studentId,
      ),
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.studentName,
            subtitle: widget.rollNo != null ? 'Roll No: ${widget.rollNo}' : 'My Enrolled Courses',
            initials: _initials,
            onLeadingTap: () {
              HapticFeedback.lightImpact();
              _scaffoldKey.currentState?.openDrawer();
            },
            showThemeToggle: true,
            actionIcon: Icons.refresh_rounded,
            onActionTap: _load,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
        const SizedBox(height: 14),
        Text('Loading your courses…', style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
      ]));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64,
            decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 30, color: AppTheme.red)),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Try Again', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary)),
      ])));
    }
    if (_courses.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(gradient: AppTheme.primaryGrad, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.school_outlined, color: Colors.white, size: 36)),
        const SizedBox(height: 20),
        Text('No Courses Found', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
        const SizedBox(height: 6),
        Text('You are not enrolled in any course yet. Please contact your admin.', textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
      ])));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          // Dynamic student welcome banner
          _buildHeroBanner(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats row ───────────────────────────────────────
                _StudentStatsRow(courseCount: _courses.length)
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 22),

                // ── Section header ──────────────────────────────────
                _buildSectionHeader('My Enrolled Courses', _courses.length)
                    .animate(delay: 100.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 12),

                // ── Course cards ────────────────────────────────────
                ...List.generate(_courses.length, (i) {
                  final course = _courses[i];

                  const accentColors = [
                    AppTheme.primary, AppTheme.greenDark, AppTheme.violet,
                    AppTheme.amber, AppTheme.teal,
                  ];
                  const accentBgs = [
                    AppTheme.primaryBg, AppTheme.greenBg, AppTheme.violetBg,
                    AppTheme.amberBg, AppTheme.tealBg,
                  ];
                  const accentGrads = [
                    AppTheme.primaryGrad, AppTheme.greenGrad, AppTheme.violetGrad,
                    AppTheme.accentGrad, AppTheme.primaryGrad,
                  ];

                  final color = accentColors[i % accentColors.length];
                  final bg    = accentBgs[i % accentBgs.length];
                  final grad  = accentGrads[i % accentGrads.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentCourseCard(
                      course: course,
                      color: color,
                      bg: bg,
                      gradient: grad,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, a, __) => StudentCourseDetailScreen(
                            course: course,
                            studentId: widget.studentId,
                            studentName: widget.studentName,
                            accentColor: color,
                            rollNo: widget.rollNo,
                          ),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(opacity: a, child: child),
                          transitionDuration: const Duration(milliseconds: 280),
                        ));
                      },
                    ),
                  ).animate(delay: Duration(milliseconds: 120 + i * 70))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.06, end: 0, duration: 400.ms);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                letterSpacing: -0.2)),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.primaryBg,
              borderRadius: BorderRadius.circular(50)),
          child: Text('$count',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E1B6A),
            Color(0xFF3730A3),
            Color(0xFF4F46E5),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Dynamic student welcome animation
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Lottie.asset(
                'assets/lottie/student.json',
                fit: BoxFit.cover,
                animate: true,
                repeat: true,
              ),
            ),
          )
              .animate()
              .scaleXY(
                  begin: 0.5,
                  end: 1.0,
                  duration: 800.ms,
                  curve: Curves.elasticOut)
              .fadeIn(duration: 500.ms),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting + '! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.78),
                    fontWeight: FontWeight.w400,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 450.ms),
                const SizedBox(height: 4),
                Text(
                  widget.studentName,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STUDENT STATS ROW
// ══════════════════════════════════════════════════════════════════
class _StudentStatsRow extends StatelessWidget {
  final int courseCount;
  const _StudentStatsRow({required this.courseCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Courses',
            value: '$courseCount',
            icon: Icons.menu_book_rounded,
            gradient: AppTheme.primaryGrad,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Enrolled',
            value: 'Active',
            icon: Icons.verified_rounded,
            gradient: AppTheme.greenGrad,
            color: AppTheme.greenDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient gradient;
  final Color color;
  const _StatCard({
    required this.label, required this.value, required this.icon,
    required this.gradient, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.themedCard(context),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 14, offset: const Offset(0, 5))
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText1
                          : AppTheme.text1, letterSpacing: -0.8)),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText3
                          : AppTheme.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STUDENT COURSE CARD — matches teacher's _CourseCard design
// ══════════════════════════════════════════════════════════════════
class _StudentCourseCard extends StatefulWidget {
  final StudentCourse course;
  final Color color, bg;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _StudentCourseCard({
    required this.course,
    required this.color,
    required this.bg,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_StudentCourseCard> createState() => _StudentCourseCardState();
}

class _StudentCourseCardState extends State<_StudentCourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color;
    final bg = widget.bg;
    final grad = widget.gradient;

    return ScaleTransition(
      scale: _s,
      child: GestureDetector(
        onTapDown: (_) { _c.forward(); HapticFeedback.selectionClick(); },
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: Container(
          decoration: AppTheme.themedCard(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header with tinted background ─────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.08) : bg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: Border(
                      bottom: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.30),
                              blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.courseTitle,
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (widget.course.courseCode != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(widget.course.courseCode!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 10, fontWeight: FontWeight.w600,
                                      color: color)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Action button ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: grad,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.30),
                            blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 7),
                        Text('View Details',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NSCT DRAWER
// ══════════════════════════════════════════════════════════════════
class _NsctDrawer extends StatelessWidget {
  final String studentName;
  final String initials;
  final String? rollNo;
  final int studentId;

  const _NsctDrawer({
    required this.studentName,
    required this.initials,
    required this.rollNo,
    required this.studentId,
  });

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 285,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(studentName,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (rollNo != null)
                    Text('Roll No: $rollNo',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.70))),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── NSCT Section ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text('NSCT PREPARATION',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
            ),

            _DrawerTile(
              icon: Icons.school_rounded,
              label: 'NSCT Home',
              subtitle: 'Overview & options',
              color: AppTheme.primary,
              onTap: () => _go(context, const NsctScreen()),
            ),
            _DrawerTile(
              icon: Icons.menu_book_rounded,
              label: 'Syllabus',
              subtitle: '10 subjects · all topics',
              color: AppTheme.violet,
              onTap: () => _go(context, const NsctSyllabusScreen()),
            ),
            _DrawerTile(
              icon: Icons.folder_copy_rounded,
              label: 'Preparation Material',
              subtitle: 'Notes, MCQs, PDF guides',
              color: AppTheme.greenDark,
              onTap: () => _go(context, const NsctMaterialScreen()),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 12),

            _DrawerTile(
              icon: Icons.assignment_turned_in_rounded,
              label: 'My Results',
              subtitle: 'View all past quiz scores',
              color: AppTheme.primary,
              onTap: () => _go(context, StudentResultsScreen(studentId: studentId, studentName: studentName)),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Settings',
                  style: GoogleFonts.outfit(fontSize: 10,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ),

            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                final isLight = mode == ThemeMode.light;
                return _DrawerTile(
                  icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  label: isLight ? 'Dark Mode' : 'Light Mode',
                  subtitle: 'Change app theme',
                  color: AppTheme.amber,
                  onTap: () {
                    toggleTheme();
                    Navigator.pop(context);
                  },
                );
              },
            ),

            _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              subtitle: 'Sign out of your account',
              color: AppTheme.red,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_session'); // Or just remove specific keys
                await FCMSenderService.clearFCMData();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('AI Based Evaluation · Student',
                  style: GoogleFonts.outfit(fontSize: 10,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon, required this.label,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
              Text(subtitle, style: GoogleFonts.outfit(fontSize: 10,
                  color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
            ])),
            Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
          ]),
        ),
      ),
    );
  }
}