import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../services/student_service.dart';
import '../services/teacher_service.dart';
import '../models/quiz_model.dart';
import '../widgets/premium_app_bar.dart';
import 'student_quiz_screen.dart';
import 'student_results_screen.dart';
// ══════════════════════════════════════════════════════════════════
// STUDENT COURSE DETAIL SCREEN
// Shows quiz code entry box + attempts history
// ══════════════════════════════════════════════════════════════════
class StudentCourseDetailScreen extends StatefulWidget {
  final StudentCourse course;
  final int studentId;
  final String studentName;
  final Color accentColor;
  final String? rollNo;

  const StudentCourseDetailScreen({
    super.key,
    required this.course,
    required this.studentId,
    required this.studentName,
    required this.accentColor,
    this.rollNo,
  });

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState
    extends State<StudentCourseDetailScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Parse date+time safely (handles HH:MM and H:MM formats) ──
  DateTime? _parseDateTime(String date, String time) {
    try {
      // Normalize time — ensure HH:MM:SS format
      final parts = time.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      final s = parts.length > 2 ? int.parse(parts[2]) : 0;
      final dateParts = date.split('-');
      final year  = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day   = int.parse(dateParts[2]);
      return DateTime(year, month, day, h, m, s);
    } catch (_) {
      return DateTime.tryParse('$date $time');
    }
  }

