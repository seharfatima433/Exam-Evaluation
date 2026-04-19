import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../models/quiz_model.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

class QuizViewScreen extends StatefulWidget {
  final String quizCode, quizName;
  const QuizViewScreen({
    super.key,
    required this.quizCode,
    this.quizName = 'Quiz',
  });
  @override
  State<QuizViewScreen> createState() => _QuizViewScreenState();
}

class _QuizViewScreenState extends State<QuizViewScreen>
    with SingleTickerProviderStateMixin {
  late final QuizViewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = QuizViewController()
      ..addListener(() { if (mounted) setState(() {}); })
      ..fetchQuiz(widget.quizCode);
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
            title: widget.quizName,
            subtitle: 'Code: ${widget.quizCode}',
            showBack: true,
            tag: widget.quizCode,
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
            Text('Loading quiz…',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3)),
          ],
        ),
      );
    }

    if (_ctrl.state == LoadState.error || _ctrl.quiz == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                  color: AppTheme.redBg,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.error_outline_rounded,
                  size: 28, color: AppTheme.red),
            ),
            const SizedBox(height: 14),
            Text(_ctrl.error ?? 'Failed to load quiz',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkText3
                        : AppTheme.text3)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _ctrl.fetchQuiz(widget.quizCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Try Again',
                  style: GoogleFonts.outfit(fontSize: 13)),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    final quiz   = _ctrl.quiz!;
    final mcqs   = quiz.questions.where((q) => q.type == 'mcq').toList();
    final shorts = quiz.questions.where((q) => q.type == 'short').toList();
    final fills  = quiz.questions.where((q) => q.type == 'fill').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _InfoBar(quiz: quiz)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0),

        const SizedBox(height: 22),

        if (mcqs.isNotEmpty) ...[
          _SectionHeader('Multiple Choice', mcqs.length, AppTheme.primary,
              AppTheme.primaryGrad),
          const SizedBox(height: 10),
          ...List.generate(
            mcqs.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _McqCard(q: mcqs[i], index: i + 1)
                  .animate(delay: (80 + i * 50).ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (shorts.isNotEmpty) ...[
          _SectionHeader('Short Questions', shorts.length,
              AppTheme.greenDark, AppTheme.greenGrad),
          const SizedBox(height: 10),
          ...List.generate(
            shorts.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ShortCard(q: shorts[i], index: i + 1)
                  .animate(delay: (80 + i * 50).ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (fills.isNotEmpty) ...[
          _SectionHeader('Fill in the Blanks', fills.length,
              AppTheme.violet, AppTheme.violetGrad),
          const SizedBox(height: 10),
          ...List.generate(
            fills.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FillCard(q: fills[i], index: i + 1)
                  .animate(delay: (80 + i * 50).ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Info Bar ──────────────────────────────────────────────────────
class _InfoBar extends StatelessWidget {
  final FullQuiz quiz;
  const _InfoBar({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGrad,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.glowShadow(AppTheme.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -15, right: -15,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Wrap(
            spacing: 18, runSpacing: 10,
            children: [
              _InfoChip(Icons.tag_rounded, quiz.quizCode),
              _InfoChip(Icons.calendar_today_rounded, quiz.quizDate),
              _InfoChip(
                Icons.access_time_rounded,
                '${quiz.startTime.substring(0, 5)} – ${quiz.endTime.substring(0, 5)}',
              ),
              _InfoChip(
                Icons.help_outline_rounded,
                '${quiz.questions.length} questions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.75)),
        const SizedBox(width: 5),
        Text(text,
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.white,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final LinearGradient gradient;
  const _SectionHeader(this.title, this.count, this.color, this.gradient);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkText1
                    : AppTheme.text1, letterSpacing: -0.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Text('$count',
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ],
    );
  }
}

// ── MCQ Card ──────────────────────────────────────────────────────
class _McqCard extends StatelessWidget {
  final QuizQuestion q;
  final int index;
  const _McqCard({required this.q, required this.index});

  String _correct() {
    final ca   = q.correctAnswer ?? '';
    final opts = [q.optionA, q.optionB, q.optionC, q.optionD];
    if (ca.length == 1 && 'abcd'.contains(ca.toLowerCase())) {
      final i = 'abcd'.indexOf(ca.toLowerCase());
      return opts[i] ?? ca;
    }
    return ca;
  }

  @override
  Widget build(BuildContext context) {
    final correct = _correct();
    final opts = [
      ('A', q.optionA), ('B', q.optionB),
      ('C', q.optionC), ('D', q.optionD),
    ].where((o) => o.$2 != null).toList();

    return Container(
      decoration: AppTheme.themedCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.primary.withOpacity(0.08)
                  : AppTheme.primaryBg.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).dividerColor, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index, AppTheme.primaryGrad),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.question,
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkText1
                              : AppTheme.text1, height: 1.5)),
                ),
              ],
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: opts.map((o) {
                final isCorrect = o.$2 == correct;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.green.withOpacity(0.12)
                            : AppTheme.greenBg)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkInput
                            : AppTheme.surfaceAlt),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect
                          ? AppTheme.green.withOpacity(0.4)
                          : Theme.of(context).dividerColor,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          gradient: isCorrect
                              ? AppTheme.greenGrad
                              : null,
                          color: isCorrect ? null : AppTheme.border,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: isCorrect
                              ? [
                                  BoxShadow(
                                      color: AppTheme.greenDark
                                          .withOpacity(0.28),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(o.$1,
                              style: GoogleFonts.outfit(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: isCorrect
                                      ? Colors.white
                                      : AppTheme.text3)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(o.$2!,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isCorrect
                                    ? (Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.green
                                        : AppTheme.greenDark)
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.darkText2
                                        : AppTheme.text2),
                                fontWeight: isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ),
                      if (isCorrect)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.greenDark,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 10, color: Colors.white),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Short Question Card ───────────────────────────────────────────
class _ShortCard extends StatelessWidget {
  final QuizQuestion q;
  final int index;
  const _ShortCard({required this.q, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.themedCard(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IndexBadge(index, AppTheme.greenGrad),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.question,
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText1
                          : AppTheme.text1, height: 1.5)),
            ),
          ],
        ),
      );
}

// ── Fill Card ─────────────────────────────────────────────────────
class _FillCard extends StatelessWidget {
  final QuizQuestion q;
  final int index;
  const _FillCard({required this.q, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index, AppTheme.violetGrad),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.question,
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkText1
                              : AppTheme.text1, height: 1.5)),
                ),
              ],
            ),
            if (q.correctAnswer != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppTheme.violetGrad,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: AppTheme.glowShadow(AppTheme.violet,
                        intensity: 0.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(q.correctAnswer!,
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

// ── Index Badge ───────────────────────────────────────────────────
class _IndexBadge extends StatelessWidget {
  final int index;
  final LinearGradient gradient;
  const _IndexBadge(this.index, this.gradient);

  @override
  Widget build(BuildContext context) => Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('$index',
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      );
}
