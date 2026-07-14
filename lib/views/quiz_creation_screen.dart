import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/local_quiz_db.dart';
import '../services/fcm_sender_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

class QuizCreationScreen extends StatefulWidget {
  final int teacherId;
  final Course course;
  const QuizCreationScreen({
    super.key,
    required this.teacherId,
    required this.course,
  });
  @override
  State<QuizCreationScreen> createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = QuizCreateController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '10');
  final _local = LocalQuizDb();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _difficulty = 'medium';
  int _mcqCount = 5;
  int _shortCount = 0;
  int _fillCount = 0;
  bool _isPoll = false;

  List<Map<String, dynamic>> _questions = [];
  Timer? _genTimer;
  int _elapsed = 0;

  // ── Topic-search state ──────────────────────────────────────
  List<CachedQuizMeta> _topicSuggestions = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _topicCtrl.addListener(_onTopicChanged);
  }

  @override
  void dispose() {
    _genTimer?.cancel();
    _searchDebounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _topicCtrl.dispose();
    _marksCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Topic field listener — debounced search ───────────────────
  void _onTopicChanged() {
    _searchDebounce?.cancel();
    final q = _topicCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _topicSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _local.searchByTopic(q);
      if (mounted) setState(() => _topicSuggestions = results);
    });
  }

  // ── Open the per-question selection sheet for a cached quiz ──
  void _openQuizSelectionSheet(CachedQuizMeta meta) async {
    final rows = await _local.getQuestions(meta.quizCode);
    if (rows.isEmpty || !mounted) return;

    // Convert DB rows → display maps
    final allQuestions = rows.map((r) {
      final type = r['type'] as String;
      final normType = type == 'mcq'
          ? 'mcqs'
          : type == 'short'
          ? 'short_questions'
          : type == 'fill'
          ? 'fill_blanks'
          : type;
      return <String, dynamic>{
        'type': normType,
        'question': r['question'],
        'option_a': r['option_a'],
        'option_b': r['option_b'],
        'option_c': r['option_c'],
        'option_d': r['option_d'],
        'options': [
          r['option_a'],
          r['option_b'],
          r['option_c'],
          r['option_d'],
        ].where((o) => o != null).toList(),
        'correct_answer': r['correct_answer'],
        '_from_cache': meta.quizCode,
      };
    }).toList();

    // Which ones are already in _questions (by question text)?
    final alreadyAdded = _questions
        .where((q) => q['_from_cache'] == meta.quizCode)
        .map((q) => q['question'] as String)
        .toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuizSelectionSheet(
        meta: meta,
        questions: allQuestions,
        initiallySelected: alreadyAdded,
        onDone: (selected) {
          setState(() {
            // Remove any previously added questions from this quiz
            _questions.removeWhere((q) => q['_from_cache'] == meta.quizCode);
            // Add freshly selected ones
            _questions.addAll(selected);
          });
        },
      ),
    );
  }

  // ── Timer helpers ─────────────────────────────────────────────
  String _fmt24(TimeOfDay? t, String fb) {
    if (t == null) return fb;
    // Send HH:MM:SS in 24-hour format so backend stores correctly
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmt12(TimeOfDay? t, String fb) {
    if (t == null) return fb;
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _fmtDateReadable(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get _timerStr {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${_elapsed}s';
  }

  void _startTimer() {
    _elapsed = 0;
    _genTimer?.cancel();
    _genTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _stopTimer() {
    _genTimer?.cancel();
    _genTimer = null;
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: error ? AppTheme.red : AppTheme.text1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: error ? 5 : 3),
      ),
    );
  }

  // ── Generate ──────────────────────────────────────────────────
  Future<void> _generate() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Enter quiz name', error: true);
      return;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      _snack('Enter topic', error: true);
      return;
    }
    if (_date == null) {
      _snack('Select a date', error: true);
      return;
    }
    if (_mcqCount == 0 && _shortCount == 0 && _fillCount == 0 && !_isPoll) {
      _snack('Select at least one question type', error: true);
      return;
    }

    HapticFeedback.mediumImpact();
    _startTimer();

    final Map<String, dynamic> categoriesPayload = {};
    if (_isPoll) {
      categoriesPayload['mcqs'] = 100;
      if (_shortCount > 0) categoriesPayload['short_questions'] = _shortCount;
      if (_fillCount > 0) categoriesPayload['fill_blanks'] = _fillCount;
    } else {
      if (_mcqCount > 0) categoriesPayload['mcqs'] = _mcqCount;
      if (_shortCount > 0) categoriesPayload['short_questions'] = _shortCount;
      if (_fillCount > 0) categoriesPayload['fill_blanks'] = _fillCount;
    }

    await _ctrl.generateQuiz({
      'teacher_id': widget.teacherId,
      'course_id': widget.course.id,
      'quiz_name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'topic': _topicCtrl.text.trim(),
      'quiz_date': _fmtDate(_date!),
      'start_time': _fmt24(_startTime, '09:00'),
      'end_time': _fmt24(_endTime, '10:00'),
      'difficulty': _difficulty,
      'is_poll': _isPoll,
      'categories': categoriesPayload,
    });
    _stopTimer();

    if (_ctrl.generateState == LoadState.success &&
        _ctrl.generatedQuestions != null) {
      _buildList();
      if (mounted && _questions.isNotEmpty) _showAllQuestionsPopup();
    } else if (_ctrl.generateError != null) {
      _snack(_ctrl.generateError!, error: true);
    }
  }

  void _buildList() {
    // Keep already-merged cached questions, append new AI questions
    final cached = _questions
        .where((q) => q.containsKey('_from_cache'))
        .toList();
    _questions = [...cached];

    final q = _ctrl.generatedQuestions!;

    // ── Only parse types the teacher actually selected ──────────
    if (_isPoll || _mcqCount > 0) {
      for (final item in (q['mcqs'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(item);
        map['type'] = 'mcqs';
        // Normalize correct_answer to uppercase letter (A/B/C/D)
        final ca = (map['correct_answer'] ?? '').toString().trim();
        if (ca.length == 1 && 'abcd'.contains(ca.toLowerCase())) {
          map['correct_answer'] = ca.toUpperCase();
        } else {
          // If it's the full option text, find which index it matches and convert
          final opts = _opts(map);
          final idx = opts.indexWhere(
                (o) => o.toString().trim().toLowerCase() == ca.toLowerCase(),
          );
          if (idx >= 0 && idx < 4) {
            map['correct_answer'] = ['A', 'B', 'C', 'D'][idx];
          }
        }
        _questions.add(map);
      }
    }

    if (_shortCount > 0) {
      for (final item in (q['short_questions'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(item);
        map['type'] = 'short_questions';
        String ans = (map['correct_answer'] ?? map['answer'] ?? '').toString().trim();
        if (ans.isEmpty && map['keywords'] is List) {
          ans = (map['keywords'] as List).join(', ');
        } else if (ans.isEmpty && map['context'] != null) {
          ans = map['context'].toString().trim();
        }
        map['correct_answer'] = ans;
        _questions.add(map);
      }
    }

    if (_fillCount > 0) {
      for (final item in (q['fill_blanks'] as List? ?? [])) {
        final map = Map<String, dynamic>.from(item);
        map['type'] = 'fill_blanks';
        String ans = (map['correct_answer'] ?? map['answer'] ?? '').toString().trim();
        if (ans.isEmpty && map['keywords'] is List) {
          ans = (map['keywords'] as List).join(', ');
        } else if (ans.isEmpty && map['context'] != null) {
          ans = map['context'].toString().trim();
        }
        map['correct_answer'] = ans;
        _questions.add(map);
      }
    }
  }

  List<dynamic> _opts(Map<String, dynamic> m) {
    if (m['options'] is List) return m['options'] as List;
    return [
      m['option_a'],
      m['option_b'],
      m['option_c'],
      m['option_d'],
    ].where((o) => o != null).toList();
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_questions.isEmpty) {
      _snack('No questions to save', error: true);
      return;
    }
    if (_marksCtrl.text.trim().isEmpty) {
      _snack('Enter total marks', error: true);
      return;
    }
    final totalMarks = int.tryParse(_marksCtrl.text.trim());
    if (totalMarks == null || totalMarks <= 0) {
      _snack('Total marks must be a valid positive number', error: true);
      return;
    }
    HapticFeedback.mediumImpact();

    final qs = <Map<String, dynamic>>[];
    for (int index = 0; index < _questions.length; index++) {
      final q = _questions[index];
      final out = <String, dynamic>{};
      // ── Type: normalize to backend-expected values ──
      final rawType = (q['type'] ?? 'mcqs').toString();
      const typeMap = {
        'mcqs': 'mcq',
        'mcq': 'mcq',
        'short_questions': 'short',
        'short': 'short',
        'long_questions': 'long',
        'long': 'long',
        'fill_blanks': 'fill',
        'fill': 'fill',
      };
      out['type'] = typeMap[rawType] ?? 'mcq';
      out['question'] = q['question'];
      out['no'] = index + 1;

      if (rawType == 'mcqs' || rawType == 'mcq') {
        final opts = _opts(q);
        out['option_a'] = opts.length > 0 ? opts[0] : '';
        out['option_b'] = opts.length > 1 ? opts[1] : '';
        out['option_c'] = opts.length > 2 ? opts[2] : '';
        out['option_d'] = opts.length > 3 ? opts[3] : '';
        // Ensure correct_answer is stored as letter (A/B/C/D)
        final ca = (q['correct_answer'] ?? '').toString().trim();
        if (ca.length == 1 && 'ABCD'.contains(ca.toUpperCase())) {
          out['correct_answer'] = ca.toUpperCase();
        } else {
          // It might be full text — find which option matches
          final idx = opts.indexWhere(
                (o) => o.toString().trim().toLowerCase() == ca.toLowerCase(),
          );
          out['correct_answer'] = idx >= 0 ? ['A', 'B', 'C', 'D'][idx] : ca;
        }
      } else {
        out['correct_answer'] = q['correct_answer'] ?? q['answer'] ?? '';
      }
      qs.add(out);
    }

    final payload = {
      'teacher_id': widget.teacherId,
      'course_id': widget.course.id,
      'quiz_name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'topic': _topicCtrl.text.trim(),
      'quiz_date': _fmtDate(_date!),
      'start_time': _fmt24(_startTime, '09:00'),
      'end_time': _fmt24(_endTime, '10:00'),
      'difficulty': _difficulty,
      'is_poll': _isPoll,
      'num_questions': _questions.length,
      'total_marks': totalMarks,
      'questions': qs,
    };

    // ── Route to poll endpoint when is_poll is true ──
    final ok = _isPoll
        ? await _ctrl.savePoll(payload)
        : await _ctrl.saveQuiz(payload);

    if (ok) {
      final code = _ctrl.savedQuizCode ?? '';

      // ── Send Quiz Scheduled FCM Notification ──
      FCMSenderService.sendQuizScheduledNotification(
        courseId: widget.course.id,
        quizName: _nameCtrl.text.trim(),
        courseName: widget.course.courseTitle,
        quizDate: _fmtDateReadable(_date!),
        startTime: _fmt12(_startTime, '09:00 AM'),
        endTime: _fmt12(_endTime, '10:00 AM'),
        isPoll: _isPoll,
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _QuizCodeDialog(
            code: code,
            isPoll: _isPoll,
          ),
        );
        if (mounted) Navigator.pop(context);
      }
    } else {
      _snack(
        _ctrl.saveError ?? (_isPoll ? 'Poll save failed' : 'Save failed'),
        error: true,
      );
    }
  }

  // ── Review popup ──────────────────────────────────────────────
  void _showAllQuestionsPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AllQuestionsSheet(
        questions: _questions,
        quizName: _nameCtrl.text.trim(),
        onSave: () {
          Navigator.pop(context);
          _save();
        },
        onDiscard: () => Navigator.pop(context),
        onDeleteQuestion: (idx) => setState(() => _questions.removeAt(idx)),
        onEditQuestion: (idx, updated) =>
            setState(() => _questions[idx] = updated),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final generating = _ctrl.generateState == LoadState.loading;
    final saving = _ctrl.saveState == LoadState.loading;
    final hasQs = _questions.isNotEmpty;
    final mergedCount = _questions
        .where((q) => q.containsKey('_from_cache'))
        .length;

    final media = MediaQuery.of(context);
    final isSmall = media.size.width < 400;
    final hPad = isSmall ? 10.0 : 14.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.course.courseTitle,
            subtitle: 'Create Quiz',
            showBack: true,
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: generating || saving,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: (generating || saving) ? 0.6 : 1.0,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
                  children: [
                    // ── Quiz Details ───────────────────────────────────
                    _SectionCard(
                      title: 'Quiz Details',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Quiz Name *'),
                          const SizedBox(height: 5),
                          _tf(
                            _nameCtrl,
                            'e.g. Mid-Term Quiz',
                            Icons.title_rounded,
                            enabled: !generating && !saving,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Topic *'),
                                    const SizedBox(height: 5),
                                    _buildTopicField(enabled: !generating && !saving),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Total Marks *'),
                                    const SizedBox(height: 5),
                                    _tf(
                                      _marksCtrl,
                                      'e.g. 50',
                                      Icons.score_outlined,
                                      enabled: !generating && !saving,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _label('Description'),
                          const SizedBox(height: 5),
                          _tf(
                            _descCtrl,
                            'Optional description',
                            Icons.notes_rounded,
                            enabled: !generating && !saving,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 50.ms)
                        .slideY(begin: 0.06, end: 0),

                    // ── Topic suggestions — full-width list outside card ──
                    _buildSuggestionsSection(),
                    const SizedBox(height: 10),

                    // ── Schedule ───────────────────────────────────────
                    _SectionCard(
                      title: 'Schedule',
                      icon: Icons.calendar_today_rounded,
                      child: Row(
                        children: [
                          Expanded(child: _datePicker()),
                          SizedBox(width: isSmall ? 5 : 7),
                          Expanded(
                            child: _timePicker(
                              'Start',
                              _startTime,
                                  (t) => setState(() => _startTime = t),
                            ),
                          ),
                          SizedBox(width: isSmall ? 5 : 7),
                          Expanded(
                            child: _timePicker(
                              'End',
                              _endTime,
                                  (t) => setState(() => _endTime = t),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 130.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 10),

                    // ── Settings ───────────────────────────────────────
                    _SectionCard(
                      title: 'Settings',
                      icon: Icons.tune_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Difficulty'),
                          const SizedBox(height: 7),
                          Row(
                            children: ['easy', 'medium', 'hard'].map((d) {
                              final sel = d == _difficulty;
                              final c = d == 'easy'
                                  ? AppTheme.green
                                  : d == 'hard'
                                  ? AppTheme.red
                                  : AppTheme.amber;
                              final bg = d == 'easy'
                                  ? AppTheme.greenBg
                                  : d == 'hard'
                                  ? AppTheme.redBg
                                  : AppTheme.amberBg;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: d != 'hard' ? (isSmall ? 4.0 : 6.0) : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: (generating || saving)
                                        ? null
                                        : () => setState(() => _difficulty = d),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel ? bg : const Color(0xFFF2F6FC),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: sel ? c : AppTheme.border,
                                          width: sel ? 1.5 : 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          d[0].toUpperCase() + d.substring(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: sel ? c : AppTheme.text3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          
                          // ── Poll Toggle ────────────────────────────
                          _PollToggleTile(
                            isPoll: _isPoll,
                            onChanged: (val) {
                              if (generating || saving) return;
                              setState(() {
                                _isPoll = val;
                                if (val) {
                                  _mcqCount = 100; // Poll ON: MCQs forced to 100
                                } else {
                                  // Poll OFF: Reset MCQs back to valid range to prevent slider crash
                                  if (_mcqCount > 30) _mcqCount = 5; 
                                }
                              });
                              HapticFeedback.selectionClick();
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          _label('Select Question Counts *'),
                          const SizedBox(height: 10),
                          
                          // Custom steppers for each question type
                          IgnorePointer(
                            ignoring: generating || saving,
                            child: Column(
                              children: [
                                _buildCounter(
                                  label: 'Multiple Choice (MCQs)',
                                  value: _isPoll ? 100 : _mcqCount,
                                  color: AppTheme.primary,
                                  locked: _isPoll,
                                  hint: _isPoll ? 'Fixed to 100 for polls' : null,
                                  onChanged: (v) => setState(() => _mcqCount = v),
                                ),
                                const SizedBox(height: 6),
                                _buildCounter(
                                  label: 'Short Answer Questions',
                                  value: _shortCount,
                                  color: AppTheme.green,
                                  locked: false,
                                  onChanged: (v) => setState(() => _shortCount = v),
                                ),
                                const SizedBox(height: 6),
                                _buildCounter(
                                  label: 'Fill in the Blanks',
                                  value: _fillCount,
                                  color: AppTheme.violet,
                                  locked: false,
                                  onChanged: (v) => setState(() => _fillCount = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Generate button ─────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      height: generating ? 72 : 56,
                      decoration: BoxDecoration(
                        color: generating
                            ? (Theme.of(context).brightness == Brightness.dark
                            ? (_isPoll
                            ? AppTheme.violet.withOpacity(0.12)
                            : AppTheme.primary.withOpacity(0.12))
                            : (_isPoll
                            ? AppTheme.violetBg
                            : AppTheme.primaryBg))
                            : null,
                        gradient: generating
                            ? null
                            : (_isPoll
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF6A1B9A),
                            Color(0xFF9C27B0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : AppTheme.heroGrad),
                        borderRadius: BorderRadius.circular(14),
                        border: generating
                            ? Border.all(
                          color:
                          (_isPoll ? AppTheme.violet : AppTheme.primary)
                              .withOpacity(0.35),
                        )
                            : null,
                        boxShadow: generating
                            ? null
                            : AppTheme.glowShadow(
                          _isPoll ? AppTheme.violet : AppTheme.primary,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: (generating || saving) ? null : _generate,
                          borderRadius: BorderRadius.circular(14),
                          splashColor: Colors.white.withOpacity(0.12),
                          child: Center(
                            child: generating
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation(
                                      _isPoll
                                          ? AppTheme.violet
                                          : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isPoll
                                      ? 'Generating Poll · $_timerStr · ~2 min'
                                      : 'Generating · $_timerStr · up to 2 min',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: _isPoll
                                        ? AppTheme.violet
                                        : (Theme.of(context).brightness ==
                                        Brightness.dark
                                        ? const Color(0xFF42A5F5)
                                        : AppTheme.primary),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isPoll
                                      ? Icons.poll_rounded
                                      : Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: isSmall ? 16 : 19,
                                ),
                                SizedBox(width: isSmall ? 6 : 9),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isPoll
                                          ? 'Generate Poll with AI'
                                          : 'Generate Quiz with AI',
                                      style: GoogleFonts.outfit(
                                        fontSize: isSmall ? 14 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isPoll) ...[
                                  SizedBox(width: isSmall ? 6 : 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmall ? 5 : 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      '100 Qs',
                                      style: TextStyle(
                                        fontSize: isSmall ? 9 : 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

                    // ── Summary banner ──────────────────────────────────
                    if (hasQs) ...[
                      const SizedBox(height: 16),
                      _GeneratedSummaryBanner(
                        count: _questions.length,
                        mergedCount: mergedCount,
                        isPoll: _isPoll,
                        onReview: _showAllQuestionsPopup,
                        onSave: _save,
                        saving: saving,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Topic field with live suggestions ────────────────────────
  // Returns only the TextField — suggestions are rendered separately outside the card
  Widget _buildTopicField({bool enabled = true}) {
    return TextField(
      enabled: enabled,
      controller: _topicCtrl,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkText1
            : AppTheme.text1,
      ),
      decoration: InputDecoration(
        hintText: 'e.g. Flutter Widgets',
        hintStyle: TextStyle(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkText4
              : AppTheme.text4,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.topic_outlined, size: 17, color: AppTheme.text4),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        suffixIcon: _topicCtrl.text.isNotEmpty
            ? IconButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 15,
            color: AppTheme.text4,
          ),
          onPressed: () {
            _topicCtrl.clear();
            setState(() => _topicSuggestions = []);
          },
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF42A5F5)
                : AppTheme.primary,
            width: 1.8,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkInput
            : const Color(0xFFF2F6FC),
      ),
    );
  }

  // ── Suggestions list — shown outside the Quiz Details card ────
  Widget _buildSuggestionsSection() {
    if (_topicSuggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Quizzes with same topic — tap to add questions as reference',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.text2,
                  ),
                ), // usually text2/darkText2 handled by theme
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '${_topicSuggestions.length} found',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // One card per quiz
        ..._topicSuggestions.map((meta) {
          final addedCount = _questions
              .where((q) => q['_from_cache'] == meta.quizCode)
              .length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TopicSuggestionTile(
              meta: meta,
              addedCount: addedCount,
              onTap: () => _openQuizSelectionSheet(meta),
            ),
          );
        }),
      ],
    );
  }

  // ── App bar ───────────────────────────────────────────────────
  // App bar replaced by PremiumAppBar widget in build()

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkText3
          : AppTheme.text3,
      letterSpacing: 0.1,
    ),
  );

  Widget _tf(TextEditingController c, String hint, IconData icon,
      {bool enabled = true}) =>
      TextField(
        enabled: enabled,
        controller: c,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkText1
              : AppTheme.text1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkText4
                : AppTheme.text4,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              icon,
              size: 17,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkText4
                  : AppTheme.text4,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBorder
                  : AppTheme.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBorder
                  : AppTheme.border,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF42A5F5)
                  : AppTheme.primary,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkInput
              : const Color(0xFFF5F7FF),
        ),
      );

  Widget _datePicker() => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (d != null) setState(() => _date = d);
    },
    child: _pickerBox(
      Icons.calendar_today_rounded,
      _date != null ? '${_date!.day}/${_date!.month}/${_date!.year}' : 'Date *',
    ),
  );

  Widget _timePicker(
      String label,
      TimeOfDay? t,
      void Function(TimeOfDay) onPick,
      ) => GestureDetector(
    onTap: () async {
      final p = await showTimePicker(
        context: context,
        initialTime: t ?? TimeOfDay.now(),
        builder: (context, child) {
          // Force 24-hour format so 11 PM = 23, not 11
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (p != null) onPick(p);
    },
    child: _pickerBox(
      Icons.access_time_rounded,
      // Display in 24hr format so teacher sees 23:00 not 11:00 PM
      t != null
          ? '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}'
          : label,
    ),
  );
  Widget _buildCounter({
    required String label,
    required int value,
    required Color color,
    required bool locked,
    String? hint,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: locked ? 0.55 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.text3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Count badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: value > 0 ? color.withOpacity(0.12) : (isDark ? AppTheme.darkInput : AppTheme.bg),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: value > 0 ? color.withOpacity(0.35) : (isDark ? AppTheme.darkBorder : AppTheme.border),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  locked ? '100 (fixed)' : '$value',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: value > 0 || locked ? color : (isDark ? AppTheme.darkText3 : AppTheme.text3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.12),
              disabledActiveTrackColor: color.withOpacity(0.4),
              disabledThumbColor: color.withOpacity(0.4),
              disabledInactiveTrackColor: color.withOpacity(0.1),
            ),
            child: Slider(
              value: locked ? 100.0 : value.toDouble(),
              min: 0,
              max: locked ? 100.0 : 30.0,
              divisions: locked ? 100 : 30,
              onChanged: locked
                  ? null
                  : (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v.round());
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerBox(IconData icon, String label) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkInput
            : const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.border,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmall ? 10 : 12,
            color: AppTheme.primary.withOpacity(0.6),
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: isSmall ? 10 : 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkText3
                      : AppTheme.text3,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Topic suggestion tile — shows quiz info + how many Qs added
// ═════════════════════════════════════════════════════════════════
class _TopicSuggestionTile extends StatelessWidget {
  final CachedQuizMeta meta;
  final int addedCount;
  final VoidCallback onTap;
  const _TopicSuggestionTile({
    required this.meta,
    required this.addedCount,
    required this.onTap,
  });

  Color get _diffColor => meta.difficulty == 'easy'
      ? AppTheme.green
      : meta.difficulty == 'hard'
      ? AppTheme.red
      : AppTheme.amber;

  @override
  Widget build(BuildContext context) {
    final hasAdded = addedCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasAdded ? AppTheme.greenBg : AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasAdded
                    ? Icons.playlist_add_check_rounded
                    : Icons.quiz_outlined,
                size: 17,
                color: hasAdded ? AppTheme.green : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.quizName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        size: 10,
                        color: AppTheme.text4,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          meta.quizCode,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.text3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (meta.difficulty != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _diffColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            meta.difficulty!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _diffColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge: shows count if some added, else "Select" button
            hasAdded
                ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppTheme.greenBg,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.green.withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppTheme.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$addedCount added',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.green,
                    ),
                  ),
                ],
              ),
            )
                : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 12,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
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

// ═════════════════════════════════════════════════════════════════
// Per-question selection sheet — teacher picks which Qs to include
// ═════════════════════════════════════════════════════════════════
class _QuizSelectionSheet extends StatefulWidget {
  final CachedQuizMeta meta;
  final List<Map<String, dynamic>> questions;
  final Set<String> initiallySelected;
  final void Function(List<Map<String, dynamic>> selected) onDone;

  const _QuizSelectionSheet({
    required this.meta,
    required this.questions,
    required this.initiallySelected,
    required this.onDone,
  });

  @override
  State<_QuizSelectionSheet> createState() => _QuizSelectionSheetState();
}

class _QuizSelectionSheetState extends State<_QuizSelectionSheet> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    // Pre-tick questions that were already added
    _selected = {};
    for (int i = 0; i < widget.questions.length; i++) {
      final qText = widget.questions[i]['question'] as String? ?? '';
      if (widget.initiallySelected.contains(qText)) _selected.add(i);
    }
  }

  void _toggleAll(bool val) => setState(() {
    if (val) {
      _selected.addAll(List.generate(widget.questions.length, (i) => i));
    } else {
      _selected.clear();
    }
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.questions.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderMid,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.playlist_add_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meta.quizName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.text1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.questions.length} questions available',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Select all toggle
                      GestureDetector(
                        onTap: () => _toggleAll(!allSelected),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: allSelected
                                ? (Theme.of(context).brightness ==
                                Brightness.dark
                                ? AppTheme.primary.withOpacity(0.15)
                                : AppTheme.primaryBg)
                                : (Theme.of(context).brightness ==
                                Brightness.dark
                                ? AppTheme.darkInput
                                : AppTheme.bg),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: allSelected
                                  ? AppTheme.primary.withOpacity(0.4)
                                  : (Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border),
                            ),
                          ),
                          child: Text(
                            allSelected ? 'Deselect all' : 'Select all',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: allSelected
                                  ? (Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? const Color(0xFF42A5F5)
                                  : AppTheme.primary)
                                  : (Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? AppTheme.darkText3
                                  : AppTheme.text3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppTheme.divider),
                ],
              ),
            ),

            // ── Question list ───────────────────────────────────
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: widget.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final q = widget.questions[i];
                  final isSel = _selected.contains(i);
                  return _ReferenceQuestionCard(
                    index: i + 1,
                    question: q,
                    isAdded: isSel,
                    onToggle: () => setState(
                          () => isSel ? _selected.remove(i) : _selected.add(i),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom bar ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkInput
                                : AppTheme.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                              Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                Theme.of(context).brightness ==
                                    Brightness.dark
                                    ? AppTheme.darkText1
                                    : AppTheme.text3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          final sel = _selected
                              .map((i) => widget.questions[i])
                              .toList();
                          widget.onDone(sel);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGrad,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.glowShadow(AppTheme.primary),
                          ),
                          child: Center(
                            child: Text(
                              _selected.isEmpty
                                  ? 'Add 0 Questions'
                                  : 'Add ${_selected.length} Question${_selected.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// Reference question card — per-question + / − button, answers shown
// ═══════════════════════════════════════════════════════════════
class _ReferenceQuestionCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> question;
  final bool isAdded;
  final VoidCallback onToggle;
  const _ReferenceQuestionCard({
    required this.index,
    required this.question,
    required this.isAdded,
    required this.onToggle,
  });
  @override
  State<_ReferenceQuestionCard> createState() => _ReferenceQuestionCardState();
}

class _ReferenceQuestionCardState extends State<_ReferenceQuestionCard> {
  bool _expanded = false; // answers collapsed by default; tap arrow to expand

  Color get _color => widget.question['type'] == 'mcqs'
      ? AppTheme.primary
      : widget.question['type'] == 'short_questions'
      ? AppTheme.green
      : AppTheme.violet;

  String get _tag => widget.question['type'] == 'mcqs'
      ? 'MCQ'
      : widget.question['type'] == 'short_questions'
      ? 'Short'
      : 'Fill';

  List<dynamic> _opts() {
    if (widget.question['options'] is List)
      return widget.question['options'] as List;
    return [
      widget.question['option_a'],
      widget.question['option_b'],
      widget.question['option_c'],
      widget.question['option_d'],
    ].where((o) => o != null).toList();
  }

  String get _answer =>
      (widget.question['correct_answer'] ?? widget.question['answer'] ?? '')
          .toString()
          .trim();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: AppTheme.themedCard(context).copyWith(
        color: widget.isAdded
            ? (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primary.withOpacity(0.12)
            : AppTheme.primaryBg)
            : null,
        border: Border.all(
          color: widget.isAdded
              ? (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF42A5F5).withOpacity(0.5)
              : AppTheme.primary.withOpacity(0.35))
              : (Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.border),
          width: widget.isAdded ? 1.5 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _color.withOpacity(0.2)),
                  ),
                  child: Text(
                    _tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Index
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Question text
                Expanded(
                  child: Text(
                    widget.question['question']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText1
                          : AppTheme.text1,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Expand arrow
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppTheme.text4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // ── + / − button ──────────────────────────────────
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: widget.isAdded
                          ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.green.withOpacity(0.12)
                          : AppTheme.greenBg)
                          : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primary.withOpacity(0.12)
                          : AppTheme.primaryBg),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isAdded
                            ? AppTheme.green.withOpacity(0.4)
                            : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF42A5F5).withOpacity(0.5)
                            : AppTheme.primary.withOpacity(0.35)),
                      ),
                    ),
                    child: Icon(
                      widget.isAdded ? Icons.remove_rounded : Icons.add_rounded,
                      size: 16,
                      color: widget.isAdded ? AppTheme.green : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Collapsible answer preview ─────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _expanded
                ? Column(
              children: [
                Container(height: 1, color: AppTheme.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: _buildAnswer(),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer() {
    if (widget.question['type'] == 'mcqs') return _mcqPreview();
    if (_answer.isNotEmpty) return _shortFillPreview();
    return const SizedBox.shrink();
  }

  Widget _mcqPreview() {
    final opts = _opts();
    final correct = _answer;
    final labels = ['A', 'B', 'C', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText3, // darkText3 is neutral grey
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        ...opts.asMap().entries.map((e) {
          final label = e.key < labels.length ? labels[e.key] : '?';
          final text = e.value?.toString() ?? '';
          final isC = text.isNotEmpty && text == correct;
          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: isC
                  ? (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.green.withOpacity(0.15)
                  : AppTheme.greenBg)
                  : (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkInput
                  : AppTheme.bg),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isC
                    ? AppTheme.green.withOpacity(0.35)
                    : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : AppTheme.border),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isC
                        ? AppTheme.green
                        : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : AppTheme.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isC
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkText3
                            : AppTheme.text3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      color: isC
                          ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.green
                          : AppTheme.greenDark)
                          : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText2
                          : AppTheme.text2),
                      fontWeight: isC ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isC)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: AppTheme.green,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _shortFillPreview() {
    final isViolet = widget.question['type'] == 'fill_blanks';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isViolet
            ? (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.violet.withOpacity(0.15)
            : AppTheme.violetBg)
            : (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.green.withOpacity(0.15)
            : AppTheme.greenBg),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isViolet
              ? AppTheme.violet.withOpacity(0.3)
              : AppTheme.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_rounded,
            size: 12,
            color: isViolet ? AppTheme.violet : AppTheme.green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _answer,
              style: TextStyle(
                fontSize: 12,
                color: isViolet ? AppTheme.violet : AppTheme.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Summary banner
// ═════════════════════════════════════════════════════════════════
class _GeneratedSummaryBanner extends StatelessWidget {
  final int count, mergedCount;
  final bool isPoll;
  final VoidCallback onReview, onSave;
  final bool saving;
  const _GeneratedSummaryBanner({
    required this.count,
    required this.mergedCount,
    required this.isPoll,
    required this.onReview,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmall = media.size.width < 400;

    return Container(
      decoration: BoxDecoration(
        gradient: isPoll
            ? const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : AppTheme.greenGrad,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.glowShadow(
          isPoll ? AppTheme.violet : AppTheme.green,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            if (isPoll)
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          isPoll
                              ? Icons.poll_rounded
                              : Icons.check_circle_rounded,
                          size: isSmall ? 20 : 24,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: isSmall ? 10 : 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isPoll
                                        ? 'Poll Generated!'
                                        : 'Quiz Generated!',
                                    style: GoogleFonts.outfit(
                                      fontSize: isSmall ? 13 : 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPoll) ...[
                                  const SizedBox(width: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      'POLL',
                                      style: TextStyle(
                                        fontSize: isSmall ? 8 : 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: isSmall ? 0.5 : 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mergedCount > 0
                                  ? '$count questions ($mergedCount from existing quiz)'
                                  : '$count questions ready to review',
                              style: GoogleFonts.outfit(
                                fontSize: isSmall ? 11 : 12,
                                color: Colors.white.withOpacity(0.80),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$count Qs',
                          style: GoogleFonts.outfit(
                            fontSize: isSmall ? 11 : 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onReview,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.preview_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Review',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: saving ? null : onSave,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow:
                              (Theme.of(context).brightness ==
                                  Brightness.dark)
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: AppTheme.greenDark.withOpacity(
                                    0.25,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.greenDark,
                                  ),
                                ),
                              )
                                  : Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_alt_rounded,
                                    size: 16,
                                    color: AppTheme.greenDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Save Quiz',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.greenDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

// ═════════════════════════════════════════════════════════════════
// Poll Toggle Tile — animated banner-style switch
// ═════════════════════════════════════════════════════════════════
class _PollToggleTile extends StatelessWidget {
  final bool isPoll;
  final ValueChanged<bool> onChanged;
  const _PollToggleTile({required this.isPoll, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark
        ? const Color(0xFF6A1B9A).withOpacity(0.18)
        : const Color(0xFFF3E5F5);
    final activeColor = AppTheme.violet;
    final inactiveBg = isDark ? AppTheme.darkInput : const Color(0xFFF2F6FC);
    final borderColor = isPoll
        ? activeColor.withOpacity(0.45)
        : (isDark ? AppTheme.darkBorder : AppTheme.border);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isPoll ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isPoll ? 1.6 : 1.2),
        boxShadow: isPoll
            ? [
          BoxShadow(
            color: activeColor.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Row(
        children: [
          // Icon with animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPoll
                  ? activeColor.withOpacity(0.15)
                  : (isDark ? AppTheme.darkBorder : AppTheme.border)
                  .withOpacity(0.35),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child:
              Icon(
                isPoll ? Icons.poll_rounded : Icons.poll_outlined,
                size: 20,
                color: isPoll
                    ? activeColor
                    : (isDark ? AppTheme.darkText3 : AppTheme.text3),
              )
                  .animate(target: isPoll ? 1 : 0)
                  .scaleXY(
                begin: 0.8,
                end: 1.0,
                duration: 200.ms,
                curve: Curves.elasticOut,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPoll
                        ? activeColor
                        : (isDark ? AppTheme.darkText1 : AppTheme.text1),
                  ),
                  child: const Text('Create as Poll'),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    color: isPoll
                        ? activeColor.withOpacity(0.75)
                        : (isDark ? AppTheme.darkText4 : AppTheme.text4),
                    fontWeight: FontWeight.w400,
                  ),
                  child: Text(
                    isPoll
                        ? 'MCQs: 100 fixed • Short/Fill: slider value'
                        : 'Tap to generate a 100-question poll instead',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Custom animated switch
          GestureDetector(
            onTap: () => onChanged(!isPoll),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: isPoll
                    ? activeColor
                    : (isDark
                    ? const Color(0xFF1A3355)
                    : const Color(0xFFDDE3F0)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isPoll
                    ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    alignment: isPoll
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: isPoll
                            ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Color(0xFF6A1B9A),
                        )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(isPoll)).fadeIn(duration: 180.ms);
  }
}

// ═════════════════════════════════════════════════════════════════
// Section Card
// ═════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: AppTheme.themedCard(context, radius: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.primary.withOpacity(0.08)
                : AppTheme.primaryBg.withOpacity(0.45),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGrad,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkText1
                      : AppTheme.text1,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        // Content
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════
// Full Questions + Answers Bottom Sheet (review before save)
// ═════════════════════════════════════════════════════════════════
class _AllQuestionsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String quizName;
  final VoidCallback onSave, onDiscard;
  final void Function(int index) onDeleteQuestion;
  final void Function(int index, Map<String, dynamic> updated) onEditQuestion;

  const _AllQuestionsSheet({
    required this.questions,
    required this.quizName,
    required this.onSave,
    required this.onDiscard,
    required this.onDeleteQuestion,
    required this.onEditQuestion,
  });

  @override
  State<_AllQuestionsSheet> createState() => _AllQuestionsSheetState();
}

class _AllQuestionsSheetState extends State<_AllQuestionsSheet> {
  late List<Map<String, dynamic>> _qs;

  @override
  void initState() {
    super.initState();
    _qs = List.from(widget.questions);
  }

  void _delete(int i) {
    widget.onDeleteQuestion(i);
    setState(() => _qs.removeAt(i));
  }

  void _edit(int i) async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditQuestionDialog(question: _qs[i]),
    );
    if (updated != null) {
      widget.onEditQuestion(i, updated);
      setState(() => _qs[i] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderMid,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quizName.isEmpty
                                  ? 'Generated Quiz'
                                  : widget.quizName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color:
                                Theme.of(context).brightness ==
                                    Brightness.dark
                                    ? AppTheme.darkText1
                                    : AppTheme.text1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_qs.length} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                Theme.of(context).brightness ==
                                    Brightness.dark
                                    ? AppTheme.darkText3
                                    : AppTheme.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _typeCount(_qs),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppTheme.divider),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                itemCount: _qs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReviewQuestionCard(
                  index: i + 1,
                  question: _qs[i],
                  onDelete: () => _delete(i),
                  onEdit: () => _edit(i),
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onDiscard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppTheme.redBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.red.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.red,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Discard',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: widget.onSave,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppTheme.greenGrad,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.glowShadow(AppTheme.green),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Save Quiz',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _typeCount(List<Map<String, dynamic>> qs) {
    final mcq = qs.where((q) => q['type'] == 'mcqs').length;
    final short = qs.where((q) => q['type'] == 'short_questions').length;
    final fill = qs.where((q) => q['type'] == 'fill_blanks').length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mcq > 0) _pill('$mcq MCQ', AppTheme.primary, AppTheme.primaryBg),
        if (short > 0) ...[
          const SizedBox(width: 4),
          _pill('$short Short', AppTheme.green, AppTheme.greenBg),
        ],
        if (fill > 0) ...[
          const SizedBox(width: 4),
          _pill('$fill Fill', AppTheme.violet, AppTheme.violetBg),
        ],
      ],
    );
  }

  Widget _pill(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════
// Review question card — collapsible, edit + delete buttons
// ═════════════════════════════════════════════════════════════════
class _ReviewQuestionCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onDelete, onEdit;
  const _ReviewQuestionCard({
    required this.index,
    required this.question,
    required this.onDelete,
    required this.onEdit,
  });
  @override
  State<_ReviewQuestionCard> createState() => _ReviewQuestionCardState();
}

class _ReviewQuestionCardState extends State<_ReviewQuestionCard> {
  bool _expanded = true;

  bool get _fromCache => widget.question.containsKey('_from_cache');

  Color get _color => widget.question['type'] == 'mcqs'
      ? AppTheme.primary
      : widget.question['type'] == 'short_questions'
      ? AppTheme.green
      : AppTheme.violet;

  String get _tag => widget.question['type'] == 'mcqs'
      ? 'MCQ'
      : widget.question['type'] == 'short_questions'
      ? 'Short'
      : 'Fill';

  List<dynamic> _opts() {
    final m = widget.question;
    if (m['options'] is List) return m['options'] as List;
    return [
      m['option_a'],
      m['option_b'],
      m['option_c'],
      m['option_d'],
    ].where((o) => o != null).toList();
  }

  String get _answer =>
      (widget.question['correct_answer'] ?? widget.question['answer'] ?? '')
          .toString()
          .trim();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.themedCard(
        context,
        radius: 14,
        borderColor: _fromCache ? AppTheme.violet.withOpacity(0.4) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _color.withOpacity(0.2)),
                  ),
                  child: Text(
                    _tag,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: _color,
                    ),
                  ),
                ),
                if (_fromCache) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.violetBg,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppTheme.violet.withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      'merged',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.violet,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.question['question']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkText1
                          : AppTheme.text1,
                      height: 1.4,
                    ),
                  ),
                ),
                // Edit
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                // Delete
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.redBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 13,
                      color: AppTheme.red,
                    ),
                  ),
                ),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppTheme.text4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _expanded
                ? Column(
              children: [
                Container(height: 1, color: AppTheme.divider),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildAnswer(),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer() {
    final type = widget.question['type'] ?? '';
    if (type == 'mcqs') return _mcqAnswer();
    if (type == 'short_questions') return _shortAnswer();
    return _fillAnswer();
  }

  Widget _mcqAnswer() {
    final opts = _opts();
    final correct = _answer;
    final labels = ['A', 'B', 'C', 'D'];
    if (opts.isEmpty) return _noAnswer();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.text3,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        ...opts.asMap().entries.map((e) {
          final label = e.key < labels.length ? labels[e.key] : '?';
          final text = e.value?.toString() ?? '';
          final isC = (text.isNotEmpty && text == correct) || label == correct;
          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isC ? AppTheme.greenBg : AppTheme.bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isC ? AppTheme.green.withOpacity(0.35) : AppTheme.border,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isC ? AppTheme.green : AppTheme.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isC ? Colors.white : AppTheme.text3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      color: isC ? AppTheme.green : AppTheme.text2,
                      fontWeight: isC ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isC)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppTheme.green,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _shortAnswer() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'EXPECTED KEYWORDS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.text3,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 7),
      _answer.isEmpty
          ? Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.border, width: 1.2),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: AppTheme.text4,
            ),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Students write their own answer',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.text3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      )
          : Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.greenBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppTheme.green.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Text(
          _answer,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.text1,
            height: 1.5,
          ),
        ),
      ),
    ],
  );

  Widget _fillAnswer() {
    if (_answer.isEmpty) return _noAnswer();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ANSWER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.text3,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.violetBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppTheme.violet,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _answer,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.violet,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noAnswer() => const Text(
    'No answer available',
    style: TextStyle(
      fontSize: 12,
      color: AppTheme.text3,
      fontStyle: FontStyle.italic,
    ),
  );
}

// ═════════════════════════════════════════════════════════════════
// Edit Question Dialog
// ═════════════════════════════════════════════════════════════════
class _EditQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  const _EditQuestionDialog({required this.question});
  @override
  State<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<_EditQuestionDialog> {
  late TextEditingController _qCtrl;
  late TextEditingController _ansCtrl;
  late List<TextEditingController> _optCtrls;
  late int _correctIdx;

  bool get _isMcq => widget.question['type'] == 'mcqs';

  List<dynamic> _opts() {
    final m = widget.question;
    if (m['options'] is List) return m['options'] as List;
    return [
      m['option_a'],
      m['option_b'],
      m['option_c'],
      m['option_d'],
    ].where((o) => o != null).toList();
  }

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.question['question'] ?? '');
    _ansCtrl = TextEditingController(
      text: widget.question['correct_answer'] ?? '',
    );

    if (_isMcq) {
      final opts = _opts();
      _optCtrls = List.generate(
        4,
            (i) => TextEditingController(
          text: i < opts.length ? opts[i]?.toString() ?? '' : '',
        ),
      );
      // Find correct index — supports both letter (A/B/C/D) and full-text
      final ca = (widget.question['correct_answer'] ?? '').toString().trim();
      if (ca.length == 1 && 'ABCD'.contains(ca.toUpperCase())) {
        _correctIdx = 'ABCD'.indexOf(ca.toUpperCase());
        if (_correctIdx < 0) _correctIdx = 0;
      } else {
        _correctIdx = opts.indexWhere((o) => o?.toString() == ca);
        if (_correctIdx < 0) _correctIdx = 0;
      }
    } else {
      _optCtrls = [];
      _correctIdx = 0;
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _ansCtrl.dispose();
    for (final c in _optCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit Question',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.darkText4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Question text
            const Text(
              'Question',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.text2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _qCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: AppTheme.text1),
              decoration: _inputDec('Enter question text'),
            ),
            const SizedBox(height: 14),

            if (_isMcq) ...[
              const Text(
                'Options  (tap circle to mark correct)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text2,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final isC = i == _correctIdx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _correctIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isC ? AppTheme.green : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isC ? AppTheme.green : AppTheme.borderMid,
                              width: 1.5,
                            ),
                          ),
                          child: isC
                              ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _optCtrls[i],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.text1,
                          ),
                          decoration: _inputDec(
                            'Option ${['A', 'B', 'C', 'D'][i]}',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text(
                widget.question['type'] == 'short_questions'
                    ? 'Keywords (comma separated)'
                    : 'Answer',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text2,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _ansCtrl,
                maxLines: widget.question['type'] == 'short_questions' ? 3 : 2,
                style: const TextStyle(fontSize: 13, color: AppTheme.text1),
                decoration: _inputDec(
                  widget.question['type'] == 'short_questions'
                      ? 'e.g. keyword1, keyword2, concept...'
                      : 'Enter correct answer',
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13, color: AppTheme.text3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final updated = Map<String, dynamic>.from(
                        widget.question,
                      );
                      updated['question'] = _qCtrl.text.trim();
                      if (_isMcq) {
                        final opts = _optCtrls
                            .map((c) => c.text.trim())
                            .toList();
                        updated['option_a'] = opts[0];
                        updated['option_b'] = opts[1];
                        updated['option_c'] = opts[2];
                        updated['option_d'] = opts[3];
                        updated['options'] = opts
                            .where((o) => o.isNotEmpty)
                            .toList();
                        // Store correct_answer as letter (A/B/C/D)
                        updated['correct_answer'] = _correctIdx < 4
                            ? ['A', 'B', 'C', 'D'][_correctIdx]
                            : 'A';
                      } else {
                        updated['correct_answer'] = _ansCtrl.text.trim();
                      }
                      Navigator.pop(context, updated);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGrad,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.glowShadow(AppTheme.primary),
                      ),
                      child: const Center(
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 13,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkText4
          : AppTheme.text4,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkBorder
            : AppTheme.border,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkBorder
            : AppTheme.border,
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF42A5F5)
            : AppTheme.primary,
        width: 1.8,
      ),
    ),
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkInput
        : const Color(0xFFF2F6FC),
  );
}

// ═══════════════════════════════════════════════════════════════
//  Quiz Code Dialog — shown after successful quiz/poll save
// ═══════════════════════════════════════════════════════════════
class _QuizCodeDialog extends StatefulWidget {
  final String code;
  final bool isPoll;
  const _QuizCodeDialog({required this.code, required this.isPoll});

  @override
  State<_QuizCodeDialog> createState() => _QuizCodeDialogState();
}

class _QuizCodeDialogState extends State<_QuizCodeDialog>
    with SingleTickerProviderStateMixin {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPoll = widget.isPoll;
    final accent = isPoll ? AppTheme.violet : AppTheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.18),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: isPoll
                    ? const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppTheme.heroGrad,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPoll
                          ? Icons.poll_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPoll ? 'Poll Saved!' : 'Quiz Saved!',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPoll
                        ? 'Share this code with students'
                        : 'Share this code with students',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ],
              ),
            ),

            // ── Code section ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Text(
                    isPoll ? 'Poll Code' : 'Quiz Code',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Code box with copy button
                  GestureDetector(
                    onTap: _copy,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _copied
                            ? accent.withOpacity(0.10)
                            : (isDark
                                ? AppTheme.darkInput
                                : const Color(0xFFF4F6FB)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _copied
                              ? accent.withOpacity(0.5)
                              : (isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border),
                          width: _copied ? 1.8 : 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.code,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _copied
                                    ? accent
                                    : (isDark
                                        ? AppTheme.darkText1
                                        : AppTheme.text1),
                                letterSpacing: 3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _copied
                                ? Icon(Icons.check_circle_rounded,
                                    key: const ValueKey('check'),
                                    color: accent,
                                    size: 22)
                                : Icon(Icons.copy_rounded,
                                    key: const ValueKey('copy'),
                                    color: isDark
                                        ? AppTheme.darkText3
                                        : AppTheme.text3,
                                    size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _copied ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'Copied to clipboard!',
                      style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Done button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _copy,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_rounded, size: 16, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            'Copy Code',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 280.ms,
          curve: Curves.easeOutBack,
        );
  }
}