import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../services/student_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/quiz_db_helper.dart';
import '../services/notification_service.dart';
import 'package:flutter/gestures.dart';

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

    // ── CODE MATCH VALIDATION ──
    // Prevent entering a different quiz's code from this specific quiz entry screen.
    if (widget.quiz.quizCode.isNotEmpty && code != widget.quiz.quizCode.toUpperCase()) {
      setState(() {
        _error = 'Invalid code for this quiz. Please enter exactly: ${widget.quiz.quizCode}';
      });
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
      
      // ── STRICT AUTHENTICATION (TIME CHECKS) ──
      DateTime? _parseDt(String dateStr, String timeStr) {
        if (dateStr.isEmpty || timeStr.isEmpty) return null;
        try {
          return DateTime.parse('$dateStr $timeStr');
        } catch (_) {
          return null;
        }
      }

      DateTime? startDt = _parseDt(fullQuiz.quizDate, fullQuiz.startTime);
      DateTime? endDt = _parseDt(fullQuiz.quizDate, fullQuiz.endTime);
      
      if (startDt != null && endDt != null && endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1)); // midnight crossing
      }

      final now = DateTime.now();
      if (endDt != null && now.isAfter(endDt)) {
        setState(() {
          _error = 'Time over! The scheduled time for this quiz has ended.';
        });
        return;
      }
      if (startDt != null && now.isBefore(startDt)) {
        setState(() {
          _error = 'Quiz has not started yet. Please wait until scheduled time.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final localSubmitted = prefs.getBool('quiz_submitted_${widget.studentId}_${fullQuiz.quizId}') == true;
      
      if (localSubmitted) {
        setState(() {
          _error = 'You have already attempted this quiz. Check your results in the My Results section.';
        });
        return;
      }

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
                    'Please enter the quiz code and join',
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
  final int? courseId;

  const StudentQuizSolveScreen({
    super.key,
    required this.quiz,
    required this.quizCode,
    required this.studentId,
    required this.studentName,
    this.endTime,
    this.isReadOnlyResult = false,
    this.initialResultData,
    this.courseId,
  });

  @override
  State<StudentQuizSolveScreen> createState() => _StudentQuizSolveScreenState();
}

class _StudentQuizSolveScreenState extends State<StudentQuizSolveScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  final Set<int> _flaggedQuestions = {}; // index-based flagged list
  Timer? _heartbeatTimer;

  // ── State ────────────────────────────────────────────────────────
  final Map<int, String> _answers = {}; // questionId -> saved answer
  final Map<int, String> _draftAnswers = {}; // questionId -> unsaved selection
  final Map<int, TextEditingController> _textControllers = {};
  bool _submitting = false;
  bool _submitted = false;
  int _score = 0;
  bool _loadingResults = false;
  Map<String, dynamic>? _resultData;

  // ── Timer ────────────────────────────────────────────────────────
  Timer? _timer;
  Duration _remaining = const Duration(hours: 1);
  DateTime? _targetEndTime;

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

  void _startHeartbeatTimer() {
    if (widget.isReadOnlyResult) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_submitted && !widget.isReadOnlyResult) {
        StudentService().updateHeartbeat(widget.quiz.quizId, widget.studentId);
      }
    });
  }

  void _trackScreenCloseIfAbandoned() {
    if (!_submitted && !widget.isReadOnlyResult) {
      StudentService().trackScreenClose(widget.quiz.quizId, widget.studentId);
    }
  }

  void _forceExitDueToTabSwitch() async {
    if (_submitted) return;
    await _saveDraftProgress();
    setState(() {
      _submitted = true;
    });
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _stopProctoring();
    
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
      ),
    );

    // Await tab switch track API call to make sure the backend gets updated to abandoned!
    try {
      await StudentService().trackTabSwitch(widget.quiz.quizId, widget.studentId);
    } catch (e) {
      debugPrint('Error tracking tab switch: $e');
    }

    if (!mounted) return;
    Navigator.pop(context); // Pop the loader

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Quiz Locked', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You switched tabs or minimized the app. As per quiz policy, you are not allowed to switch tabs. Your quiz attempt has been locked.\n\nPlease request your teacher to unlock your attempt.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // pop dialog
              Navigator.pop(context); // exit quiz solve screen
            },
            child: Text('Close', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_submitted || widget.isReadOnlyResult) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Quiz?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to leave the quiz? Your progress will be saved, but you will be locked out and cannot re-enter without teacher permission.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Exit & Lock', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _saveDraftProgress();
      setState(() {
        _submitted = true;
      });
      _timer?.cancel();
      _heartbeatTimer?.cancel();
      _stopProctoring();

      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
        ),
      );

      // Await screen close track API call to make sure status is set to abandoned!
      try {
        await StudentService().trackScreenClose(widget.quiz.quizId, widget.studentId);
      } catch (e) {
        debugPrint('Error tracking screen close: $e');
      }

      if (mounted) {
        Navigator.pop(context); // Pop the loader
      }
      return true;
    }

    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.isReadOnlyResult || _submitted) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      debugPrint('[Proctoring] Tab switch or app minimized detected.');
      _forceExitDueToTabSwitch();
    }
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
      WidgetsBinding.instance.addObserver(this);
      WakelockPlus.enable(); // Screen ko awake rakhega
      try {
        BrowserContextMenu.disableContextMenu();
      } catch (e) {
        debugPrint('Error disabling browser context menu: $e');
      }
      HardwareKeyboard.instance.addHandler(_globalKeyHandler);
      _initQuiz();
      _startHeartbeatTimer();
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
      final draftData = await QuizDbHelper.instance.loadDraft(widget.studentId, widget.quiz.quizId);

      if (draftData != null) {
        // Load answers
        final savedAnswersJson = draftData['answers_json'] as String?;
        if (savedAnswersJson != null && savedAnswersJson.isNotEmpty) {
          final Map<String, dynamic> decoded = jsonDecode(savedAnswersJson);
          setState(() {
            decoded.forEach((key, val) {
              final qId = int.tryParse(key);
              if (qId != null) {
                _answers[qId] = val.toString();
                _draftAnswers[qId] = val.toString();
                if (_textControllers.containsKey(qId)) {
                  _textControllers[qId]!.text = val.toString();
                }
              }
            });
          });
        }

        // Load index
        final savedIndex = draftData['current_index'] as int?;
        if (savedIndex != null && savedIndex >= 0 && savedIndex < _questions.length) {
          setState(() {
            _currentQuestionIndex = savedIndex;
          });
        }

        // Load flagged
        final savedFlaggedJson = draftData['flagged_json'] as String?;
        if (savedFlaggedJson != null && savedFlaggedJson.isNotEmpty) {
          final List<dynamic> decodedFlagged = jsonDecode(savedFlaggedJson);
          _flaggedQuestions.addAll(decodedFlagged.map((x) => int.tryParse(x.toString()) ?? 0));
        }

        // Load End Time
        final savedEndTime = draftData['end_time_ms'] as int?;
        if (savedEndTime != null && savedEndTime > 0) {
          _targetEndTime = DateTime.fromMillisecondsSinceEpoch(savedEndTime);
        }
      }

      // Initialize End Time if not found
      if (_targetEndTime == null) {
        _targetEndTime = widget.endTime ?? DateTime.now().add(const Duration(hours: 1));
        await _saveDraftProgress(); // Save the newly generated end time
      }

      final diff = _targetEndTime!.difference(DateTime.now());
      _remaining = diff.isNegative ? Duration.zero : diff;
    } catch (e) {
      debugPrint('Error loading SQLite draft: $e');
      _targetEndTime = widget.endTime ?? DateTime.now().add(const Duration(hours: 1));
      final diff = _targetEndTime!.difference(DateTime.now());
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
      
      if (_targetEndTime != null) {
        final diff = _targetEndTime!.difference(DateTime.now());
        setState(() {
          if (diff.isNegative) {
            _remaining = Duration.zero;
          } else {
            _remaining = diff;
          }
        });
      } else {
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining = Duration(seconds: _remaining.inSeconds - 1);
          } else {
            _remaining = Duration.zero;
          }
        });
      }

      if (_remaining == Duration.zero && !_submitted) {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  Future<void> _saveDraftProgress() async {
    if (widget.isReadOnlyResult || _submitted) return;
    try {
      await QuizDbHelper.instance.saveDraft(
        studentId: widget.studentId,
        quizId: widget.quiz.quizId,
        answers: _answers,
        flaggedQuestions: _flaggedQuestions.toList(),
        currentIndex: _currentQuestionIndex,
        endTimeMs: _targetEndTime?.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving SQLite progress: $e');
    }
  }

  Future<void> _clearDraftProgress() async {
    try {
      debugPrint('[QuizDebug] Clearing SQLite draft progress!');
      await QuizDbHelper.instance.clearDraft(widget.studentId, widget.quiz.quizId);
    } catch (e) {
      debugPrint('Error clearing SQLite draft: $e');
    }
  }

  Future<void> _markQuizAsSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keySubmitted = 'quiz_submitted_${widget.studentId}_${widget.quiz.quizId}';
      await prefs.setBool(keySubmitted, true);

      // Save metadata of the quiz
      final metaKey = 'quiz_meta_${widget.quiz.quizId}';
      final metaData = {
        'quiz_id': widget.quiz.quizId,
        'quiz_code': widget.quizCode,
        'quiz_name': widget.quiz.quizName,
        'description': widget.quiz.description,
        'quiz_date': widget.quiz.quizDate,
        'start_time': widget.quiz.startTime,
        'end_time': widget.quiz.endTime,
        'is_poll': widget.quiz.isPoll,
        'student_id': widget.studentId,
        'course_id': widget.courseId,
        'submitted_at': DateTime.now().toIso8601String(),
        'total_questions': widget.quiz.questions.length,
      };
      await prefs.setString(metaKey, jsonEncode(metaData));

      // Append to the list of attempted quizzes for this student
      final keyList = 'attempted_quizzes_list_${widget.studentId}';
      final List<String> currentList = prefs.getStringList(keyList) ?? [];
      final String idStr = widget.quiz.quizId.toString();
      if (!currentList.contains(idStr)) {
        currentList.add(idStr);
        await prefs.setStringList(keyList, currentList);
      }
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
    _heartbeatTimer?.cancel();
    if (!widget.isReadOnlyResult) {
      WidgetsBinding.instance.removeObserver(this);
      WakelockPlus.disable(); // Wakelock disable karein taake phone ka normal timeout behavior restore ho
      try {
        BrowserContextMenu.enableContextMenu();
      } catch (e) {
        debugPrint('Error enabling browser context menu: $e');
      }
      HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
      _trackScreenCloseIfAbandoned();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _stopProctoring(); // Stop proctoring when quiz ends
    super.dispose();
  }

  // ── Answer helpers ───────────────────────────────────────────────
  void _selectMcq(int questionId, String answer) {
    HapticFeedback.selectionClick();
    setState(() {
      _draftAnswers[questionId] = answer;
      _answers[questionId] = answer;
    });
    _saveDraftProgress();
  }

  // ── Answered count ───────────────────────────────────────────────
  int get _answeredCount {
    int count = 0;
    for (final q in _questions) {
      if (q.questionId == null) continue;
      if (q.type == 'mcq' && (_draftAnswers.containsKey(q.questionId) || _answers.containsKey(q.questionId))) {
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
      final selected = _draftAnswers[q.questionId] ?? _answers[q.questionId];
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
    // Ensure all question IDs are present, sending empty string for unanswered
    final Map<String, String> answersMap = {};
    for (final q in _questions) {
      if (q.questionId == null) continue;
      if (q.type == 'mcq') {
        final selectedVal = _draftAnswers[q.questionId] ?? _answers[q.questionId];
        if (selectedVal != null) {
          if (selectedVal == q.optionA) {
            answersMap[q.questionId.toString()] = 'A';
          } else if (selectedVal == q.optionB) {
            answersMap[q.questionId.toString()] = 'B';
          } else if (selectedVal == q.optionC) {
            answersMap[q.questionId.toString()] = 'C';
          } else if (selectedVal == q.optionD) {
            answersMap[q.questionId.toString()] = 'D';
          } else {
            answersMap[q.questionId.toString()] = '';
          }
        } else {
          answersMap[q.questionId.toString()] = '';
        }
      } else {
        final ctrl = _textControllers[q.questionId];
        if (ctrl != null && ctrl.text.trim().isNotEmpty) {
          answersMap[q.questionId.toString()] = ctrl.text.trim();
        } else {
          answersMap[q.questionId.toString()] = '';
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
      
      try {
        BrowserContextMenu.enableContextMenu();
      } catch (_) {}
      HardwareKeyboard.instance.removeHandler(_globalKeyHandler);

      // ── Schedule Local Notification for Result Unlock ──
      if (widget.endTime != null) {
        await NotificationService().scheduleResultNotification(
          quizId: widget.quiz.quizId,
          quizName: widget.quiz.quizName,
          scheduledTime: widget.endTime!,
        );
      }

      // Notify backend that attempt is submitted
      StudentService().markSubmitted(widget.quiz.quizId, widget.studentId);
      _snack('Quiz submitted successfully!', isError: false);
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

    if (!mounted) return;

    if (data['message'] != null) {
      _snack(data['message'].toString(), isError: data['status'] != true);
    }

    // If result is unlocked successfully, save to local storage
    if (data['status'] == true) {
      await prefs.setString(localKey, jsonEncode(data));
    }

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

  void _showSecureSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  bool _isTextFieldFocused() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return false;
    if (primary.debugLabel?.contains('EditableText') == true) {
      return true;
    }
    if (primary.context != null) {
      bool found = false;
      try {
        if (primary.context!.widget is EditableText) {
          found = true;
        } else {
          primary.context!.visitAncestorElements((element) {
            if (element.widget is EditableText) {
              found = true;
              return false;
            }
            return true;
          });
        }
      } catch (_) {}
      return found;
    }
    return false;
  }

  bool _globalKeyHandler(KeyEvent event) {
    if (widget.isReadOnlyResult || _submitted) return false;

    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isControlPressed) {
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.keyC) {
          _showSecureSnack("⛔ Copying is not allowed during the exam.");
          return true;
        } else if (key == LogicalKeyboardKey.keyX) {
          _showSecureSnack("⛔ Cutting text is not allowed during the exam.");
          return true;
        } else if (key == LogicalKeyboardKey.keyV) {
          _showSecureSnack("⛔ Pasting is not allowed during the exam.");
          return true;
        } else if (key == LogicalKeyboardKey.keyA) {
          if (!_isTextFieldFocused()) {
            _showSecureSnack("⛔ Keyboard shortcuts are disabled...");
            return true;
          }
        }
      }
    }
    return false;
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
    if (_remaining.inSeconds <= 10) return AppTheme.red;
    if (_remaining.inMinutes <= 2) return AppTheme.red;
    if (_remaining.inMinutes <= 10) return AppTheme.amber;
    return AppTheme.greenDark;
  }

  bool _isQuestionAnswered(int index) {
    if (index < 0 || index >= _questions.length) return false;
    final q = _questions[index];
    if (q.questionId == null) return false;
    return _answers.containsKey(q.questionId) &&
        _answers[q.questionId] != null &&
        _answers[q.questionId]!.isNotEmpty;
  }

  bool _hasDraftAnswer(int index) {
    if (index < 0 || index >= _questions.length) return false;
    final q = _questions[index];
    if (q.questionId == null) return false;
    if (q.type == 'mcq') {
      return _draftAnswers.containsKey(q.questionId) &&
          _draftAnswers[q.questionId] != null &&
          _draftAnswers[q.questionId]!.isNotEmpty;
    } else {
      return _textControllers.containsKey(q.questionId) &&
          _textControllers[q.questionId]!.text.trim().isNotEmpty;
    }
  }

  void _saveAndNext() {
    HapticFeedback.mediumImpact();
    final q = _questions[_currentQuestionIndex];
    if (q.questionId != null) {
      if (q.type == 'mcq') {
        if (!_draftAnswers.containsKey(q.questionId)) {
          _snack('Please select an option to save', isError: true);
          return;
        }
        _answers[q.questionId!] = _draftAnswers[q.questionId!]!;
      } else {
        final txt = _textControllers[q.questionId]?.text.trim() ?? '';
        if (txt.isEmpty) {
          _snack('Please enter an answer to save', isError: true);
          return;
        }
        _answers[q.questionId!] = txt;
      }
    }
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
    
    _saveDraftProgress();
    _snack('Answer saved successfully!', isError: false);
  }

  void _toggleFlag() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_flaggedQuestions.contains(_currentQuestionIndex)) {
        _flaggedQuestions.remove(_currentQuestionIndex);
      } else {
        _flaggedQuestions.add(_currentQuestionIndex);
      }
    });
    _saveDraftProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSecurity = !widget.isReadOnlyResult && !_submitted;

    Widget body = Column(
      children: [
        // ── Custom App Bar with timer ──────────────────────────
        _QuizAppBar(
          quizName: widget.quiz.quizName.isNotEmpty
              ? widget.quiz.quizName
              : widget.quizCode,
          timer: _fmtTimer(_remaining),
          timerColor: _timerColor,
          isUrgent: _remaining.inSeconds <= 10,
          answeredCount: _answeredCount,
          totalCount: _questions.length,
          submitted: _submitted,
          studentName: widget.studentName,
          onBack: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
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
              : Column(
                  children: [
                    // ── Candidate info strip ───────────────────
                    _buildCandidateStrip(isDark),

                    // ── VU-Style Question Map Strip ────────────
                    _buildQuestionMapStrip(isDark),

                    // ── Main Single Question Panel ─────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: anim.drive(Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic))),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentQuestionIndex),
                            child: _buildQuestionCard(
                              _questions[_currentQuestionIndex],
                              _currentQuestionIndex + 1,
                              isDark,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Premium Bottom Action Dock ─────────────
                    _buildActionDock(isDark),
                  ],
                ),
        ),
      ],
    );

    if (showSecurity) {
      body = Listener(
        onPointerDown: (PointerDownEvent event) {
          if (event.buttons == kSecondaryButton) {
            _showSecureSnack("⛔ Right-click is disabled during the exam.");
          }
        },
        child: body,
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: body,
      ),
    );
  }

  // ── Candidate profile info strip ────────────────────────────────
  Widget _buildCandidateStrip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.studentName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.isReadOnlyResult)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.greenDark.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.greenDark.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppTheme.greenDark,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .scaleXY(begin: 0.8, end: 1.3, duration: 600.ms)
                             .fade(begin: 0.4, end: 1.0),
                            const SizedBox(width: 4),
                            Text(
                              'SECURE',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.greenDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${widget.studentId} • Code: ${widget.quizCode}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              'Q: ${_currentQuestionIndex + 1} / ${_questions.length}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal question navigation map ──────────────────────────
  Widget _buildQuestionMapStrip(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface.withOpacity(0.6) : AppTheme.surfaceAlt.withOpacity(0.6),
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: _questions.length,
        itemBuilder: (context, idx) {
          final isCurrent = idx == _currentQuestionIndex;
          final isAnswered = _isQuestionAnswered(idx);
          final isUnsaved = !_isQuestionAnswered(idx) && _hasDraftAnswer(idx);
          final isFlagged = _flaggedQuestions.contains(idx);

          Color textColor = isDark ? AppTheme.darkText2 : AppTheme.text2;
          BoxDecoration dec;

          if (isCurrent) {
            dec = BoxDecoration(
              gradient: AppTheme.heroGrad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 8, offset: const Offset(0, 3))
              ],
            );
            textColor = Colors.white;
          } else if (isFlagged) {
            dec = BoxDecoration(
              gradient: AppTheme.accentGrad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.amber.withOpacity(0.25),
                    blurRadius: 6, offset: const Offset(0, 2))
              ],
            );
            textColor = Colors.white;
          } else if (isAnswered) {
            dec = BoxDecoration(
              gradient: AppTheme.greenGrad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.greenDark.withOpacity(0.2),
                    blurRadius: 6, offset: const Offset(0, 2))
              ],
            );
            textColor = Colors.white;
          } else if (isUnsaved) {
            dec = BoxDecoration(
              color: isDark ? AppTheme.darkInput : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.amber.withOpacity(0.6),
                  width: 1.5),
            );
            textColor = AppTheme.amber;
          } else {
            dec = BoxDecoration(
              color: isDark ? AppTheme.darkInput : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  width: 1.2),
            );
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _currentQuestionIndex = idx;
              });
              _saveDraftProgress();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: dec,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${idx + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isCurrent || isAnswered || isFlagged || isUnsaved
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (isFlagged && !isCurrent)
                    Positioned(
                      top: 3, right: 3,
                      child: Icon(Icons.flag_rounded, size: 7, color: Colors.yellow.shade200),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── VU-Style bottom action control dock ─────────────────────────
  Widget _buildActionDock(bool isDark) {
    final hasPrev = _currentQuestionIndex > 0;
    final hasNext = _currentQuestionIndex < _questions.length - 1;
    final isFlagged = _flaggedQuestions.contains(_currentQuestionIndex);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        border: Border(
            top: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                width: 1.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12, offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Previous
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasPrev ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: IconButton(
                  onPressed: hasPrev
                      ? () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkInput : AppTheme.bg,
                    foregroundColor: AppTheme.primary,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: isDark ? AppTheme.darkText4 : AppTheme.text4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2)),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Flag for Review
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (_submitted || _remaining == Duration.zero) ? null : _toggleFlag,
                    icon: Icon(
                      isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
                      size: 16,
                      color: (_submitted || _remaining == Duration.zero)
                          ? (isDark ? AppTheme.darkText4 : AppTheme.text4)
                          : (isFlagged ? AppTheme.amber : (isDark ? AppTheme.darkText2 : AppTheme.text2)),
                    ),
                    label: Text(
                      isFlagged ? 'FLAGGED' : 'FLAG',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: (_submitted || _remaining == Duration.zero)
                            ? (isDark ? AppTheme.darkText4 : AppTheme.text4)
                            : (isFlagged ? AppTheme.amber : (isDark ? AppTheme.darkText2 : AppTheme.text2)),
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: (_submitted || _remaining == Duration.zero)
                          ? Colors.transparent
                          : (isFlagged ? AppTheme.amber.withOpacity(0.08) : Colors.transparent),
                      side: BorderSide(
                        color: (_submitted || _remaining == Duration.zero)
                            ? (isDark ? AppTheme.darkBorder : AppTheme.border)
                            : (isFlagged ? AppTheme.amber.withOpacity(0.6) : (isDark ? AppTheme.darkBorder : AppTheme.border)),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Save Answer / Next
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (_submitted || _remaining == Duration.zero) ? null : AppTheme.greenGrad,
                      color: (_submitted || _remaining == Duration.zero)
                          ? (isDark ? AppTheme.darkInput : AppTheme.border)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: (_submitted || _remaining == Duration.zero) ? null : AppTheme.glowShadow(AppTheme.greenDark),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: (_submitted || _remaining == Duration.zero) ? null : _saveAndNext,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_rounded,
                                color: (_submitted || _remaining == Duration.zero)
                                    ? (isDark ? AppTheme.darkText4 : AppTheme.text4)
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasNext ? 'SAVE & NEXT' : 'SAVE ANSWER',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: (_submitted || _remaining == Duration.zero)
                                      ? (isDark ? AppTheme.darkText4 : AppTheme.text4)
                                      : Colors.white,
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
              ),
              const SizedBox(width: 10),

              // Next Question without saving
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasNext ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: IconButton(
                  onPressed: hasNext
                      ? () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkInput : AppTheme.bg,
                    foregroundColor: AppTheme.primary,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: isDark ? AppTheme.darkText4 : AppTheme.text4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2)),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Submit Exam dashboard link
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppTheme.glowShadow(AppTheme.red),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _submitting ? null : () => _confirmSubmit(),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'SUBMIT QUIZ / EXAM',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
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
    );
  }

  void _confirmSubmit() {
    final int answered = _answeredCount;
    final int total = _questions.length;
    final int unattempted = total - answered;
    final int flagged = _flaggedQuestions.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 38, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Exam Submission Summary',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please review your attempt details before final submission',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                ),
              ),
              const SizedBox(height: 24),

              // Dashboard items
              Row(
                children: [
                  Expanded(
                    child: _summaryBox('Total', '$total', AppTheme.primaryGrad, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryBox('Saved', '$answered', AppTheme.greenGrad, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _summaryBox('Flagged', '$flagged', AppTheme.accentGrad, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryBox('Unsaved', '$unattempted',
                        unattempted > 0
                            ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)])
                            : const LinearGradient(colors: [Colors.grey, Color(0xFF9CA3AF)]),
                        isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (unattempted > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.red.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You have $unattempted unsaved question${unattempted > 1 ? 's' : ''}. We recommend going back and saving answers before submitting.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.red,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                          'Back to Exam',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
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
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _submit();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppTheme.greenGrad,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppTheme.glowShadow(AppTheme.greenDark),
                            ),
                            child: Center(
                              child: Text(
                                'Confirm Submission ✓',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
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

  Widget _summaryBox(String title, String val, LinearGradient grad, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText3 : AppTheme.text3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q, int idx, bool isDark) {
    Widget card;
    final bool isQuizClosed = _submitted || _remaining == Duration.zero;
    switch (q.type) {
      case 'mcq':
        card = _StudentMcqCard(
          q: q,
          index: idx,
          selectedAnswer: q.questionId != null ? (_draftAnswers[q.questionId] ?? _answers[q.questionId]) : null,
          onSelect: q.questionId != null
              ? (ans) => _selectMcq(q.questionId!, ans)
              : (_) {},
          submitted: isQuizClosed,
        );
        break;
      case 'short':
        card = _StudentTextCard(
          q: q,
          index: idx,
          controller: q.questionId != null
              ? _textControllers[q.questionId!]
              : null,
          label: 'Write your answer',
          maxLines: 3,
          submitted: isQuizClosed,
          gradient: AppTheme.greenGrad,
          onSecurityWarning: _showSecureSnack,
        );
        break;
      case 'fill':
        card = _StudentTextCard(
          q: q,
          index: idx,
          controller: q.questionId != null
              ? _textControllers[q.questionId!]
              : null,
          label: 'Fill in the blank',
          maxLines: 1,
          submitted: isQuizClosed,
          gradient: AppTheme.violetGrad,
          onSecurityWarning: _showSecureSnack,
        );
        break;
      default:
        card = const SizedBox.shrink();
    }
    
    return card.animate(delay: Duration(milliseconds: (idx.clamp(1, 10) * 50))).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
}

// ══════════════════════════════════════════════════════════════════
// QUIZ APP BAR  — with live countdown
// ══════════════════════════════════════════════════════════════════
class _QuizAppBar extends StatelessWidget {
  final String quizName;
  final String timer;
  final Color timerColor;
  final bool isUrgent;
  final int answeredCount;
  final int totalCount;
  final bool submitted;
  final String? studentName;
  final VoidCallback? onBack;

  const _QuizAppBar({
    required this.quizName,
    required this.timer,
    required this.timerColor,
    this.isUrgent = false,
    required this.answeredCount,
    required this.totalCount,
    required this.submitted,
    this.studentName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalHeight = 96.0;

    return Stack(
      children: [
        // Layer 1: Ambient shadow underline
        ClipPath(
          clipper: const _QuizWaveClipper(offsetY: 3.5),
          child: Container(
            height: totalHeight + 32,
            color: Colors.black.withOpacity(0.09),
          ),
        ),
        // Layer 2: Main Premium App Bar
        ClipPath(
          clipper: const _QuizWaveClipper(),
          child: Container(
            decoration: const BoxDecoration(gradient: AppTheme.appBarGrad),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        // Back Button (Glass style)
                        GestureDetector(
                          onTap: onBack ?? () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                quizName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
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
                                      color: Colors.white.withOpacity(0.68),
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

                        const SizedBox(width: 8),

                        // Timer box
                        if (!submitted)
                          Builder(
                            builder: (context) {
                              Widget timerBox = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isUrgent ? AppTheme.red : Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isUrgent ? AppTheme.red : Colors.white.withOpacity(0.24), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_rounded, size: 13, color: Colors.white),
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
                              );

                              if (isUrgent) {
                                timerBox = timerBox
                                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                    .fade(begin: 1.0, end: 0.2, duration: 800.ms, curve: Curves.easeInOut);
                              }
                              return timerBox;
                            },
                          ),
                        if (submitted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.greenDark.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.greenDark.withOpacity(0.45), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
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
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        )
            .animate()
            .shimmer(
              duration: 3000.ms,
              color: Colors.white.withOpacity(0.15),
              size: 0.40,
            )
            .animate()
            .slideY(begin: -0.7, end: 0, duration: 380.ms, curve: Curves.easeOut)
            .fadeIn(duration: 380.ms),
      ],
    );
  }
}

class _QuizWaveClipper extends CustomClipper<Path> {
  final double offsetY;
  const _QuizWaveClipper({this.offsetY = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 22 + offsetY);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 6 + offsetY,
      size.width,
      size.height - 22 + offsetY,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _QuizWaveClipper old) => old.offsetY != offsetY;
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedAnswer != null
              ? AppTheme.primary.withOpacity(0.40)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
          width: selectedAnswer != null ? 1.8 : 1.2,
        ),
        boxShadow: selectedAnswer != null 
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))]
            : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primary.withOpacity(0.08)
                  : AppTheme.primaryBg.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              border: Border(
                  bottom: BorderSide(
                      color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                      width: 1.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index, AppTheme.primaryGrad),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multiple Choice Question',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryLighter,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.question,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.all(14),
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
                  borderColor = AppTheme.green.withOpacity(0.50);
                  textColor = AppTheme.greenDark;
                } else if (isWrong) {
                  bg = isDark
                      ? AppTheme.red.withOpacity(0.12)
                      : AppTheme.redBg;
                  borderColor = AppTheme.red.withOpacity(0.50);
                  textColor = AppTheme.red;
                } else if (isSelected) {
                  bg = isDark
                      ? AppTheme.primary.withOpacity(0.12)
                      : AppTheme.primaryBg;
                  borderColor = AppTheme.primary.withOpacity(0.60);
                  textColor = AppTheme.primary;
                } else {
                  bg = isDark ? AppTheme.darkInput : AppTheme.surfaceAlt;
                  borderColor =
                  isDark ? AppTheme.darkBorder : AppTheme.border;
                }

                return GestureDetector(
                  onTap: submitted ? null : () => onSelect(optText),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: isSelected || isCorrect || isWrong ? 1.8 : 1.2),
                      boxShadow: isSelected && !submitted
                          ? [BoxShadow(color: AppTheme.primary.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Circular Letter badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: isCorrect
                                ? AppTheme.greenGrad
                                : isWrong
                                ? const LinearGradient(colors: [AppTheme.red, Color(0xFFEF4444)])
                                : isSelected
                                ? AppTheme.primaryGrad
                                : null,
                            color: isWrong
                                ? null
                                : (!isCorrect && !isSelected)
                                ? (isDark
                                ? AppTheme.darkBorder
                                : AppTheme.border)
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              o.$1,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: (isCorrect || isWrong || isSelected)
                                    ? Colors.white
                                    : AppTheme.text4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optText,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: isSelected || isCorrect
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.greenDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white),
                          ),
                        if (isWrong)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 12, color: Colors.white),
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
  final Function(String)? onSecurityWarning;

  const _StudentTextCard({
    required this.q,
    required this.index,
    required this.controller,
    required this.label,
    required this.maxLines,
    required this.submitted,
    required this.gradient,
    this.onSecurityWarning,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFill = q.type == 'fill';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
          width: 1.2,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with question index and type badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? gradient.colors.first.withOpacity(0.08)
                  : gradient.colors.first.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              border: Border(
                  bottom: BorderSide(
                      color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                      width: 1.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IndexBadge(index, gradient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFill ? Icons.space_bar_rounded : Icons.short_text_rounded,
                            size: 14,
                            color: gradient.colors.first,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFill ? 'Fill in the Blank' : 'Short Answer Question',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: gradient.colors.first,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.question,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input
                if (controller != null && !submitted)
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    contextMenuBuilder: (context, editableTextState) {
                      if (onSecurityWarning != null) {
                        Future.microtask(() {
                          onSecurityWarning!("⛔ Right-click is disabled during the exam.");
                        });
                      }
                      return const SizedBox.shrink();
                    },
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                      prefixIcon: Icon(
                        isFill ? Icons.edit_note_rounded : Icons.mode_edit_outline_rounded,
                        color: gradient.colors.first.withOpacity(0.7),
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.border, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: gradient.colors.first, width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                // Submitted: show answer
                if (submitted && controller != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: gradient.colors.first.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: gradient.colors.first.withOpacity(0.25), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR SUBMITTED ANSWER:',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: gradient.colors.first,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller!.text.trim().isEmpty
                              ? '(No answer provided)'
                              : controller!.text.trim(),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: controller!.text.trim().isEmpty
                                ? AppTheme.text4
                                : (isDark ? AppTheme.darkText1 : AppTheme.text1),
                            fontStyle: controller!.text.trim().isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
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
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/success.json',
                  animate: true,
                  repeat: false,
                ),
              ).animate().scaleXY(begin: 0.4, end: 1.0, duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'Quiz Submitted Successfully! 🎉',
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

    // Extract nested "data" Map if present
    final innerData = resultData?['data'] is Map<String, dynamic>
        ? resultData!['data'] as Map<String, dynamic>
        : (resultData?['data'] is Map ? Map<String, dynamic>.from(resultData!['data']) : null);

    // Helper to safely parse int
    int parseIntSafe(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v.toString()) ?? fallback;
    }

    final int displayScore = parseIntSafe(
      innerData?['score'] ?? resultData?['score'] ?? resultData?['obtained_marks'],
      score,
    );

    final int displayTotal = parseIntSafe(
      innerData?['total_questions'] ?? innerData?['total'] ?? resultData?['total'] ?? resultData?['total_marks'],
      total,
    );

    final int percentage = parseIntSafe(
      innerData?['percentage'] ?? resultData?['percentage'],
      (displayTotal > 0 ? (displayScore / displayTotal * 100).round() : 0),
    );

    final int correctAns = parseIntSafe(
      innerData?['correct_answers'] ?? resultData?['correct_answers'],
      displayScore,
    );

    final int wrongAns = parseIntSafe(
      innerData?['wrong_answers'] ?? resultData?['wrong_answers'],
      (displayTotal - correctAns).clamp(0, displayTotal),
    );

    final isGood = percentage >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebratory Lottie animation
            SizedBox(
              width: 140,
              height: 140,
              child: Lottie.asset(
                'assets/lottie/success.json',
                animate: true,
                repeat: isGood,
              ),
            ).animate().scaleXY(begin: 0.4, end: 1.0, duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 12),

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

            // Stats row (using Wrap for responsive overflow-safe grid)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _StatBox('Score', '$displayScore/$displayTotal',
                    isGood ? AppTheme.greenDark : AppTheme.primary),
                _StatBox('Total Qs', '$totalQuestions', AppTheme.violet),
                _StatBox('Correct', '$correctAns', AppTheme.greenDark),
                _StatBox('Wrong', '$wrongAns', AppTheme.red),
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