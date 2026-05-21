class ApiConstants {
  static const String baseUrl =
      'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

  // ── AUTH ──────────────────────────────────
  static const String login    = '$baseUrl/login';
  static const String chatbot  = '$baseUrl/chatbot';
  static const String saveQuiz = '$baseUrl/save-quiz';
  static const String savePoll = '$baseUrl/save-quiz';

  // ── TEACHER ───────────────────────────────
  static String teacherCourses(int teacherId)   => '$baseUrl/teacher-courses/$teacherId';
  static String courseQuizzes(int tid, int cid) => '$baseUrl/course-quizzes/$tid/$cid';
  static String quizByCode(String code)         => '$baseUrl/quiz/$code';
  static String quizByCodeTeacher(String code)  => '$baseUrl/quiz/teacher/$code';
  static String quizAttemptsList(String code)   => '$baseUrl/quiz-attempts/$code';
  static String examQuiz(int quizId, int studentId) => '$baseUrl/exam-quiz/$quizId/$studentId';
  static const String quizSubmit               = '$baseUrl/quiz/submit';

  // ── STUDENT ───────────────────────────────
  static String myCourses(String rollNo)           => '$baseUrl/my-courses/$rollNo';
  static String studentCoursesByUserId(int userId) => '$baseUrl/admin/student-courses/$userId';
  static const String assignCourse                 = '$baseUrl/admin/assign-course';
  static const String removeCourse                 = '$baseUrl/admin/remove-student-course';
  static const String quizAttempt                  = '$baseUrl/quiz-attempt';

  // ── TIMEOUTS ──────────────────────────────
  static const Duration timeout      = Duration(seconds: 120); // general
  static const Duration quizTimeout  = Duration(seconds: 180); // quiz/poll generation
}