  // ── Start actual quiz solve screen ───────────────────────────
  Future<void> _startQuizAttempt({
    required FullQuiz fullQuiz,
    required String code,
    required DateTime? endDt,
  }) async {
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => StudentQuizSolveScreen(
        quiz: fullQuiz,
        quizCode: code,
        studentId: widget.studentId,
        studentName: widget.studentName,
        endTime: endDt,
        courseId: widget.course.id,
      ),
    ));
  }

  // ── Show elegant preview bottom sheet ─────────────────────────
  void _showQuizPreviewSheet({
    required FullQuiz fullQuiz,
    required Map<String, dynamic> apiData,
    required String code,
    required DateTime? endDt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;

    // Safely extract student details from flat API response keys
    final studentName = apiData['user_name']?.toString() ??
        apiData['student_name']?.toString() ??
        apiData['name']?.toString() ??
        widget.studentName;

    final rollNo = apiData['roll_no']?.toString() ??
        apiData['roll_number']?.toString() ??
        widget.rollNo ??
        'N/A';

    final courseName = apiData['course_name']?.toString() ??
        widget.course.courseTitle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // The Unified Exam Ticket Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TOP HALF OF TICKET: Student Credentials
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.verified_user_rounded, color: accent, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'EXAM TICKET',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: accent,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accent.withOpacity(0.24), accent.withOpacity(0.08)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    studentName.trim().isNotEmpty
                                        ? studentName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                        : 'ST',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          size: 11,
                                          color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rollNo,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Course',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                                ),
                              ),
                              Text(
                                courseName,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // TICKET SEPARATOR (Dashed Ticket Cut line with left/right notches)
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(
                              right: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                              top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                              bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                            )
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Flex(
                                  direction: Axis.horizontal,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: List.generate(
                                    (constraints.constrainWidth() / 8).floor(),
                                    (index) => SizedBox(
                                      width: 4,
                                      height: 1.2,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            border: Border(
                              left: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                              top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                              bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                            )
                          ),
                        ),
                      ],
                    ),

                    // BOTTOM HALF OF TICKET: Quiz Specifications
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullQuiz.quizName.isNotEmpty ? fullQuiz.quizName : 'Quiz Assessment',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PreviewInfoRow(Icons.tag_rounded, 'Quiz Code: $code', color: Colors.blue),
                          const SizedBox(height: 10),
                          _PreviewInfoRow(Icons.calendar_today_rounded, 'Date: ${fullQuiz.quizDate}', color: Colors.purple),
                          const SizedBox(height: 10),
                          _PreviewInfoRow(
                            Icons.access_time_rounded,
                            'Duration Window: ${fullQuiz.startTime} - ${fullQuiz.endTime}',
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 10),
                          _PreviewInfoRow(
                            Icons.help_outline_rounded,
                            'Total Questions: ${fullQuiz.questions.length}',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 18),

                          // Built-in Warning Box inside ticket bottom
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.amber.withOpacity(0.20)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Important: Once started, the timer cannot be paused. Keep connection stable.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Dynamic Working Start Button integrated into ticket
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context); // Close sheet
                                  _startQuizAttempt(fullQuiz: fullQuiz, code: code, endDt: endDt);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [accent, accent.withOpacity(0.85)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'START EXAM NOW',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0, duration: 550.ms, curve: Curves.easeOutBack),
            ],
          ),
        );
      },
    );
  }

  void _showAlreadyAttemptedSheet({
    required FullQuiz fullQuiz,
    required String code,
    required Map<String, dynamic>? resultData,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;
    
    final isUnlocked = resultData != null && resultData['status'] == true;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? AppTheme.greenDark.withOpacity(0.12)
                      : AppTheme.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.verified_user_rounded : Icons.lock_clock_rounded,
                  color: isUnlocked ? AppTheme.greenDark : AppTheme.amber,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                isUnlocked ? 'Quiz Results Available!' : 'Quiz Attempt Submitted',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                isUnlocked 
                    ? 'You have already attempted this quiz. You can view your detailed performance below.'
                    : 'You have completed this quiz early. The results will unlock once the quiz timer ends.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              
              // Score box or Unlock window box
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.greenDark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.greenDark.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Percentage:',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText2 : AppTheme.text2,
                        ),
                      ),
                      Text(
                        '${resultData['percentage'] ?? resultData['data']?['percentage'] ?? '—'}%',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.greenDark,
                        ),
                      ),
                    ],
                  ),
                )
              else if (resultData != null && resultData['unlock_time'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'RELEASE TIME',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.amber,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultData['unlock_time']?.toString() ?? 'After quiz ends',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                        ),
                      ),
                    ],
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkText2 : AppTheme.text2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isUnlocked ? AppTheme.greenGrad : AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.glowShadow(isUnlocked ? AppTheme.greenDark : AppTheme.primary),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context); // Close sheet
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => StudentQuizSolveScreen(
                                  quiz: fullQuiz,
                                  quizCode: code,
                                  studentId: widget.studentId,
                                  studentName: widget.studentName,
                                  isReadOnlyResult: true,
                                  initialResultData: resultData,
                                  courseId: widget.course.id,
                                ),
                              ));
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isUnlocked ? Icons.analytics_rounded : Icons.lock_open_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUnlocked ? 'VIEW PERFORMANCE' : 'CHECK STATUS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Join quiz by code ────────────────────────────────────────
  Future<void> _joinQuiz() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the quiz code');
      return;
    }
    if (code.length < 4) {
      setState(() => _error = 'Invalid quiz code');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; });

    final result = await StudentService().loadQuizAttempt(
      quizCode: code,
      studentId: widget.studentId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final fullQuiz = FullQuiz.fromJson(data);

      // ── COURSE VALIDATION: quiz must belong to THIS course ──────
      // Prevents a student from using a different course's quiz code here
      int courseIdVal = fullQuiz.courseId;
      if (courseIdVal == 0) {
        // Fallback: Fetch quiz detail by code to verify course ID
        final quizDetails = await TeacherService().fetchQuizByCode(code);
        if (quizDetails['success'] == true && quizDetails['data'] is FullQuiz) {
          courseIdVal = (quizDetails['data'] as FullQuiz).courseId;
        }
      }

      if (courseIdVal != 0 && courseIdVal != widget.course.id) {
        setState(() {
          _loading = false;
          _error = 'This quiz code belongs to a different course. '  
                   'Please enter the code for ${widget.course.courseTitle}.';
        });
        return;
      }

      // Check if student has already successfully submitted this quiz
      final prefs = await SharedPreferences.getInstance();
      final localSubmitted = prefs.getBool('quiz_submitted_${widget.studentId}_${fullQuiz.quizId}') ?? false;
      
      // Call the attempts list API to see if a completed attempt already exists on the server
      final attemptsResult = await StudentService().fetchQuizAttemptsList(code);
      bool serverSubmitted = false;
      if (attemptsResult['success'] == true) {
        final data = attemptsResult['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['attempts'] is List) {
          list = data['attempts'];
        }
        
        // Filter attempts specifically belonging to this student
        // Block re-entry for: submitted, abandoned, started (already entered the quiz)
        final studentBlockedAttempts = list.where((attempt) {
          if (attempt is Map) {
            final sId = attempt['student_id'] ?? attempt['user_id'] ?? attempt['student']?['id'];
            if (sId?.toString() == widget.studentId.toString()) {
              final status = (attempt['status'] ?? '').toString().toLowerCase();
              final hasScore = attempt['score'] != null || attempt['marks'] != null || attempt['obtained_marks'] != null;
              // Block if submitted or abandoned (explicitly left without submitting).
              // NOTE: 'started' is NOT blocked — the POST /api/quiz-attempt itself
              // sets status='started', so blocking it would prevent first-time entry.
              if (status == 'submitted' || status == 'completed' ||
                  status == 'abandoned' || hasScore) {
                return true;
              }
            }
          }
          return false;
        }).toList();
        
        if (studentBlockedAttempts.isNotEmpty) {
          serverSubmitted = true;
        }
      }
      
      final localResultKey = 'quiz_result_${fullQuiz.quizId}_${widget.studentId}';
      final localResultStr = prefs.getString(localResultKey);
      Map<String, dynamic>? checkResult;
      
      if (localResultStr != null) {
        try {
          checkResult = jsonDecode(localResultStr);
        } catch (_) {}
      }
      
      if (checkResult == null || checkResult['status'] != true) {
        checkResult = await StudentService().fetchQuizResult(fullQuiz.quizId, widget.studentId);
        if (checkResult['status'] == true) {
          await prefs.setString(localResultKey, jsonEncode(checkResult));
        }
      }
      
      final apiUnlocked = checkResult['status'] == true;
      
      if (localSubmitted || serverSubmitted || apiUnlocked) {
        setState(() {
          _loading = false;
        });
        _showAlreadyAttemptedSheet(
          fullQuiz: fullQuiz,
          code: code,
          resultData: checkResult,
        );
        return;
      }

      // Call the requested GET api/exam-quiz/{quiz_id}/{student_id} to fetch student data
      final previewResult = await StudentService().fetchExamQuizInfo(fullQuiz.quizId, widget.studentId);

      if (!mounted) return;
      setState(() => _loading = false);

      final Map<String, dynamic> apiData = previewResult['success'] == true 
          ? previewResult['data'] as Map<String, dynamic>
          : {};

      // End time for in-quiz countdown timer
      final quizDate = data['quiz_date']?.toString() ?? '';
      final endTime  = data['end_time']?.toString() ?? '';
      final startTime = data['start_time']?.toString() ?? '';
      DateTime? endDt;
      DateTime? startDt;
      if (quizDate.isNotEmpty && endTime.isNotEmpty) {
        endDt = _parseDateTime(quizDate, endTime);
        startDt = _parseDateTime(quizDate, startTime);
        // Midnight crossing — end before start means next day
        if (startDt != null && endDt != null && endDt.isBefore(startDt)) {
          endDt = endDt.add(const Duration(days: 1));
        }
      }

      // ── STRICT AUTHENTICATION (TIME CHECKS) ──
      final now = DateTime.now();
      if (endDt != null && now.isAfter(endDt)) {
        setState(() {
          _loading = false;
          _error = 'Time over! The scheduled time for this quiz has ended.';
        });
        return;
      }
      if (startDt != null && now.isBefore(startDt)) {
        setState(() {
          _loading = false;
          _error = 'Quiz has not started yet. Please wait until scheduled time.';
        });
        return;
      }

      // Show beautiful Bottom Sheet with Student Info & Start Button
      _showQuizPreviewSheet(
        fullQuiz: fullQuiz,
        apiData: apiData,
        code: code,
        endDt: endDt,
      );

    } else {
      setState(() => _loading = false);
      final quizStatus = (result['quizStatus'] ?? '').toString().toLowerCase();
      String msg;
      if (quizStatus == 'locked' || quizStatus == 'not_started') {
        msg = 'Quiz has not started yet. Please wait for the scheduled time.';
      } else if (quizStatus == 'expired' || quizStatus == 'ended') {
        msg = 'Quiz time has ended. You can no longer attempt this quiz.';
      } else {
        msg = result['message'] as String? ?? 'Quiz not found. Check the code and try again.';
      }
      setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.course.courseTitle,
            subtitle: widget.course.courseCode ?? 'Course Details',
            showBack: true,
          ),

          // ── Scrollable body ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Quiz Code Entry Card ──────────────────────
                  _CodeEntryCard(
                    accent: accent,
                    controller: _codeCtrl,
                    loading: _loading,
                    error: _error,
                    onJoin: _joinQuiz,
                    onChanged: () { if (_error != null) setState(() => _error = null); },
                  ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 24),

                  // ── Past Results Button ──────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : accent.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => StudentResultsScreen(
                              studentId: widget.studentId,
                              studentName: widget.studentName,
                              courseId: widget.course.id, // Pass course ID!
                            ),
                          ));
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              // Glass-styled history icon container
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.16),
                                      accent.withValues(alpha: 0.04),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.22),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View Past Results',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Check scores, keys, & performance analysis',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: accent,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CODE ENTRY CARD
