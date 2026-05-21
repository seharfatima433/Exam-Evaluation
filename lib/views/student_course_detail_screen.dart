import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../services/student_service.dart';
import '../models/quiz_model.dart';
import 'student_quiz_screen.dart';

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

  // Attempts history
  List<Map<String, dynamic>> _attempts = [];
  bool _loadingAttempts = false;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Load attempts history from API ───────────────────────────
  Future<void> _loadAttempts() async {
    // Attempts only load after a quiz code is submitted
    // We'll refresh this after each quiz attempt
  }

  Future<void> _loadAttemptsForCode(String code) async {
    setState(() => _loadingAttempts = true);
    try {
      final result = await StudentService().fetchQuizAttemptsList(code);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        List<Map<String, dynamic>> list = [];
        if (data is List) {
          list = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is Map && data['attempts'] is List) {
          list = (data['attempts'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        setState(() {
          _attempts = list;
          _loadingAttempts = false;
        });
      } else {
        setState(() => _loadingAttempts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAttempts = false);
    }
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
    // Load attempts history in background
    _loadAttemptsForCode(code);

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => StudentQuizSolveScreen(
        quiz: fullQuiz,
        quizCode: code,
        studentId: widget.studentId,
        studentName: widget.studentName,
        endTime: endDt,
      ),
    ));

    // Refresh attempts after returning from quiz
    if (mounted) _loadAttemptsForCode(code);
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
        
        // Filter attempts specifically belonging to this student that are completed
        final studentCompletedAttempts = list.where((attempt) {
          if (attempt is Map) {
            final sId = attempt['student_id'] ?? attempt['user_id'] ?? attempt['student']?['id'];
            if (sId?.toString() == widget.studentId.toString()) {
              final status = (attempt['status'] ?? '').toString().toLowerCase();
              final hasScore = attempt['score'] != null || attempt['marks'] != null || attempt['obtained_marks'] != null;
              if (status == 'completed' || status == 'submitted' || hasScore) {
                return true;
              }
            }
          }
          return false;
        }).toList();
        
        if (studentCompletedAttempts.isNotEmpty) {
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
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You have already submitted this quiz. Showing your results.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
          backgroundColor: AppTheme.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentQuizSolveScreen(
              quiz: fullQuiz,
              quizCode: code,
              studentId: widget.studentId,
              studentName: widget.studentName,
              isReadOnlyResult: true,
              initialResultData: checkResult,
            ),
          ),
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
      if (quizDate.isNotEmpty && endTime.isNotEmpty) {
        endDt = _parseDateTime(quizDate, endTime);
        final startDt = _parseDateTime(quizDate, startTime);
        // Midnight crossing — end before start means next day
        if (startDt != null && endDt != null && endDt.isBefore(startDt)) {
          endDt = endDt.add(const Duration(days: 1));
        }
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
          // ── App Bar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 18, left: 16, right: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course.courseTitle,
                          style: GoogleFonts.outfit(fontSize: 16,
                              fontWeight: FontWeight.w800, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (widget.course.courseCode != null)
                        Text(widget.course.courseCode!,
                            style: GoogleFonts.outfit(fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
              ],
            ),
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

                  // ── Attempts History ──────────────────────────
                  if (_attempts.isNotEmpty || _loadingAttempts) ...[
                    Text('My Quiz Attempts',
                        style: GoogleFonts.outfit(fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkText2 : AppTheme.text2)),
                    const SizedBox(height: 10),

                    if (_loadingAttempts)
                      Center(child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, valueColor: AlwaysStoppedAnimation(accent)),
                      ))
                    else
                      ..._attempts.asMap().entries.map((e) =>
                          _AttemptRow(
                            attempt: e.value, 
                            index: e.key, 
                            accent: accent,
                            onTap: () {
                              _codeCtrl.text = e.value['quiz_code']?.toString() ?? '';
                              if (_codeCtrl.text.isNotEmpty) {
                                _joinQuiz();
                              }
                            },
                          )),
                  ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: error != null
                ? AppTheme.red.withValues(alpha: 0.40)
                : accent.withValues(alpha: 0.22),
            width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Accent top strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.45)]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.75)]),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.vpn_key_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Enter Quiz Code',
                          style: GoogleFonts.outfit(fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
                      Text('Get the code from your teacher',
                          style: GoogleFonts.outfit(fontSize: 11,
                              color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
                    ]),
                  ]),

                  const SizedBox(height: 20),

                  // Code input
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26, fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '· · · · · ·',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                        letterSpacing: 6,
                      ),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkInput : const Color(0xFFF5F7FF),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark ? AppTheme.darkBorder : AppTheme.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark ? AppTheme.darkBorder : AppTheme.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: accent, width: 2)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.red, width: 1.5)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.red, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      prefixIcon: Icon(Icons.tag_rounded, size: 18,
                          color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                    ),
                    onSubmitted: (_) => onJoin(),
                    onChanged: (_) => onChanged(),
                  ),

                  // Error message
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(error!,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: AppTheme.red,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Join button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: loading ? null : onJoin,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: loading ? null : LinearGradient(
                                colors: [accent, accent.withValues(alpha: 0.80)]),
                            color: loading
                                ? (isDark ? AppTheme.darkInput : const Color(0xFFF0F0F0))
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: loading ? null : [
                              BoxShadow(color: accent.withValues(alpha: 0.35),
                                  blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Center(
                            child: loading
                                ? SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(accent)))
                                : Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text('Start Quiz',
                                  style: GoogleFonts.outfit(fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info note
                  Row(children: [
                    Icon(Icons.schedule_rounded, size: 13,
                        color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You can only attempt the quiz during its scheduled time window.',
                        style: GoogleFonts.outfit(fontSize: 11,
                            color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]),
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