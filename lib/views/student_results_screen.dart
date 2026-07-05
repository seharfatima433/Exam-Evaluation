import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/student_service.dart';
import '../services/fcm_sender_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_app_bar.dart';

class StudentResultsScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final int? courseId;

  const StudentResultsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.courseId,
  });

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  final _service = StudentService();
  bool _loading = true;
  String? _error;
  List<dynamic> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  DateTime? _parseDateTime(String date, String time) {
    try {
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

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // ── 1. Fetch server results ──────────────────────────────────
    final res = await _service.fetchStudentResults(
      widget.studentId,
      courseId: widget.courseId,
    );
    if (!mounted) return;

    List<dynamic> serverResults = [];
    if (res['success'] == true) {
      final raw = res['data'];
      if (raw is List) {
        serverResults = List<dynamic>.from(raw);
      } else if (raw is Map) {
        // Try every possible key the backend may use
        final inner = raw['data'] ?? raw['results'] ??
            raw['quiz_results'] ?? raw['attempts'] ?? raw['records'];
        if (inner is List) {
          serverResults = List<dynamic>.from(inner);
        }
      }
    }
    debugPrint('[Results] Server returned ${serverResults.length} results');

    // ── 2. Build full set of locally-submitted quiz IDs ──────────
    final prefs = await SharedPreferences.getInstance();

    final Set<String> allAttemptedIds = {};

    // From the new tracking list
    final tracked = prefs.getStringList('attempted_quizzes_list_${widget.studentId}') ?? [];
    allAttemptedIds.addAll(tracked);

    // Scan ALL prefs keys for quiz_submitted_{studentId}_{quizId}
    // This catches quizzes submitted BEFORE the new tracking list existed
    final submitPrefix = 'quiz_submitted_${widget.studentId}_';
    for (final key in prefs.getKeys()) {
      if (key.startsWith(submitPrefix)) {
        final qIdStr = key.substring(submitPrefix.length);
        if (qIdStr.isNotEmpty && int.tryParse(qIdStr) != null) {
          allAttemptedIds.add(qIdStr);
        }
      }
    }
    debugPrint('[Results] Local attempted quiz IDs: $allAttemptedIds');

    // ── 3. Build final list ──────────────────────────────────────
    final List<dynamic> finalResults = List<dynamic>.from(serverResults);

    // Track which quiz IDs are already covered by server results
    final Set<String> processedIds = {};
    for (final r in serverResults) {
      if (r is Map) {
        final qId = (r['quiz_id'] ?? r['id'])?.toString();
        if (qId != null) processedIds.add(qId);
      }
    }

    for (final qIdStr in allAttemptedIds) {
      if (processedIds.contains(qIdStr)) continue;

      final quizId = int.tryParse(qIdStr)!;
      final localResultKey = 'quiz_result_${quizId}_${widget.studentId}';

      // ── a) Check local cache first ─────────────────────────────
      final localStr = prefs.getString(localResultKey);
      Map<String, dynamic>? cached;
      if (localStr != null) {
        try { cached = jsonDecode(localStr); } catch (_) {}
      }

      // Course filter guard on cached result
      if (widget.courseId != null && cached != null) {
        final cachedCourseId = cached['course_id'] ?? cached['data']?['course_id'];
        if (cachedCourseId != null &&
            cachedCourseId.toString() != widget.courseId.toString()) {
          continue; // belongs to a different course — skip
        }
      }

      if (cached != null && cached['status'] == true) {
        final d = cached['data'] is Map ? cached['data'] as Map<String, dynamic> : cached;
        finalResults.add(_buildResultEntry(quizId, d, {}));
        processedIds.add(qIdStr);
        continue;
      }

      // ── b) Always try a live API fetch ─────────────────────────
      // (no local metadata = old quiz; try anyway — it may be unlocked now)
      final metaKey = 'quiz_meta_$quizId';
      final metaStr = prefs.getString(metaKey);
      Map<String, dynamic> meta = {};
      if (metaStr != null) {
        try { meta = Map<String, dynamic>.from(jsonDecode(metaStr)); } catch (_) {}
      }

      // Course filter guard (only when metadata is available)
      if (widget.courseId != null && meta.isNotEmpty) {
        final metaCourse = meta['course_id'];
        if (metaCourse != null &&
            metaCourse.toString() != widget.courseId.toString()) {
          continue;
        }
      }

      // Live fetch
      final fetchRes = await _service.fetchQuizResult(quizId, widget.studentId);
      debugPrint('[Results] fetchQuizResult $quizId => status=${fetchRes['status']}');

      if (fetchRes['status'] == true) {
        await prefs.setString(localResultKey, jsonEncode(fetchRes));
        // Also update the tracking list so next load is faster
        final list = prefs.getStringList('attempted_quizzes_list_${widget.studentId}') ?? [];
        if (!list.contains(qIdStr)) {
          list.add(qIdStr);
          await prefs.setStringList('attempted_quizzes_list_${widget.studentId}', list);
        }
        final d = fetchRes['data'] is Map ? fetchRes['data'] as Map<String, dynamic> : fetchRes;

        // ── Send Result Unlocked FCM Notification ──
        FCMSenderService.sendResultUnlockedNotification(
          quizName: d['quiz_name']?.toString() ?? meta['quiz_name']?.toString() ?? 'Quiz #$quizId',
          courseName: d['course_name']?.toString() ?? meta['course_name']?.toString(),
          score: '${d['score'] ?? d['obtained_marks'] ?? '0'}/${d['total_marks'] ?? '0'}',
          percentage: d['percentage']?.toString(),
        );

        finalResults.add(_buildResultEntry(quizId, d, meta));
        processedIds.add(qIdStr);
        continue;
      }

      // ── c) Still locked / pending ──────────────────────────────
      if (meta.isNotEmpty) {
        finalResults.add({
          'quiz_id': quizId.toString(),
          'quiz_code': meta['quiz_code'] ?? '',
          'quiz_name': meta['quiz_name'] ?? '',
          'course_name': meta['course_name'] ?? meta['course_title'] ?? '',
          'total_questions': meta['total_questions'] ?? '0',
          'submitted_at': meta['submitted_at'] ?? '',
          'start_time': meta['start_time'] ?? '',
          'end_time': meta['end_time'] ?? '',
          'student_id': widget.studentId.toString(),
          'is_pending': true,
        });
      } else if (widget.courseId == null) {
        // Old quiz with no metadata — show minimal pending card
        finalResults.add({
          'quiz_id': quizId.toString(),
          'quiz_code': '',
          'quiz_name': 'Quiz #$quizId',
          'course_name': '',
          'total_questions': '0',
          'submitted_at': '',
          'start_time': '',
          'end_time': '',
          'student_id': widget.studentId.toString(),
          'is_pending': true,
        });
      }
      processedIds.add(qIdStr);
    }

    debugPrint('[Results] Final list size: ${finalResults.length}');
    setState(() {
      _results = finalResults;
      _loading = false;
      if (serverResults.isEmpty && finalResults.isEmpty && res['success'] == false) {
        _error = res['message'];
      }
    });
  }

  /// Build a normalized result map from API data + optional meta fallback.
  Map<String, dynamic> _buildResultEntry(
    int quizId,
    Map<String, dynamic> d,
    Map<String, dynamic> meta,
  ) {
    return {
      'quiz_id': quizId.toString(),
      'quiz_code': d['quiz_code'] ?? meta['quiz_code'] ?? '',
      'quiz_name': d['quiz_name'] ?? meta['quiz_name'] ?? '',
      'course_name': d['course_name'] ?? d['course_title'] ?? '',
      'total_questions':
          d['total_questions'] ?? d['total'] ?? meta['total_questions'] ?? '0',
      'correct_answers': d['correct_answers'] ?? '0',
      'wrong_answers': d['wrong_answers'] ?? '0',
      'score': d['score'] ?? d['obtained_marks'] ?? '0',
      'total_marks': d['total_marks'] ?? meta['total_marks'] ?? d['total_questions'] ?? d['total'] ?? meta['total_questions'] ?? '0',
      'percentage': d['percentage'] ?? '0',
      'submitted_at': d['submitted_at'] ?? meta['submitted_at'] ?? '',
      'start_time': d['start_time'] ?? meta['start_time'] ?? '',
      'end_time': d['end_time'] ?? meta['end_time'] ?? '',
      'short_answers': d['short_answers_detail'] ?? d['short_answers'] ?? [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumAppBar(
            title: widget.courseId != null ? 'Course Results' : 'My Quiz Results',
            subtitle: widget.studentName,
            showBack: true,
          ),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.outfit(color: AppTheme.red, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.amber.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.amber, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No Past Results', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
            const SizedBox(height: 8),
            Text('You haven\'t completed any quizzes yet\nthat have unlocked results.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0);
    }

    return RefreshIndicator(
      onRefresh: _loadResults,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return _ResultCard(
            result: result,
            index: index,
            onRefresh: _loadResults,
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final int index;
  final VoidCallback onRefresh;

  const _ResultCard({
    required this.result,
    required this.index,
    required this.onRefresh,
  });

  void _showResultDetails(BuildContext context, Map<String, dynamic> result, bool isDark) {
    int parseIntSafe(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      final d = double.tryParse(v.toString());
      if (d != null) return d.round();
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDoubleSafe(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String formatScore(double v) {
      if (v == v.toInt()) {
        return v.toInt().toString();
      }
      return v.toStringAsFixed(2);
    }

    final score = parseDoubleSafe(result['score']);
    final totalMarks = parseDoubleSafe(result['total_marks'] ?? result['total_questions']);
    final correct = parseIntSafe(result['correct_answers']);
    final wrong = parseIntSafe(result['wrong_answers']);
    
    int percentage = parseIntSafe(result['percentage']);
    if (percentage == 0 && score > 0 && totalMarks > 0) {
      percentage = ((score / totalMarks) * 100).round();
    }
    final isPass = percentage >= 50;

    final quizCode = result['quiz_code']?.toString() ?? 'Unknown';
    final courseName = result['course_name']?.toString() ?? result['course_title']?.toString() ?? '';
    final quizName = result['quiz_name']?.toString() ?? '';
    final submittedAt = result['submitted_at']?.toString() ?? 'N/A';
    final startTime = result['start_time']?.toString() ?? 'N/A';
    final endTime = result['end_time']?.toString() ?? 'N/A';
    
    final color = isPass ? AppTheme.greenDark : AppTheme.amber;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppTheme.darkBorder : AppTheme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              
              // Header
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: isPass ? AppTheme.greenGrad : AppTheme.primaryGrad,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                courseName.isNotEmpty ? courseName : 'Quiz: $quizCode',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText1 : AppTheme.text1),
                textAlign: TextAlign.center,
              ),
              if (quizName.isNotEmpty)
                Text(quizName, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
              
              const SizedBox(height: 24),
 
              // Stats Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _DetailBox('Score', '${formatScore(score)}/${formatScore(totalMarks)}', color, isDark),
                  _DetailBox('Correct', '$correct', AppTheme.greenDark, isDark),
                  _DetailBox('Wrong', '$wrong', AppTheme.red, isDark),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Timing Info
              _TimingRow('Scheduled Start', startTime, isDark),
              _TimingRow('Scheduled End', endTime, isDark),
              _TimingRow('Submitted At', submittedAt, isDark),
              
              if (result['short_answers'] != null && (result['short_answers'] as List).isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppTheme.violet.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.violet, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text('AI Evaluation Feedback', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
                  ],
                ),
                const SizedBox(height: 12),
                ...((result['short_answers'] as List).map((sa) {
                  final qText = sa['question']?.toString() ?? '';
                  final ans = sa['student_answer']?.toString() ?? 'No answer';
                  final fScore = double.tryParse(sa['final_score']?.toString() ?? '0') ?? 0.0;
                  final feedback = sa['feedback']?.toString() ?? '';
                  final isC = sa['is_correct'] == true || fScore >= 60;
                  
                  final kwScore = double.tryParse(sa['keyword_score']?.toString() ?? '0') ?? 0.0;
                  final aiScore = double.tryParse(sa['ai_score']?.toString() ?? '0') ?? 0.0;
                  final kwWeight = sa['keyword_weight']?.toString() ?? '20';
                  final aiWeight = sa['ai_weight']?.toString() ?? '80';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkInput : AppTheme.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isC ? AppTheme.green.withOpacity(0.3) : AppTheme.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: $qText', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText2 : AppTheme.text2)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(ans.isEmpty ? 'No answer provided' : ans, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText1 : AppTheme.text1, fontStyle: ans.isEmpty ? FontStyle.italic : FontStyle.normal)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text('Keywords ($kwWeight%): ${kwScore.toStringAsFixed(1)}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.violet.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text('AI Eval ($aiWeight%): ${aiScore.toStringAsFixed(1)}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.violet, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(isC ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: isC ? AppTheme.green : AppTheme.red),
                            const SizedBox(width: 6),
                            Text('Final Score: ${fScore.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: isC ? AppTheme.green : AppTheme.red)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('AI Feedback: $feedback', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? AppTheme.violet.withOpacity(0.9) : AppTheme.violet, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList()),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                    foregroundColor: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      );
    },
    );
  }

  void _showPendingDetailsSheet(BuildContext context, Map<String, dynamic> result, bool isDark) {
    final quizIdStr = result['quiz_id']?.toString() ?? '';
    final studentIdStr = result['student_id']?.toString() ?? '';
    final quizCode = result['quiz_code']?.toString() ?? 'Unknown';
    final courseName = result['course_name']?.toString() ?? result['course_title']?.toString() ?? '';
    final quizName = result['quiz_name']?.toString() ?? '';
    final submittedAt = result['submitted_at']?.toString() ?? 'N/A';
    final submittedDateOnly = submittedAt.length >= 10 ? submittedAt.substring(0, 10) : submittedAt;
    final submittedTimeOnly = submittedAt.length >= 16 ? submittedAt.substring(11, 16) : '';
    final endTime = result['end_time']?.toString() ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        bool verifying = false;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppTheme.darkBorder : AppTheme.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  
                  // Pending Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_clock_rounded,
                        color: AppTheme.amber,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Result Pending Release',
                    style: GoogleFonts.outfit(
                      fontSize: 20, 
                      fontWeight: FontWeight.w800, 
                      color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    courseName.isNotEmpty ? courseName : 'Quiz Code: $quizCode',
                    style: GoogleFonts.outfit(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText2 : AppTheme.text2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (quizName.isNotEmpty)
                    Text(quizName, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Your quiz has been submitted successfully. The results will unlock once the quiz timer ends and the teacher unlocks the grades.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.darkText3 : AppTheme.text3,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  _TimingRow('Quiz Scheduled End', endTime, isDark),
                  _TimingRow('Submitted Date', submittedDateOnly, isDark),
                  if (submittedTimeOnly.isNotEmpty)
                    _TimingRow('Submitted Time', submittedTimeOnly, isDark),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: verifying ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.darkInput : AppTheme.surfaceAlt,
                              foregroundColor: isDark ? AppTheme.darkText1 : AppTheme.text1,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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
                              gradient: verifying ? null : AppTheme.primaryGrad,
                              color: verifying ? (isDark ? AppTheme.darkInput : AppTheme.border) : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: verifying ? null : AppTheme.glowShadow(AppTheme.primary),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: verifying ? null : () async {
                                  setModalState(() => verifying = true);
                                  final qId = int.tryParse(quizIdStr);
                                  final sId = int.tryParse(studentIdStr);
                                  if (qId != null && sId != null) {
                                    final fetchRes = await StudentService().fetchQuizResult(qId, sId);
                                    if (fetchRes['status'] == true) {
                                      final prefs = await SharedPreferences.getInstance();
                                      final localResultKey = 'quiz_result_${qId}_$sId';
                                      await prefs.setString(localResultKey, jsonEncode(fetchRes));
                                      
                                      HapticFeedback.mediumImpact();
                                      if (context.mounted) {
                                        Navigator.pop(context); // Close sheet
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Quiz Results Unlocked Successfully!', style: GoogleFonts.outfit(color: Colors.white)),
                                            backgroundColor: AppTheme.greenDark,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                      onRefresh();
                                      return;
                                    }
                                  }
                                  
                                  // Still pending
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  if (context.mounted) {
                                    setModalState(() => verifying = false);
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Results are still pending release.', style: GoogleFonts.outfit(color: Colors.white)),
                                        backgroundColor: AppTheme.amber,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: verifying
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'REFRESH STATUS',
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
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = result['is_pending'] == true;

    if (isPending) {
      final quizCode = result['quiz_code']?.toString() ?? 'Unknown';
      final courseName = result['course_name']?.toString() ?? result['course_title']?.toString();
      final displayName = courseName != null && courseName.isNotEmpty 
          ? '$courseName ($quizCode)' 
          : 'Quiz: $quizCode';
      final submittedAt = result['submitted_at']?.toString() ?? '';
      final dateOnly = submittedAt.length >= 10 ? submittedAt.substring(0, 10) : 'Pending';
      
      final color = AppTheme.amber;
      final grad = AppTheme.accentGrad;
      final bg = isDark ? color.withOpacity(0.08) : AppTheme.amberBg;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.themedCard(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.lightImpact();
                _showPendingDetailsSheet(context, result, isDark);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: grad,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.30),
                                blurRadius: 10, offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_clock_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PENDING RELEASE',
                                  style: GoogleFonts.outfit(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: color, letterSpacing: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                        const SizedBox(width: 5),
                        Text(dateOnly,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
                        const Spacer(),
                        Text(
                          'LOCKED',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w800, color: color),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: index * 60))
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.05, end: 0);
    }
    
    int parseIntSafe(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      final d = double.tryParse(v.toString());
      if (d != null) return d.round();
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDoubleSafe(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String formatScore(double v) {
      if (v == v.toInt()) {
        return v.toInt().toString();
      }
      return v.toStringAsFixed(2);
    }

    final score = parseDoubleSafe(result['score']);
    final totalMarks = parseDoubleSafe(result['total_marks'] ?? result['total_questions']);
    
    int percentage = parseIntSafe(result['percentage']);
    if (percentage == 0 && score > 0 && totalMarks > 0) {
      percentage = ((score / totalMarks) * 100).round();
    }
    final isPass = percentage >= 50;

    final quizCode = result['quiz_code']?.toString() ?? 'Unknown';
    final courseName = result['course_name']?.toString() ?? result['course_title']?.toString();
    final displayName = courseName != null && courseName.isNotEmpty ? '$courseName ($quizCode)' : 'Quiz: $quizCode';

    final submittedAt = result['submitted_at']?.toString() ?? '';
    final dateOnly = submittedAt.length >= 10 ? submittedAt.substring(0, 10) : submittedAt;

    final color = isPass ? AppTheme.greenDark : AppTheme.amber;
    final grad = isPass ? AppTheme.greenGrad : AppTheme.accentGrad;
    final bg   = isPass ? AppTheme.greenBg   : AppTheme.amberBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.themedCard(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              _showResultDetails(context, result, isDark);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tinted header ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? color.withOpacity(0.08) : bg,
                    border: Border(
                        bottom: BorderSide(
                            color: isDark ? AppTheme.darkBorder : AppTheme.border,
                            width: 1)),
                  ),
                  child: Row(
                    children: [
                      // Gradient score badge
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: grad,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.30),
                                blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$percentage%',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                              displayName,
                              style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkText1 : AppTheme.text1,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPass ? 'PASSED' : 'NEEDS IMPROVEMENT',
                                style: GoogleFonts.outfit(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: color, letterSpacing: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom detail row ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                      const SizedBox(width: 5),
                      Text(dateOnly,
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
                      const Spacer(),
                      Text(
                        '${formatScore(score)} / ${formatScore(totalMarks)}',
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w800, color: color),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: isDark ? AppTheme.darkText4 : AppTheme.text4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _DetailBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _DetailBox(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _TimingRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppTheme.darkText3 : AppTheme.text3)),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkText1 : AppTheme.text1)),
        ],
      ),
    );
  }
}
