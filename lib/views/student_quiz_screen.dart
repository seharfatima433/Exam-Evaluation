import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../services/student_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

// ══════════════════════════════════════════════════════════════════
// STUDENT QUIZ ENTRY SCREEN
// Active quiz ke liye code confirm karo, phir quiz load karo
// ══════════════════════════════════════════════════════════════════
class StudentQuizEntryScreen extends StatefulWidget {
  final StudentQuiz quiz;
  final int studentId;
  final String studentName;

  const StudentQuizEntryScreen({
    super.key,
    required this.quiz,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentQuizEntryScreen> createState() => _StudentQuizEntryScreenState();
}

class _StudentQuizEntryScreenState extends State<StudentQuizEntryScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill if we already know the code
    if (widget.quiz.quizCode.isNotEmpty) {
      _codeCtrl.text = widget.quiz.quizCode;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the quiz code');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await StudentService().loadQuizAttempt(
      quizCode: code,
      studentId: widget.studentId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      final fullQuiz = FullQuiz.fromJson(result['data'] as Map<String, dynamic>);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizSolveScreen(
            quiz: fullQuiz,
            quizCode: code,
            studentId: widget.studentId,
            studentName: widget.studentName,
            endTime: widget.quiz.endDateTime,
          ),
        ),
      );
    } else {
      final status = result['quizStatus'] as String? ?? 'unknown';
      setState(() {
        if (status == 'expired') {
          _error = 'This quiz has expired. You can no longer access it.';
        } else if (status == 'locked') {
          _error = 'Quiz is locked. Please wait for the scheduled start time.';
        } else {
          _error = result['message'] as String? ?? 'Quiz could not be loaded.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.quiz.quizName.isNotEmpty
                ? widget.quiz.quizName
                : 'Enter Quiz',
            subtitle: 'Code: ${widget.quiz.quizCode}',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Icon ──────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGrad,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.glowShadow(AppTheme.greenDark),
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 38),
                  )
                      .animate()
                      .scaleXY(
                      begin: 0.6,
                      end: 1.0,
                      duration: 550.ms,
                      curve: Curves.elasticOut)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  Text(
                    'Confirm Quiz',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      letterSpacing: -0.5,
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 6),

                  Text(
                    'Please enter the quiz code aur join karein',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                    ),
                  ).animate(delay: 160.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // ── Quiz info card ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greenDark.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.greenDark.withOpacity(0.25),
                          width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 14, color: AppTheme.greenDark),
                            const SizedBox(width: 6),
                            Text(
                              'Quiz Details',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.greenDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                            Icons.calendar_today_rounded, widget.quiz.quizDate),
                        const SizedBox(height: 5),
                        _InfoRow(Icons.access_time_rounded,
                            '${widget.quiz.startTime} – ${widget.quiz.endTime}'),
                        const SizedBox(height: 5),
                        _InfoRow(Icons.quiz_outlined,
                            '${widget.quiz.totalQuestions} Questions'),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // ── Code Input ─────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1),
                      boxShadow: AppTheme.softShadow,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz Code',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                            isDark ? AppTheme.darkText3 : AppTheme.text3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color:
                            isDark ? AppTheme.darkText1 : AppTheme.text1,
                            letterSpacing: 6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'CODE',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color:
                              isDark ? AppTheme.darkText4 : AppTheme.text4,
                              letterSpacing: 6,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkInput
                                : AppTheme.primaryBg.withOpacity(0.5),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.greenDark, width: 2)),
                            errorText: _error,
                            errorStyle: GoogleFonts.outfit(
                                fontSize: 11, color: AppTheme.red),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            prefixIcon: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                              child: Icon(Icons.tag_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppTheme.darkText4
                                      : AppTheme.text4),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                                minWidth: 50, minHeight: 50),
                          ),
                          onSubmitted: (_) => _join(),
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() => _error = null);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Join button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: _loading ? null : _join,
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient:
                                  _loading ? null : AppTheme.greenGrad,
                                  color: _loading
                                      ? (isDark
                                      ? AppTheme.darkInput
                                      : AppTheme.bg)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _loading
                                      ? null
                                      : AppTheme.glowShadow(AppTheme.greenDark),
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                      AlwaysStoppedAnimation(
                                          AppTheme.greenDark),
                                    ),
                                  )
                                      : Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.play_circle_rounded,
                                          color: Colors.white,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Start Quiz',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
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
                      ],
                    ),
                  ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.greenDark.withOpacity(0.7)),
        const SizedBox(width: 7),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkText2
                : AppTheme.text2,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PROCTORING SERVICE
