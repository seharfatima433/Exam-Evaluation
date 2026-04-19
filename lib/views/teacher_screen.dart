import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';
import 'course_quizzes_screen.dart';
import 'quiz_creation_screen.dart';

class TeacherScreen extends StatefulWidget {
  final int teacherId;
  final String teacherName;
  const TeacherScreen({
    super.key,
    required this.teacherId,
    this.teacherName = 'Teacher',
  });
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen>
    with SingleTickerProviderStateMixin {
  late final CourseController _ctrl;

  String get _initials {
    final p = widget.teacherName.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return widget.teacherName.isNotEmpty
        ? widget.teacherName[0].toUpperCase()
        : 'T';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = CourseController()
      ..addListener(() { if (mounted) setState(() {}); })
      ..fetchTeacherCourses(widget.teacherId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.teacherName,
            subtitle: 'My Courses',
            initials: _initials,
            showThemeToggle: true,
            actionIcon: Icons.refresh_rounded,
            onActionTap: () => _ctrl.fetchTeacherCourses(widget.teacherId),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.state == LoadState.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 14),
            Text('Loading courses…',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3)),
          ],
        ),
      );
    }
    if (_ctrl.state == LoadState.error) {
      return _ErrorState(
        message: _ctrl.error ?? 'Failed to load',
        onRetry: () => _ctrl.fetchTeacherCourses(widget.teacherId),
      );
    }
    if (_ctrl.courses.isEmpty) {
      return const _EmptyState(message: 'No courses assigned yet');
    }

    return RefreshIndicator(
      onRefresh: () => _ctrl.fetchTeacherCourses(widget.teacherId),
      color: Theme.of(context).primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          // Stats row
          _StatsRow(
            courseCount: _ctrl.courseCount,
            studentCount: _ctrl.totalStudents,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 22),

          // Section header
          _buildSectionHeader('Your Courses', _ctrl.courses.length)
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          // Course cards with stagger
          ...List.generate(_ctrl.courses.length, (i) {
            final course = _ctrl.courses[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                course: course,
                colorIndex: i,
                onCreateQuiz: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => QuizCreationScreen(
                      teacherId: widget.teacherId,
                      course: course,
                    ),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                ),
                onViewQuizzes: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => CourseQuizzesScreen(
                      teacherId: widget.teacherId,
                      course: course,
                    ),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                ),
              )
                  .animate(delay: (120 + i * 70).ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.06, end: 0, duration: 400.ms),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText1
                    : AppTheme.text1,
                letterSpacing: -0.2)),
        const SizedBox(width: 9),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
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
}

// ── Stats Row ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int courseCount, studentCount;
  const _StatsRow({required this.courseCount, required this.studentCount});

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
            bg: AppTheme.primaryBg,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Students',
            value: '$studentCount',
            icon: Icons.people_rounded,
            gradient: AppTheme.greenGrad,
            bg: AppTheme.greenBg,
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
  final Gradient gradient;
  final Color bg, color;
  const _StatCard({
    required this.label, required this.value, required this.icon,
    required this.gradient, required this.bg, required this.color,
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
                      fontSize: 24, fontWeight: FontWeight.w800,
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

// ── Course Card ───────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  final int colorIndex;
  final VoidCallback onCreateQuiz, onViewQuizzes;

  static const _colors = [
    AppTheme.primary, AppTheme.greenDark, AppTheme.violet,
    AppTheme.amber, AppTheme.teal,
  ];
  static const _bgs = [
    AppTheme.primaryBg, AppTheme.greenBg, AppTheme.violetBg,
    AppTheme.amberBg, AppTheme.tealBg,
  ];
  static const _grads = [
    AppTheme.primaryGrad, AppTheme.greenGrad, AppTheme.violetGrad,
    AppTheme.accentGrad, AppTheme.primaryGrad,
  ];

  const _CourseCard({
    required this.course, required this.colorIndex,
    required this.onCreateQuiz, required this.onViewQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colors[colorIndex % _colors.length];
    final bg    = _bgs[colorIndex % _bgs.length];
    final grad  = _grads[colorIndex % _grads.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: AppTheme.themedCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────
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
                        course.courseTitle,
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppTheme.text1),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Course ID: ${course.id}',
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

          // ── Action buttons ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Create Quiz',
                    icon: Icons.add_circle_outline_rounded,
                    primary: true,
                    color: color,
                    gradient: grad,
                    onTap: onCreateQuiz,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'View Quizzes',
                    icon: Icons.list_alt_rounded,
                    primary: false,
                    color: color,
                    gradient: grad,
                    onTap: onViewQuizzes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label, required this.icon, required this.primary,
    required this.color, required this.gradient, required this.onTap,
  });
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
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
    return GestureDetector(
      onTapDown: (_) { _c.forward(); HapticFeedback.selectionClick(); },
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: widget.primary ? widget.gradient : null,
            color: widget.primary
                ? null
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkInput
                    : AppTheme.bg),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.primary
                  ? Colors.transparent
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkBorder
                      : AppTheme.border),
              width: 1.2,
            ),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.30),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 13,
                  color: widget.primary
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText3
                          : AppTheme.text3)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(widget.label,
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: widget.primary
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkText2
                                : AppTheme.text2),
                        letterSpacing: 0.1),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error States ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.glowShadow(AppTheme.primary,
                    intensity: 0.5),
              ),
              child: const Icon(Icons.inbox_rounded,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3)),
          ],
        ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.92, end: 1),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    color: AppTheme.redBg,
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 30, color: AppTheme.red),
              ),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText3
                          : AppTheme.text3)),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: Text('Try Again',
                    style: GoogleFonts.outfit(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      );
}
