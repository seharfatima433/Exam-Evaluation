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
  final String quizCode;
  final String quizName;
  final String? description;
  final String quizDate;
  final String startTime;
  final String endTime;
  final bool isPoll;
  final List<QuizQuestion> questions;

  const FullQuiz({
    required this.quizId,
    required this.quizCode,
    required this.quizName,
    this.description,
    required this.quizDate,
    required this.startTime,
    required this.endTime,
    this.isPoll = false,
    required this.questions,
  });

  factory FullQuiz.fromJson(Map<String, dynamic> json) => FullQuiz(
    quizId: _parseInt(json['quiz_id']),
    quizCode: json['quiz_code'] ?? '',
    quizName: json['quiz_name'] ?? '',
    description: json['description'],
    quizDate: json['quiz_date'] ?? '',
    startTime: json['start_time'] ?? '',
    endTime: json['end_time'] ?? '',
    isPoll: json['is_poll'] == true || json['is_poll'] == 1,
    questions: (json['questions'] as List<dynamic>? ?? [])
        .map((q) => QuizQuestion.fromJson(q))
        .toList(),
  );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