// ══════════════════════════════════════════════════════════════════
class _CodeEntryCard extends StatelessWidget {
  final Color accent;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onJoin;
  final VoidCallback onChanged;

  const _CodeEntryCard({
    required this.accent,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onJoin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: error != null
              ? AppTheme.red.withValues(alpha: 0.45)
              : accent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: error != null
                ? AppTheme.red.withValues(alpha: 0.08)
                : accent.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Ambient Top Gradient Accent Line
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.7),
                    accent.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Modern Glassmorphic Icon Container
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.70)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Enter Quiz Code',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Secure Lock Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 9, color: accent),
                                      const SizedBox(width: 3),
                                      Text(
                                        'SECURE',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: accent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Get the unique credentials from your teacher',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // High-tech Pin Entry TextField
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      hintText: '······',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                        letterSpacing: 10,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkInput.withValues(alpha: 0.5)
                          : const Color(0xFFF3F2FD),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          Icons.tag_rounded,
                          size: 20,
                          color: isDark ? AppTheme.darkText4 : AppTheme.text3,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    onSubmitted: (_) => onJoin(),
                    onChanged: (_) => onChanged(),
                  ),

                  // Error message overlay
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.red.withValues(alpha: 0.22), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppTheme.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().shake(duration: 400.ms, curve: Curves.easeInOut),
                  ],

                  const SizedBox(height: 18),

                  // Start Quiz Shiny Gradient Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: loading
                            ? null
                            : LinearGradient(
                                colors: [accent, accent.withValues(alpha: 0.80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: loading
                            ? (isDark ? AppTheme.darkInput : const Color(0xFFF0F0F0))
                            : null,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: loading
                            ? null
                            : [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          onTap: loading ? null : onJoin,
                          borderRadius: BorderRadius.circular(15),
                          child: Center(
                            child: loading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(accent),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Start Quiz',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),

                                    ],
                                  ),
                          ),
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: false))
                        .shimmer(
                          duration: 2500.ms,
                          color: Colors.white.withValues(alpha: 0.24),
                          size: 0.35,
                        ),
                  ),

                  const SizedBox(height: 14),

                  // Info note
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'You can only attempt the quiz during its scheduled time window.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
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