// ══════════════════════════════════════════════════════════════════
class ProctoringService {
  static const String baseUrl = 'http://localhost:5000';
  
  // Start exam proctoring
  static Future<bool> startExam({
    required String studentId,
    required String studentName,
    required String courseName,
    required String quizCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start-exam'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'student_name': studentName,
          'course_name': courseName,
          'quiz_code': quizCode,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
    } catch (e) {
      debugPrint('Error starting proctoring: $e');
    }
    return false;
  }
  
  // Stop exam proctoring
  static Future<bool> stopExam() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stop-exam'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
    } catch (e) {
      debugPrint('Error stopping proctoring: $e');
    }
    return false;
  }
  
  // Get proctoring status
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting status: $e');
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════
// STUDENT QUIZ SOLVE SCREEN
// Student quiz solve karta hai — MCQ select, short/fill type karein
// ══════════════════════════════════════════════════════════════════
class StudentQuizSolveScreen extends StatefulWidget {
  final FullQuiz quiz;
  final String quizCode;
  final int studentId;
  final String studentName;
  final DateTime? endTime; // Quiz ka end time (live timer)
  final bool isReadOnlyResult;
  final Map<String, dynamic>? initialResultData;

  const StudentQuizSolveScreen({
    super.key,
    required this.quiz,
    required this.quizCode,
    required this.studentId,
    required this.studentName,
    this.endTime,
    this.isReadOnlyResult = false,
    this.initialResultData,
  });

  @override
  State<StudentQuizSolveScreen> createState() => _StudentQuizSolveScreenState();
}

class _StudentQuizSolveScreenState extends State<StudentQuizSolveScreen> {
  // ── State ────────────────────────────────────────────────────────
  final Map<int, String> _answers = {}; // questionId -> selected answer
  final Map<int, TextEditingController> _textControllers = {};
  bool _submitting = false;
  bool _submitted = false;
  int _score = 0;
  bool _loadingResults = false;
  Map<String, dynamic>? _resultData;

  // ── Timer ────────────────────────────────────────────────────────
  Timer? _timer;
  Duration _remaining = const Duration(hours: 1);

  List<QuizQuestion> get _questions => widget.quiz.questions;

  void _startProctoring() async {
    if (widget.isReadOnlyResult) return;
    final started = await ProctoringService.startExam(
      studentId: widget.studentId.toString(),
      studentName: widget.studentName,
      courseName: widget.quiz.quizName,
      quizCode: widget.quizCode,
    );
    
    if (started) {
      debugPrint('Proctoring started successfully');
    }
  }

