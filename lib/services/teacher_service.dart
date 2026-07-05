import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';

class TeacherService {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  // Helper for safe JSON decoding with content-type and try-catch protection
  dynamic _safeDecode(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw const FormatException('Invalid content type (not JSON)');
    }
    return jsonDecode(response.body);
  }

  // ── API 1: Fetch Teacher Courses ──────────
  Future<Map<String, dynamic>> fetchTeacherCourses(int teacherId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.teacherCourses(teacherId)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final dynamic decoded = _safeDecode(response);
        final List<dynamic> list = decoded is List ? decoded : [];
        final courses = list.map((c) => Course.fromJson(c)).toList();
        return {'success': true, 'data': courses};
      } else {
        return {'success': false, 'message': 'Server error (${response.statusCode})'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 2: Generate Quiz via Chatbot (with Polling) ──────
  Future<Map<String, dynamic>> generateQuiz(Map<String, dynamic> payload) async {
    try {
      // 1. Submit the generation job to the backend
      final response = await http
          .post(
        Uri.parse(ApiConstants.chatbot),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(ApiConstants.timeout); // Submission should be quick

      final data = _safeDecode(response);
      if (response.statusCode != 200 || data['status'] != true) {
        return {'success': false, 'message': data['message'] ?? 'Generation initiation failed'};
      }

      final jobId = data['job_id'] as String?;
      if (jobId == null || jobId.isEmpty) {
        return {'success': false, 'message': 'Invalid Job ID received from server'};
      }

      // 2. Poll the status endpoint until completed or timed out
      final startTime = DateTime.now();
      const pollInterval = Duration(seconds: 3);
      final maxDuration = ApiConstants.quizTimeout;

      while (DateTime.now().difference(startTime) < maxDuration) {
        await Future.delayed(pollInterval);

        try {
          final pollResponse = await http
              .get(
            Uri.parse(ApiConstants.generationStatus(jobId)),
            headers: {'Content-Type': 'application/json'},
          )
              .timeout(ApiConstants.timeout);

          if (pollResponse.statusCode == 200) {
            final pollData = _safeDecode(pollResponse);
            if (pollData['status'] == true) {
              final job = pollData['data'] as Map<String, dynamic>?;
              if (job != null) {
                final status = job['status'] as String?;
                if (status == 'completed') {
                  return {'success': true, 'data': job};
                } else if (status == 'failed') {
                  return {'success': false, 'message': job['message'] ?? 'Generation failed on server'};
                }
                // If status is 'processing', continue polling
              }
            }
          }
        } catch (e) {
          // If a single poll request fails (network glitch), don't abort immediately.
          // Just let the loop continue and try again.
        }
      }

      return {
        'success': false,
        'message': 'Quiz generation timed out. The server is still processing your request, please check again later or retry.'
      };
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The generation service is temporarily unavailable or returned an error page.',
        };
      }
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

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to save quiz (Server returned status ${response.statusCode})',
        };
      }

      final data = _safeDecode(response);
      if (data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Save failed'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 3b: Save Poll ─────────────────────
  Future<Map<String, dynamic>> savePoll(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.savePoll),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(ApiConstants.timeout);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to save poll (Server returned status ${response.statusCode})',
        };
      }

      final data = _safeDecode(response);
      if (data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Poll save failed'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
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

      final data = _safeDecode(response);
      if (response.statusCode == 200 && data['status'] == true) {
        final quizzes = (data['quizzes'] as List<dynamic>)
            .map((q) => QuizSummary.fromJson(q))
            .toList();
        return {'success': true, 'data': quizzes};
      } else {
        return {'success': false, 'message': 'No quizzes found'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 5: Student side ───────────────────
  Future<Map<String, dynamic>> fetchQuizByCode(String quizCode) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.quizByCode(quizCode)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      final data = _safeDecode(response);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': FullQuiz.fromJson(data)};
      } else {
        return {'success': false, 'message': 'Quiz not found'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 5b: Teacher side — /quiz/teacher/{code}
  Future<Map<String, dynamic>> fetchQuizByCodeTeacher(String quizCode) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.quizByCodeTeacher(quizCode)),
          headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      final data = _safeDecode(response);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': FullQuiz.fromJson(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Quiz not found'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 6: Fetch Quiz Attempts (Live Tracking) ──────────
  Future<Map<String, dynamic>> fetchQuizAttempts(String quizCode) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.quizAttemptsList(quizCode)),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConstants.timeout);

      final data = _safeDecode(response);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load tracking data'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server. The service is temporarily unavailable or returned an error page.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── API 7: Unlock Quiz Attempt (Allow Re-entry) ──────────
  Future<Map<String, dynamic>> unlockAttempt(int attemptId) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.unlockAttempt),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'attempt_id': attemptId,
            }),
          )
          .timeout(ApiConstants.timeout);

      final data = _safeDecode(response);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Attempt unlocked successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to unlock attempt'};
      }
    } catch (e) {
      if (e is FormatException) {
        return {
          'success': false,
          'message': 'Failed to parse response from server.',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }
}