// ══════════════════════════════════════════════════════════════════
// ATTEMPT ROW — shows each quiz attempt history
// ══════════════════════════════════════════════════════════════════
class _AttemptRow extends StatelessWidget {
  final Map<String, dynamic> attempt;
  final int index;
  final Color accent;
  final VoidCallback? onTap;

  const _AttemptRow({
    required this.attempt,
    required this.index,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizName  = attempt['quiz_name']?.toString() ?? attempt['quiz_code']?.toString() ?? 'Quiz ${index + 1}';
    final score     = attempt['score']?.toString() ?? attempt['marks']?.toString() ?? '—';
    final total     = attempt['total']?.toString() ?? attempt['total_marks']?.toString() ?? '';
    final status    = attempt['status']?.toString() ?? 'completed';
    final attemptNo = attempt['attempt_number']?.toString() ?? attempt['attempt_no']?.toString() ?? '${index + 1}';
    final date      = attempt['created_at']?.toString() ?? attempt['attempted_at']?.toString() ?? '';

    final isPass = status.toLowerCase() == 'pass' || status.toLowerCase() == 'passed';
    final statusColor = isPass ? AppTheme.greenDark : AppTheme.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
        // Attempt number badge
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.75)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('#$attemptNo',
                style: GoogleFonts.outfit(fontSize: 11,
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(quizName,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (date.isNotEmpty)
              Text(date.length > 10 ? date.substring(0, 10) : date,
                  style: GoogleFonts.outfit(fontSize: 11,
                      color: isDark ? AppTheme.darkText4 : AppTheme.text4)),
          ]),
        ),
        // Score
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(total.isNotEmpty ? '$score / $total' : score,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800,
                  color: accent)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 9,
                    fontWeight: FontWeight.w800, color: statusColor,
                    letterSpacing: 0.3)),
          ),
        ]),
      ]),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

// ── PREVIEW INFO ROW WIDGET ───────────────────────────────────────
class _PreviewInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _PreviewInfoRow(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = color ?? AppTheme.primary;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primary.withOpacity(isDark ? 0.16 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 14, color: primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText2 : AppTheme.text2,
            ),
          ),
        ),
      ],
    );
  }
}