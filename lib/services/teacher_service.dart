import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';

class TeacherService {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  // ── API 1: Fetch Teacher Courses ──────────
  Future<Map<String, dynamic>> fetchTeacherCourses(int teacherId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.teacherCourses(teacherId)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final courses = list.map((c) => Course.fromJson(c)).toList();
        return {'success': true, 'data': courses};
      } else {
        return {'success': false, 'message': 'Server error (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 2: Generate Quiz via Chatbot ──────
  Future<Map<String, dynamic>> generateQuiz(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.chatbot),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Generation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 3: Save Quiz ──────────────────────
  Future<Map<String, dynamic>> saveQuiz(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.saveQuiz),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(ApiConstants.timeout);

      // Guard: server might return HTML (404/500 page) instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}) — endpoint not found or server is down',
        };
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Save failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 3b: Save Poll ─────────────────────
  // Polls use the same /save-quiz endpoint (no separate poll route on backend).
  Future<Map<String, dynamic>> savePoll(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.savePoll),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(ApiConstants.timeout);

      // Guard: server might return HTML (404/500 page) instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}) — endpoint not found or server is down',
        };
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Poll save failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 4: Course Quizzes ─────────────────
  Future<Map<String, dynamic>> fetchCourseQuizzes(int teacherId, int courseId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.courseQuizzes(teacherId, courseId)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final quizzes = (data['quizzes'] as List<dynamic>)
            .map((q) => QuizSummary.fromJson(q))
            .toList();
        return {'success': true, 'data': quizzes};
      } else {
        return {'success': false, 'message': 'No quizzes found'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 5: Get Full Quiz by Code ──────────
  Future<Map<String, dynamic>> fetchQuizByCode(String quizCode) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.quizByCode(quizCode)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': FullQuiz.fromJson(data)};
      } else {
        return {'success': false, 'message': 'Quiz not found'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
