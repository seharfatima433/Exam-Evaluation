import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';
import 'quiz_view_screen.dart';

class CourseQuizzesScreen extends StatefulWidget {
  final int teacherId;
  final Course course;
  const CourseQuizzesScreen({
    super.key,
    required this.teacherId,
    required this.course,
  });
  @override
  State<CourseQuizzesScreen> createState() => _CourseQuizzesScreenState();
}

class _CourseQuizzesScreenState extends State<CourseQuizzesScreen>
    with SingleTickerProviderStateMixin {
  late final QuizListController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = QuizListController()
      ..addListener(() { if (mounted) setState(() {}); })
      ..fetchCourseQuizzes(widget.teacherId, widget.course.id);
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
            title: widget.course.courseTitle,
            subtitle: 'Saved Quizzes',
            showBack: true,
            actionIcon: Icons.refresh_rounded,
            onActionTap: () {
              HapticFeedback.lightImpact();
              _ctrl.fetchCourseQuizzes(widget.teacherId, widget.course.id);
            },
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
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text('Loading quizzes…',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                    color: AppTheme.redBg,
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 28, color: AppTheme.red),
              ),
              const SizedBox(height: 14),
              Text(
                _ctrl.error ?? 'Failed to load',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _ctrl.fetchCourseQuizzes(
                    widget.teacherId, widget.course.id),
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

    if (_ctrl.quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.glowShadow(AppTheme.primary, intensity: 0.5),
              ),
              child: const Icon(Icons.quiz_outlined,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('No quizzes yet',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText1
                        : AppTheme.text2)),
            const SizedBox(height: 5),
            Text('Create your first quiz to get started',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText4
                        : AppTheme.text4)),
          ],
        ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.92, end: 1),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          _ctrl.fetchCourseQuizzes(widget.teacherId, widget.course.id),
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: _ctrl.quizzes.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _QuizTile(
            quiz: _ctrl.quizzes[i],
            index: i,
            onTap: () => Navigator.push(
              ctx,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => QuizViewScreen(
                  quizCode: _ctrl.quizzes[i].quizCode,
                  quizName: _ctrl.quizzes[i].quizName,
                ),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          )
              .animate(delay: (60 + i * 55).ms)
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.08, end: 0),
        ),
      ),
    );
  }
}

// ── Quiz Tile ─────────────────────────────────────────────────────
class _QuizTile extends StatefulWidget {
  final QuizSummary quiz;
  final int index;
  final VoidCallback onTap;
  const _QuizTile(
      {required this.quiz, required this.index, required this.onTap});
  @override
  State<_QuizTile> createState() => _QuizTileState();
}

class _QuizTileState extends State<_QuizTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _s = Tween<double>(begin: 1.0, end: 0.975)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Color get _diffColor => widget.quiz.difficulty == 'easy'
      ? AppTheme.green
      : widget.quiz.difficulty == 'hard'
          ? AppTheme.red
          : AppTheme.amber;

  LinearGradient get _diffGrad => widget.quiz.difficulty == 'easy'
      ? AppTheme.greenGrad
      : widget.quiz.difficulty == 'hard'
          ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)])
          : AppTheme.accentGrad;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _c.forward(); HapticFeedback.lightImpact(); },
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          decoration: AppTheme.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header bar
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: const Border(
                      bottom: BorderSide(color: AppTheme.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGrad,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppTheme.glowShadow(AppTheme.primary,
                            intensity: 0.5),
                      ),
                      child: Center(
                        child: Text('${widget.index + 1}',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.quiz.quizName,
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkText1
                                  : AppTheme.text1),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _diffGrad,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                              color: _diffColor.withOpacity(0.28),
                              blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(widget.quiz.difficulty,
                          style: GoogleFonts.outfit(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // Meta info
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 14, runSpacing: 6,
                      children: [
                        _MetaChip(Icons.tag_rounded, widget.quiz.quizCode),
                        _MetaChip(Icons.calendar_today_rounded,
                            widget.quiz.quizDate),
                        _MetaChip(Icons.help_outline_rounded,
                            '${widget.quiz.totalQuestions} Questions'),
                        _MetaChip(
                          Icons.access_time_rounded,
                          '${widget.quiz.startTime.substring(0, 5)} – ${widget.quiz.endTime.substring(0, 5)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: AppTheme.glowShadow(AppTheme.primary,
                              intensity: 0.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Quiz',
                                style: GoogleFonts.outfit(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11,
            color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF42A5F5)
                    : AppTheme.primary)
                .withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText3
                    : AppTheme.text3,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
