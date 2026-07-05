class QuizSummary {
  final int id;
  final String quizCode;
  final String quizName;
  final String? description;
  final String quizDate;
  final String startTime;
  final String endTime;
  final String difficulty;
  final int totalQuestions;
  final int totalMarks;
  final int courseId;
  final bool isPoll;

  const QuizSummary({
    required this.id,
    required this.quizCode,
    required this.quizName,
    this.description,
    required this.quizDate,
    required this.startTime,
    required this.endTime,
    required this.difficulty,
    required this.totalQuestions,
    required this.totalMarks,
    required this.courseId,
    this.isPoll = false,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) => QuizSummary(
    id: _parseInt(json['id']),
    quizCode: json['quiz_code'] ?? '',
    quizName: json['quiz_name'] ?? '',
    description: json['description'],
    quizDate: json['quiz_date'] ?? '',
    startTime: json['start_time'] ?? '',
    endTime: json['end_time'] ?? '',
    difficulty: json['difficulty'] ?? 'medium',
    totalQuestions: _parseInt(json['total_questions']),
    totalMarks: _parseInt(json['total_marks'] ?? json['total_questions']),
    courseId: _parseInt(json['course_id']),
    isPoll: json['is_poll'] == true || json['is_poll'] == 1,
  );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ─────────────────────────────────────────────
class QuizQuestion {
  final int? questionId;
  final String type; // 'mcq' | 'short' | 'fill'
  final String question;
  final String? optionA, optionB, optionC, optionD;
  final String? correctAnswer;

  const QuizQuestion({
    this.questionId,
    required this.type,
    required this.question,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    questionId: json['question_id'] is int ? json['question_id'] : null,
    type: _normalizeType(json['type'] ?? ''),
    question: json['question'] ?? '',
    optionA: json['option_a'],
    optionB: json['option_b'],
    optionC: json['option_c'],
    optionD: json['option_d'],
    correctAnswer: json['correct_answer']?.toString(),
  );

  static String _normalizeType(String t) {
    if (t == 'mcqs' || t == 'mcq') return 'mcq';
    if (t == 'short_questions' || t == 'short') return 'short';
    if (t == 'fill_blanks' || t == 'fill') return 'fill';
    return t;
  }
}

// ─────────────────────────────────────────────
class FullQuiz {
  final int quizId;
  final int courseId; // ← used to validate quiz belongs to current course
  final String quizCode;
  final String quizName;
  final String? description;
  final String quizDate;
  final String startTime;
  final String endTime;
  final int totalMarks;
  final bool isPoll;
  final List<QuizQuestion> questions;

  const FullQuiz({
    required this.quizId,
    this.courseId = 0,
    required this.quizCode,
    required this.quizName,
    this.description,
    required this.quizDate,
    required this.startTime,
    required this.endTime,
    required this.totalMarks,
    this.isPoll = false,
    required this.questions,
  });

  factory FullQuiz.fromJson(Map<String, dynamic> json) {
    // /api/quiz-attempt returns quiz data — questions may be nested
    // Try: json['quiz'] wrapper first, then flat
    final Map<String, dynamic> q =
        (json['quiz'] is Map ? json['quiz'] as Map<String, dynamic> : null) ?? json;

    // Questions can be under different keys
    List<dynamic> rawQuestions = [];
    if (q['questions'] is List && (q['questions'] as List).isNotEmpty) {
      rawQuestions = q['questions'] as List;
    } else if (json['questions'] is List && (json['questions'] as List).isNotEmpty) {
      rawQuestions = json['questions'] as List;
    } else if (q['mcqs'] is List || q['short_questions'] is List || q['fill_in_the_blank'] is List) {
      // Merge multiple question type arrays
      final mcqs   = (q['mcqs']               as List<dynamic>? ?? []);
      final shorts = (q['short_questions']     as List<dynamic>? ?? []);
      final fills  = (q['fill_in_the_blank']   as List<dynamic>? ?? []);
      rawQuestions = [...mcqs, ...shorts, ...fills];
    } else if (json['mcqs'] is List || json['short_questions'] is List) {
      final mcqs   = (json['mcqs']             as List<dynamic>? ?? []);
      final shorts = (json['short_questions']  as List<dynamic>? ?? []);
      final fills  = (json['fill_in_the_blank'] as List<dynamic>? ?? []);
      rawQuestions = [...mcqs, ...shorts, ...fills];
    }

    return FullQuiz(
      quizId:      _parseInt(q['id'] ?? json['id'] ?? q['quiz_id'] ?? json['quiz_id']),
      courseId:    _parseInt(q['course_id'] ?? json['course_id']),
      quizCode:    q['quiz_code']?.toString() ?? json['quiz_code']?.toString() ?? '',
      quizName:    q['quiz_name']?.toString() ?? json['quiz_name']?.toString() ?? '',
      description: q['description']?.toString() ?? json['description']?.toString(),
      quizDate:    q['quiz_date']?.toString()  ?? json['quiz_date']?.toString()  ?? '',
      startTime:   q['start_time']?.toString() ?? json['start_time']?.toString() ?? '',
      endTime:     q['end_time']?.toString()   ?? json['end_time']?.toString()   ?? '',
      totalMarks:  _parseInt(q['total_marks'] ?? json['total_marks'] ?? rawQuestions.length),
      isPoll:      q['is_poll'] == true || q['is_poll'] == 1,
      questions:   rawQuestions.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}