  void _stopProctoring() async {
    if (widget.isReadOnlyResult) return;
    await ProctoringService.stopExam();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnlyResult) {
      _submitted = true;
      _resultData = widget.initialResultData;
      // Setup text controllers for short/fill questions
      for (final q in _questions) {
        if (q.questionId != null &&
            (q.type == 'short' || q.type == 'fill')) {
          _textControllers[q.questionId!] = TextEditingController();
        }
      }
      _loadReadOnlyAnswers();
    } else {
      _initQuiz();
    }
  }

  Future<void> _loadReadOnlyAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyAnswers = 'quiz_answers_${widget.studentId}_${widget.quiz.quizId}';
      final savedAnswersJson = prefs.getString(keyAnswers);
      if (savedAnswersJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(savedAnswersJson);
        setState(() {
          decoded.forEach((key, val) {
            final qId = int.tryParse(key);
            if (qId != null) {
              _answers[qId] = val.toString();
              if (_textControllers.containsKey(qId)) {
                _textControllers[qId]!.text = val.toString();
              }
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading read only answers: $e');
    }
  }

  Future<void> _initQuiz() async {
    // Setup text controllers for short/fill questions
    for (final q in _questions) {
      if (q.questionId != null &&
          (q.type == 'short' || q.type == 'fill')) {
        _textControllers[q.questionId!] = TextEditingController();
      }
    }

    // Load progress from draft (if any)
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyAnswers = 'quiz_answers_${widget.studentId}_${widget.quiz.quizId}';
      final keyTime = 'quiz_time_${widget.studentId}_${widget.quiz.quizId}';
      
      final savedAnswersJson = prefs.getString(keyAnswers);
      final savedTimeSeconds = prefs.getInt(keyTime);

      if (savedAnswersJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(savedAnswersJson);
        decoded.forEach((key, val) {
          final qId = int.tryParse(key);
          if (qId != null) {
            _answers[qId] = val.toString();
            if (_textControllers.containsKey(qId)) {
              _textControllers[qId]!.text = val.toString();
            }
          }
        });
      }

      if (savedTimeSeconds != null && savedTimeSeconds > 0) {
        _remaining = Duration(seconds: savedTimeSeconds);
      } else {
        final end = widget.endTime ?? DateTime.now().add(const Duration(hours: 1));
        final diff = end.difference(DateTime.now());
        _remaining = diff.isNegative ? Duration.zero : diff;
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
      final end = widget.endTime ?? DateTime.now().add(const Duration(hours: 1));
      final diff = end.difference(DateTime.now());
      _remaining = diff.isNegative ? Duration.zero : diff;
    }

    // Listeners for short/fill text fields to save draft progress in real-time
    _textControllers.forEach((qId, ctrl) {
      ctrl.addListener(() {
        _answers[qId] = ctrl.text.trim();
        _saveDraftProgress();
      });
    });

    _startTimer();
    _startProctoring();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
          _saveDraftProgress();
        } else {
          _remaining = Duration.zero;
        }
      });
      if (_remaining == Duration.zero && !_submitted) {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  Future<void> _saveDraftProgress() async {
    if (widget.isReadOnlyResult || _submitted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyAnswers = 'quiz_answers_${widget.studentId}_${widget.quiz.quizId}';
      final keyTime = 'quiz_time_${widget.studentId}_${widget.quiz.quizId}';

      final stringAnswers = _answers.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(keyAnswers, jsonEncode(stringAnswers));
      await prefs.setInt(keyTime, _remaining.inSeconds);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _clearDraftProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyAnswers = 'quiz_answers_${widget.studentId}_${widget.quiz.quizId}';
      final keyTime = 'quiz_time_${widget.studentId}_${widget.quiz.quizId}';
      await prefs.remove(keyAnswers);
      await prefs.remove(keyTime);
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  Future<void> _markQuizAsSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keySubmitted = 'quiz_submitted_${widget.studentId}_${widget.quiz.quizId}';
      await prefs.setBool(keySubmitted, true);
    } catch (e) {
      debugPrint('Error marking quiz submitted: $e');
    }
  }

  void _autoSubmit() {
    _snack('Time is up! Submitting your quiz…',
        isError: false);
    _submit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _stopProctoring(); // Stop proctoring when quiz ends
    super.dispose();
  }

  // ── Answer helpers ───────────────────────────────────────────────
  void _selectMcq(int questionId, String answer) {
    HapticFeedback.selectionClick();
    setState(() => _answers[questionId] = answer);
    _saveDraftProgress();
  }

  // ── Answered count ───────────────────────────────────────────────
  int get _answeredCount {
    int count = 0;
    for (final q in _questions) {
      if (q.questionId == null) continue;
      if (q.type == 'mcq' && _answers.containsKey(q.questionId)) {
        count++;
      } else if ((q.type == 'short' || q.type == 'fill') &&
          (_textControllers[q.questionId]?.text.trim().isNotEmpty ?? false)) {
        count++;
      }
    }
    return count;
  }

  // ── Calculate score (MCQ) ────────────────────────────────────────
  int _calcScore() {
    int score = 0;
    for (final q in _questions) {
      if (q.type != 'mcq' || q.questionId == null) continue;
      final selected = _answers[q.questionId];
      if (selected == null) continue;
      final correct = _resolveCorrect(q);
      if (selected == correct) score++;
    }
    return score;
  }

  String _resolveCorrect(QuizQuestion q) {
    final ca = q.correctAnswer ?? '';
    if (ca.length == 1 && 'abcd'.contains(ca.toLowerCase())) {
      final opts = [q.optionA, q.optionB, q.optionC, q.optionD];
      return opts['abcd'.indexOf(ca.toLowerCase())] ?? ca;
    }
    return ca;
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_submitting || _submitted) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    // Build payload mapping question_id -> answer letter (MCQ) or text
    final Map<String, String> answersMap = {};
    for (final q in _questions) {
      if (q.questionId == null) continue;
      if (q.type == 'mcq') {
        final selectedVal = _answers[q.questionId];
        if (selectedVal != null) {
          if (selectedVal == q.optionA) {
            answersMap[q.questionId.toString()] = 'A';
          } else if (selectedVal == q.optionB) {
            answersMap[q.questionId.toString()] = 'B';
          } else if (selectedVal == q.optionC) {
            answersMap[q.questionId.toString()] = 'C';
          } else if (selectedVal == q.optionD) {
            answersMap[q.questionId.toString()] = 'D';
          }
        }
      } else {
        final ctrl = _textControllers[q.questionId];
        if (ctrl != null && ctrl.text.trim().isNotEmpty) {
          answersMap[q.questionId.toString()] = ctrl.text.trim();
        }
      }
    }

    final score = _calcScore();

    final result = await StudentService().submitQuizNew(
      quizId: widget.quiz.quizId,
      studentId: widget.studentId,
      answers: answersMap,
    );

    if (!mounted) return;

    if (result['success'] == true || result['message']?.toString().contains('already') == true) {
      await _clearDraftProgress();
      await _markQuizAsSubmitted();
      _snack('Quiz successfully submit ho gaya!', isError: false);
      _fetchAndShowResults();
    } else {
      _snack(result['message'] ?? 'Quiz submission failed', isError: true);
      setState(() {
        _submitting = false;
      });
    }
  }

  Future<void> _fetchAndShowResults() async {
    setState(() {
      _loadingResults = true;
      _submitting = false;
      _submitted = true;
    });
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final localKey = 'quiz_result_${widget.quiz.quizId}_${widget.studentId}';
    
    // Check local storage first
    final localDataStr = prefs.getString(localKey);
    if (localDataStr != null) {
      try {
        final localData = jsonDecode(localDataStr);
        if (localData['status'] == true) {
          if (!mounted) return;
          setState(() {
            _resultData = localData;
            _loadingResults = false;
            _score = _calcScore();
          });
          return;
        }
      } catch (e) {
        debugPrint('Error parsing local result: $e');
      }
    }

    // Fetch from API if not found locally or if status is not true
    final data = await StudentService().fetchQuizResult(
      widget.quiz.quizId,
      widget.studentId,
    );

    // If result is unlocked successfully, save to local storage
    if (data['status'] == true) {
      await prefs.setString(localKey, jsonEncode(data));
    }

    if (!mounted) return;
    setState(() {
      _resultData = data;
      _loadingResults = false;
      _score = _calcScore();
    });
  }

  int _mcqCount() =>
      _questions.where((q) => q.type == 'mcq').length;

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
      Text(msg, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
      backgroundColor: isError ? AppTheme.red : AppTheme.greenDark,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  String _fmtTimer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remaining.inMinutes <= 2) return AppTheme.red;
    if (_remaining.inMinutes <= 10) return AppTheme.amber;
    return AppTheme.greenDark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Custom App Bar with timer ──────────────────────────
          _QuizAppBar(
            quizName: widget.quiz.quizName.isNotEmpty
                ? widget.quiz.quizName
                : widget.quizCode,
            timer: _fmtTimer(_remaining),
            timerColor: _timerColor,
            answeredCount: _answeredCount,
            totalCount: _questions.length,
            submitted: _submitted,
            studentName: widget.studentName,
          ),

          // ── Progress bar ─────────────────────────────────────
          LinearProgressIndicator(
            value: _questions.isEmpty
                ? 0
                : _answeredCount / _questions.length,
            backgroundColor:
            isDark ? AppTheme.darkBorder : AppTheme.border,
            valueColor: AlwaysStoppedAnimation(
                _submitted ? AppTheme.greenDark : AppTheme.primary),
            minHeight: 3,
          ),

          // ── Questions list ────────────────────────────────────
          Expanded(
            child: _submitted
                ? _ResultView(
                    score: _score,
                    total: _mcqCount(),
                    totalQuestions: _questions.length,
                    studentName: widget.studentName,
                    onBack: () => Navigator.pop(context),
                    resultData: _resultData,
                    loading: _loadingResults,
                    onRefresh: _fetchAndShowResults,
                  )
                : _questions.isEmpty
                ? _EmptyQuiz()
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _questions.length,
              itemBuilder: (context, i) {
                final q = _questions[i];
                return _buildQuestionCard(q, i + 1, isDark);
              },
            ),
          ),
        ],
      ),

      // ── Submit FAB ────────────────────────────────────────────
      floatingActionButton: _submitted
          ? null
          : Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _submitting ? null : () => _confirmSubmit(),
          backgroundColor: _submitting
              ? (isDark ? AppTheme.darkSurface : AppTheme.bg)
              : AppTheme.greenDark,
          elevation: 4,
          icon: _submitting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                AlwaysStoppedAnimation(AppTheme.greenDark)),
          )
              : const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 20),
          label: Text(
            _submitting
                ? 'Submitting…'
                : 'Submit Quiz ($_answeredCount/${_questions.length})',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _submitting ? AppTheme.greenDark : Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _confirmSubmit() {
    final unanswered = _questions.length - _answeredCount;
    if (unanswered > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkSurface
              : AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Submit?',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Text(
            '$unanswered question${unanswered > 1 ? 's' : ''} still unanswered. Submit anyway?',
            style: GoogleFonts.outfit(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Wait',
                  style: GoogleFonts.outfit(
                      color: AppTheme.text3,
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submit();
              },
              child: Text('Submit',
                  style: GoogleFonts.outfit(
                      color: AppTheme.greenDark,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      _submit();
    }
  }

  Widget _buildQuestionCard(QuizQuestion q, int idx, bool isDark) {
    switch (q.type) {
      case 'mcq':
        return _StudentMcqCard(
          q: q,
          index: idx,
          selectedAnswer: q.questionId != null ? _answers[q.questionId] : null,
          onSelect: q.questionId != null
              ? (ans) => _selectMcq(q.questionId!, ans)
              : (_) {},
          submitted: _submitted,
        );
      case 'short':
        return _StudentTextCard(
          q: q,
          index: idx,
          controller: q.questionId != null
              ? _textControllers[q.questionId!]
              : null,
          label: 'Write your answer',
          maxLines: 3,
          submitted: _submitted,
          gradient: AppTheme.greenGrad,
        );
      case 'fill':
        return _StudentTextCard(
          q: q,
          index: idx,
          controller: q.questionId != null
              ? _textControllers[q.questionId!]
              : null,
          label: 'Fill in the blank',
          maxLines: 1,
          submitted: _submitted,
          gradient: AppTheme.violetGrad,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// QUIZ APP BAR  — with live countdown
// ══════════════════════════════════════════════════════════════════
class _QuizAppBar extends StatelessWidget {
  final String quizName;
  final String timer;
  final Color timerColor;
  final int answeredCount;
  final int totalCount;
  final bool submitted;
  final String? studentName;

  const _QuizAppBar({
    required this.quizName,
    required this.timer,
    required this.timerColor,
    required this.answeredCount,
    required this.totalCount,
    required this.submitted,
    this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.heroGrad),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      submitted
                          ? 'Submitted ✓'
                          : '$answeredCount / $totalCount answered',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                    if (studentName != null && studentName!.isNotEmpty) ...[
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: const BoxDecoration(
                          color: Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          studentName!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Timer box
          if (!submitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: timerColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: timerColor.withOpacity(0.40), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    timer,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          if (submitted)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.greenDark.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Done',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

// ══════════════════════════════════════════════════════════════════
// STUDENT MCQ CARD  — student answer select kar sakta hai
// ══════════════════════════════════════════════════════════════════
class _StudentMcqCard extends StatelessWidget {
  final QuizQuestion q;
  final int index;
  final String? selectedAnswer;
  final ValueChanged<String> onSelect;
  final bool submitted;

  const _StudentMcqCard({
    required this.q,
    required this.index,
    required this.selectedAnswer,
    required this.onSelect,
    required this.submitted,
  });

  String _correct() {
    final ca = q.correctAnswer ?? '';
    if (ca.length == 1 && 'abcd'.contains(ca.toLowerCase())) {
      final opts = [q.optionA, q.optionB, q.optionC, q.optionD];
      return opts['abcd'.indexOf(ca.toLowerCase())] ?? ca;
    }
    return ca;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final correctAns = _correct();
    final opts = [
      ('A', q.optionA),
      ('B', q.optionB),
      ('C', q.optionC),
      ('D', q.optionD),
    ].where((o) => o.$2 != null).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedAnswer != null
              ? AppTheme.primary.withOpacity(0.30)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
          width: selectedAnswer != null ? 1.5 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primary.withOpacity(0.07)
                  : AppTheme.primaryBg.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              border: Border(
                  bottom: BorderSide(
                      color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                      width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index, AppTheme.primaryGrad),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    q.question,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: opts.map((o) {
                final optText = o.$2!;
                final isSelected = selectedAnswer == optText;
                final isCorrect = submitted && optText == correctAns;
                final isWrong =
                    submitted && isSelected && optText != correctAns;

                Color bg, borderColor;
                Color textColor =
                isDark ? AppTheme.darkText2 : AppTheme.text2;

                if (isCorrect) {
                  bg = isDark
                      ? AppTheme.green.withOpacity(0.12)
                      : AppTheme.greenBg;
                  borderColor = AppTheme.green.withOpacity(0.40);
                  textColor = AppTheme.greenDark;
                } else if (isWrong) {
                  bg = isDark
                      ? AppTheme.red.withOpacity(0.10)
                      : AppTheme.redBg;
                  borderColor = AppTheme.red.withOpacity(0.35);
                  textColor = AppTheme.red;
                } else if (isSelected) {
                  bg = isDark
                      ? AppTheme.primary.withOpacity(0.10)
                      : AppTheme.primaryBg;
                  borderColor = AppTheme.primary.withOpacity(0.45);
                  textColor = AppTheme.primary;
                } else {
                  bg = isDark ? AppTheme.darkInput : AppTheme.surfaceAlt;
                  borderColor =
                  isDark ? AppTheme.darkBorder : AppTheme.border;
                }

                return GestureDetector(
                  onTap: submitted ? null : () => onSelect(optText),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        // Letter badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: isCorrect
                                ? AppTheme.greenGrad
                                : isWrong
                                ? null
                                : isSelected
                                ? AppTheme.primaryGrad
                                : null,
                            color: isWrong
                                ? AppTheme.red
                                : (!isCorrect && !isSelected)
                                ? (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.border)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              o.$1,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: (isCorrect || isWrong || isSelected)
                                    ? Colors.white
                                    : AppTheme.text4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            optText,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: isSelected || isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
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
                        if (isWrong)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppTheme.red,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 10, color: Colors.white),
                          ),
                      ],
                    ),
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

// ══════════════════════════════════════════════════════════════════
// STUDENT TEXT CARD  — short / fill type questions
// ══════════════════════════════════════════════════════════════════
class _StudentTextCard extends StatelessWidget {
  final QuizQuestion q;
  final int index;
  final TextEditingController? controller;
  final String label;
  final int maxLines;
  final bool submitted;
  final LinearGradient gradient;

  const _StudentTextCard({
    required this.q,
    required this.index,
    required this.controller,
    required this.label,
    required this.maxLines,
    required this.submitted,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexBadge(index, gradient),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q.question,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Text input
          if (controller != null && !submitted)
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppTheme.darkText1 : AppTheme.text1,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkText4 : AppTheme.text4,
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkInput : AppTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

          // Submitted: show answer
          if (submitted && controller != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.20), width: 1),
              ),
              child: Text(
                controller!.text.trim().isEmpty
                    ? '(No answer provided)'
                    : controller!.text.trim(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: controller!.text.trim().isEmpty
                      ? AppTheme.text4
                      : (isDark ? AppTheme.darkText1 : AppTheme.text1),
                  fontStyle: controller!.text.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// RESULT VIEW  — quiz submit ke baad score show karo
// ══════════════════════════════════════════════════════════════════
class _ResultView extends StatelessWidget {
  final int score;
  final int total; // MCQ count
  final int totalQuestions;
  final String studentName;
  final VoidCallback onBack;
  final Map<String, dynamic>? resultData;
  final bool loading;
  final VoidCallback? onRefresh;

  const _ResultView({
    required this.score,
    required this.total,
    required this.totalQuestions,
    required this.studentName,
    required this.onBack,
    this.resultData,
    this.loading = false,
    this.onRefresh,
  });

  String _formatUnlockTime(String? ut) {
    if (ut == null || ut.isEmpty) return '—';
    try {
      // Ignore Z to treat it as local time exactly as provided by backend
      String timeStr = ut;
      if (timeStr.endsWith('Z')) {
        timeStr = timeStr.substring(0, timeStr.length - 1);
      }
      final dt = DateTime.parse(timeStr);
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi';
    } catch (_) {
      if (ut.contains('T')) {
        final parts = ut.split('T');
        final date = parts[0];
        final time = parts[1].split('.')[0];
        return '$date $time';
      }
      return ut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your quiz result...',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText2 : AppTheme.text2,
              ),
            ),
          ],
        ),
      );
    }

    if (resultData != null && resultData!['status'] == false) {
      final msg = resultData!['message'] ?? 'Result will be available after quiz ends';
      final unlockTimeStr = _formatUnlockTime(resultData!['unlock_time']);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.amber.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: AppTheme.amber,
                  size: 40,
                ),
              ).animate().scaleXY(begin: 0.6, end: 1.0, duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'Result Pending',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                ),
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  height: 1.5,
                ),
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'UNLOCK TIME',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.amber,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlockTimeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                            ),
                            child: Center(
                              child: Text(
                                'Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onRefresh,
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGrad,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppTheme.glowShadow(AppTheme.primary),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Check Result',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
                ],
              ).animate(delay: 250.ms).fadeIn(),
            ],
          ),
        ),
      );
    }

    final displayScore = resultData?['score'] ?? resultData?['obtained_marks'] ?? score;
    final displayTotal = resultData?['total'] ?? resultData?['total_marks'] ?? total;
    final percentage = displayTotal > 0 ? (displayScore / displayTotal * 100).round() : 0;
    final isGood = percentage >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: isGood ? AppTheme.greenGrad : AppTheme.primaryGrad,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(
                    isGood ? AppTheme.greenDark : AppTheme.primary),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentage%',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$displayScore / $displayTotal',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 600.ms,
                curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text(
              isGood ? 'Well Done! 🎉' : 'Good Effort! 💪',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkText1 : AppTheme.text1,
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            Text(
              isGood
                  ? 'You performed great in this quiz!'
                  : 'Keep working hard, do better next time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                height: 1.5,
              ),
            ).animate(delay: 280.ms).fadeIn(),

            const SizedBox(height: 24),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatBox('Score Obtained', '$displayScore/$displayTotal',
                    isGood ? AppTheme.greenDark : AppTheme.primary),
                const SizedBox(width: 12),
                _StatBox('Total Qs', '$totalQuestions', AppTheme.violet),
                const SizedBox(width: 12),
                _StatBox('Accuracy', '$percentage%',
                    isGood ? AppTheme.greenDark : AppTheme.amber),
              ],
            ).animate(delay: 350.ms).fadeIn(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGrad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.glowShadow(AppTheme.primary),
                    ),
                    child: Center(
                      child: Text(
                        'Back to Courses',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate(delay: 450.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isDark ? AppTheme.darkText3 : AppTheme.text3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQuiz extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No questions found',
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkText3
              : AppTheme.text3,
        ),
      ),
    );
  }
}

// ── Index Badge ───────────────────────────────────────────────────
class _IndexBadge extends StatelessWidget {
  final int index;
  final LinearGradient gradient;
  const _IndexBadge(this.index, this.gradient);

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
        gradient: gradient, borderRadius: BorderRadius.circular(8)),
    child: Center(
      child: Text(
        '$index',
        style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white),
      ),
    ),
  );
}