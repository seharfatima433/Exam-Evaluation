class ApiConstants {
  static const String baseUrl =
      'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

  // ── ENDPOINTS ─────────────────────────────
  static const String login          = '$baseUrl/login';
  static const String chatbot        = '$baseUrl/chatbot';
  static const String saveQuiz       = '$baseUrl/save-quiz';
  static const String savePoll       = '$baseUrl/save-quiz'; // poll uses same endpoint as quiz

  static String teacherCourses(int teacherId)  => '$baseUrl/teacher-courses/$teacherId';
  static String courseQuizzes(int tid, int cid) => '$baseUrl/course-quizzes/$tid/$cid';
  static String quizByCode(String code)         => '$baseUrl/quiz/$code';

  // ── TIMEOUTS ──────────────────────────────
  static const Duration timeout = Duration(seconds: 200);
}
