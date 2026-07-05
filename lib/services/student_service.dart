import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

// ══════════════════════════════════════════════════════════════════
// STUDENT SERVICE
// ══════════════════════════════════════════════════════════════════
class StudentService {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal() {
    HttpOverrides.global = _DevOverrides();
  }

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Safely decode JSON — throws FormatException if server returned HTML
  dynamic _safeDecode(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw const FormatException('Server returned a non-JSON response (HTML error page)');
    }
    return jsonDecode(response.body);
  }

  // ── GET /api/my-courses/{rollno} ──────────────────────────────
  Future<Map<String, dynamic>> fetchMyCourses(String rollNo) async {
    try {
      final url = ApiConstants.myCourses(rollNo);
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchMyCourses ${response.statusCode}: ${response.body}');
      final data = _safeDecode(response) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final List raw = data['courses'] ?? data['data'] ?? [];
        return {
          'success': true,
          'data': raw.map((c) => StudentCourse.fromJson(c)).toList(),
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Courses load nahi hue'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/admin/student-courses/{user_id} ──────────────────
  Future<Map<String, dynamic>> fetchStudentCoursesByUserId(int userId) async {
    try {
      final url = ApiConstants.studentCoursesByUserId(userId);
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchStudentCoursesByUserId ${response.statusCode}: ${response.body}');
      final data = _safeDecode(response) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final List raw = data['courses'] ?? data['data'] ?? [];
        return {
          'success': true,
          'data': raw.map((c) => StudentCourse.fromJson(c)).toList(),
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Courses load nahi hue'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/course-quizzes/0/{course_id} ────────────────────
  // Course ke scheduled quizzes fetch karo
  Future<List<StudentQuiz>> fetchCourseQuizzes(int courseId) async {
    try {
      // Try student-specific endpoint first
      final url = '${ApiConstants.baseUrl}/course-quizzes/0/$courseId';
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchCourseQuizzes[$courseId] ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        final data = _safeDecode(response) as Map<String, dynamic>;
        final List raw = data['quizzes'] ?? data['data'] ?? [];
        return raw.map((q) => StudentQuiz.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      print('[StudentService] fetchCourseQuizzes error: $e');
      return [];
    }
  }

  // ── POST /api/quiz-attempt ────────────────────────────────────
  // quiz_code + student_id → quiz data
  Future<Map<String, dynamic>> loadQuizAttempt({
    required String quizCode,
    required int studentId,
  }) async {
    try {
      final url = ApiConstants.quizAttempt;
      final body = jsonEncode({'quiz_code': quizCode, 'student_id': studentId});
      print('[StudentService] POST $url body: $body');
      final response = await http
          .post(Uri.parse(url), headers: _headers, body: body)
          .timeout(ApiConstants.quizTimeout);
      print('[StudentService] loadQuizAttempt status=${response.statusCode} body=${response.body}');
      final data = _safeDecode(response) as Map<String, dynamic>;
      final msg = data['message']?.toString() ?? '';

      // Only trust backend — if questions exist in response, open quiz
      // No local time check — backend decides if quiz is accessible
      final hasQuestions =
          (data['questions'] is List && (data['questions'] as List).isNotEmpty) ||
              (data['quiz'] is Map) ||
              (data['mcqs'] is List && (data['mcqs'] as List).isNotEmpty) ||
              data.containsKey('quiz_name');

      if (hasQuestions) {
        return {'success': true, 'data': data};
      }

      // No questions — backend blocked access
      // Show backend message directly, no custom logic
      String displayMsg = msg.isNotEmpty
          ? msg
          : 'Quiz is not available right now. Please try again later.';

      return {'success': false, 'message': displayMsg};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── POST /api/save-quiz ───────────────────────────────────────
  Future<Map<String, dynamic>> submitQuizAttempt(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(Uri.parse(ApiConstants.saveQuiz), headers: _headers, body: jsonEncode(payload))
          .timeout(ApiConstants.timeout);
      final data = _safeDecode(response) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': data};
      return {'success': false, 'message': data['message'] ?? 'Submit nahi hua'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/exam-quiz/{quiz_id}/{student_id} ─────────────────
  // Quiz code enter karne ke baad quiz & student info fetch karo
  Future<Map<String, dynamic>> fetchExamQuizInfo(int quizId, int studentId) async {
    try {
      final url = ApiConstants.examQuiz(quizId, studentId);
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchExamQuizInfo ${response.statusCode}: ${response.body}');
      
      // If server returns HTML or fails, we decode safely
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Quiz info load nahi hui (status ${response.statusCode})'};
      }
      
      final data = _safeDecode(response) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── POST /api/quiz/submit ─────────────────────────────────────
  // New submit API: {quiz_id, student_id, answers:{"qId":"A",...}}
  Future<Map<String, dynamic>> submitQuizNew({
    required int quizId,
    required int studentId,
    required Map<String, String> answers, // questionId -> letter (A/B/C/D)
  }) async {
    try {
      final payload = {
        'quiz_id': quizId,
        'student_id': studentId,
        'answers': answers,
      };
      final body = jsonEncode(payload);
      print('[StudentService] POST ${ApiConstants.quizSubmit} body: $body');
      final response = await http
          .post(Uri.parse(ApiConstants.quizSubmit), headers: _headers, body: body)
          .timeout(ApiConstants.timeout);
      print('[StudentService] submitQuizNew ${response.statusCode}: ${response.body}');
      final data = _safeDecode(response) as Map<String, dynamic>;
      final status = data['status'];
      if (response.statusCode == 200 && (status == true || status == 1)) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Quiz submit nahi hua',
        'data': data,
      };
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/quiz-attempts/{quiz_code} ────────────────────────
  // How many times student attempted this quiz
  Future<Map<String, dynamic>> fetchQuizAttemptsList(String quizCode) async {
    try {
      final url = '${ApiConstants.baseUrl}/quiz-attempts/$quizCode';
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchQuizAttemptsList status: ' + response.statusCode.toString());
      final data = _safeDecode(response);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Attempts load failed'};
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/quiz/result/{quiz_id}/{student_id} ───────────────
  Future<Map<String, dynamic>> fetchQuizResult(int quizId, int studentId) async {
    try {
      final url = '${ApiConstants.baseUrl}/quiz/result/$quizId/$studentId';
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchQuizResult ${response.statusCode}: ${response.body}');
      final data = _safeDecode(response) as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('[StudentService] fetchQuizResult error: $e');
      return {'status': false, 'message': 'Error: $e'};
    }
  }

  // ── GET /api/student/results/{student_id} or /api/student/{student_id}/{course_id} ───────────────
  Future<Map<String, dynamic>> fetchStudentResults(int studentId, {int? courseId}) async {
    try {
      final String url = courseId != null
          ? '${ApiConstants.baseUrl}/student/$studentId/$courseId'
          : ApiConstants.studentResults(studentId);
      print('[StudentService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConstants.timeout);
      print('[StudentService] fetchStudentResults status=${response.statusCode}');
      print('[StudentService] fetchStudentResults body=${response.body}');

      if (response.statusCode == 200) {
        final decoded = _safeDecode(response);
        // Return the full decoded payload — caller will parse flexibly
        return {'success': true, 'data': decoded};
      }

      try {
        final decoded = _safeDecode(response) as Map<String, dynamic>;
        return {'success': false, 'message': decoded['message'] ?? 'Failed to fetch results'};
      } catch (_) {
        return {'success': false, 'message': 'Failed to fetch results (status ${response.statusCode})'};
      }
    } catch (e) {
      print('[StudentService] fetchStudentResults error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── POST /api/quiz-attempt/tab-switch ───────────────────────────
  Future<Map<String, dynamic>> trackTabSwitch(int quizId, int studentId) async {
    try {
      final body = jsonEncode({'quiz_id': quizId, 'student_id': studentId});
      print('[StudentService] POST ${ApiConstants.quizTabSwitch} body: $body');
      final response = await http
          .post(Uri.parse(ApiConstants.quizTabSwitch), headers: _headers, body: body)
          .timeout(ApiConstants.timeout);
      print('[StudentService] trackTabSwitch status: ${response.statusCode} body: ${response.body}');
      final data = _safeDecode(response);
      return {'success': response.statusCode == 200, 'data': data};
    } catch (e) {
      print('[StudentService] trackTabSwitch error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── POST /api/quiz-attempt/screen-close ─────────────────────────
  Future<Map<String, dynamic>> trackScreenClose(int quizId, int studentId) async {
    try {
      final body = jsonEncode({'quiz_id': quizId, 'student_id': studentId});
      print('[StudentService] POST ${ApiConstants.quizScreenClose} body: $body');
      final response = await http
          .post(Uri.parse(ApiConstants.quizScreenClose), headers: _headers, body: body)
          .timeout(ApiConstants.timeout);
      print('[StudentService] trackScreenClose status: ${response.statusCode} body: ${response.body}');
      final data = _safeDecode(response);
      return {'success': response.statusCode == 200, 'data': data};
    } catch (e) {
      print('[StudentService] trackScreenClose error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── POST /api/quiz-attempt/heartbeat ────────────────────────────
  Future<Map<String, dynamic>> updateHeartbeat(int quizId, int studentId) async {
    try {
      final body = jsonEncode({'quiz_id': quizId, 'student_id': studentId});
      print('[StudentService] POST ${ApiConstants.quizHeartbeat} body: $body');
      final response = await http
          .post(Uri.parse(ApiConstants.quizHeartbeat), headers: _headers, body: body)
          .timeout(ApiConstants.timeout);
      print('[StudentService] updateHeartbeat status: ${response.statusCode} body: ${response.body}');
      final data = _safeDecode(response);
      return {'success': response.statusCode == 200, 'data': data};
    } catch (e) {
      print('[StudentService] updateHeartbeat error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── POST /api/quiz-attempt/submitted ────────────────────────────
  Future<Map<String, dynamic>> markSubmitted(int quizId, int studentId) async {
    try {
      final body = jsonEncode({'quiz_id': quizId, 'student_id': studentId});
      print('[StudentService] POST ${ApiConstants.quizMarkSubmitted} body: $body');
      final response = await http
          .post(Uri.parse(ApiConstants.quizMarkSubmitted), headers: _headers, body: body)
          .timeout(ApiConstants.timeout);
      print('[StudentService] markSubmitted status: ${response.statusCode} body: ${response.body}');
      final data = _safeDecode(response);
      return {'success': response.statusCode == 200, 'data': data};
    } catch (e) {
      print('[StudentService] markSubmitted error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

class _DevOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (_, __, ___) => true;
}

// ══════════════════════════════════════════════════════════════════
// MODEL: StudentCourse
// ══════════════════════════════════════════════════════════════════
class StudentCourse {
  final int id;
  final String courseTitle;
  final String? courseCode;

  const StudentCourse({
    required this.id,
    required this.courseTitle,
    this.courseCode,
  });

  factory StudentCourse.fromJson(Map<String, dynamic> json) => StudentCourse(
    id: _parseInt(json['id'] ?? json['course_id']),
    courseTitle: json['course_title'] ?? json['title'] ?? json['name'] ?? json['course_name'] ?? 'Unknown',
    courseCode: json['course_code']?.toString() ?? json['code']?.toString(),
  );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ══════════════════════════════════════════════════════════════════
// MODEL: StudentQuiz — quiz with time status
// ══════════════════════════════════════════════════════════════════
class StudentQuiz {
  final int id;
  final String quizCode;
  final String quizName;
  final String quizDate;
  final String startTime;
  final String endTime;
  final String difficulty;
  final int totalQuestions;
  final int totalMarks;
  final bool isPoll;

  const StudentQuiz({
    required this.id,
    required this.quizCode,
    required this.quizName,
    required this.quizDate,
    required this.startTime,
    required this.endTime,
    required this.difficulty,
    required this.totalQuestions,
    required this.totalMarks,
    this.isPoll = false,
  });

  factory StudentQuiz.fromJson(Map<String, dynamic> json) => StudentQuiz(
    id: _parseInt(json['id']),
    quizCode: json['quiz_code']?.toString() ?? json['code']?.toString() ?? '',
    quizName: json['quiz_name'] ?? json['name'] ?? json['title'] ?? '',
    quizDate: json['quiz_date'] ?? json['date'] ?? '',
    startTime: json['start_time'] ?? json['starts_at'] ?? '',
    endTime: json['end_time'] ?? json['ends_at'] ?? '',
    difficulty: json['difficulty'] ?? json['level'] ?? 'medium',
    totalQuestions: _parseInt(json['total_questions'] ?? json['questions_count'] ?? json['no_of_questions']),
    totalMarks: _parseInt(json['total_marks'] ?? json['total_questions'] ?? json['questions_count'] ?? json['no_of_questions']),
    isPoll: json['is_poll'] == true || json['is_poll'] == 1,
  );

  DateTime? get startDateTime => _parse(quizDate, startTime);
  DateTime? get endDateTime   => _parse(quizDate, endTime);

  QuizTimeStatus get timeStatus {
    final now   = DateTime.now();
    final start = startDateTime;
    final end   = endDateTime;
    if (start == null || end == null) return QuizTimeStatus.unknown;
    if (now.isBefore(start)) return QuizTimeStatus.upcoming;
    if (now.isAfter(end))    return QuizTimeStatus.expired;
    return QuizTimeStatus.active;
  }

  Duration get timeUntilStart {
    final start = startDateTime;
    if (start == null) return Duration.zero;
    final diff = start.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static DateTime? _parse(String date, String time) {
    if (date.isEmpty || time.isEmpty) return null;
    try { return DateTime.parse('$date $time'); } catch (_) { return null; }
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

enum QuizTimeStatus { upcoming, active, expired, unknown }