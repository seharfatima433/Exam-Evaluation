import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';
import '../services/teacher_service.dart';
import '../services/local_quiz_db.dart';

enum LoadState { idle, loading, success, error }

// ── COURSE CONTROLLER ─────────────────────
class CourseController extends ChangeNotifier {
  final TeacherService _service = TeacherService();

  LoadState state = LoadState.idle;
  List<Course> courses = [];
  String? error;

  int get courseCount   => courses.length;
  int get totalStudents => courses.fold(0, (s, c) => s + (c.totalStudents ?? 0));

  Future<void> fetchTeacherCourses(int teacherId) async {
    state = LoadState.loading;
    error = null;
    notifyListeners();

    final result = await _service.fetchTeacherCourses(teacherId);

    if (result['success'] == true) {
      courses = result['data'] as List<Course>;
      state   = LoadState.success;
    } else {
      error = result['message'] as String?;
      state = LoadState.error;
    }
    notifyListeners();
  }
}

// ── QUIZ LIST CONTROLLER ──────────────────
class QuizListController extends ChangeNotifier {
  final TeacherService _service = TeacherService();

  LoadState state = LoadState.idle;
  List<QuizSummary> quizzes = [];
  String? error;

  Future<void> fetchCourseQuizzes(int teacherId, int courseId) async {
    state = LoadState.loading;
    error = null;
    notifyListeners();

    final result = await _service.fetchCourseQuizzes(teacherId, courseId);

    if (result['success'] == true) {
      quizzes = result['data'] as List<QuizSummary>;
      state   = LoadState.success;
    } else {
      error = result['message'];
      state = LoadState.error;
    }
    notifyListeners();
  }
}

// ── QUIZ VIEW CONTROLLER ──────────────────
// Fetches quiz from API and caches it locally in SQFlite.
class QuizViewController extends ChangeNotifier {
  final TeacherService _service = TeacherService();
  final LocalQuizDb    _local   = LocalQuizDb();

  LoadState state = LoadState.idle;
  FullQuiz? quiz;
  String?   error;

  Future<void> fetchQuiz(String code) async {
    state = LoadState.loading;
    error = null;
    notifyListeners();

    final result = await _service.fetchQuizByCode(code);

    if (result['success'] == true) {
      quiz  = result['data'] as FullQuiz;
      state = LoadState.success;
      // ── Cache to SQFlite in the background ──
      _local.cacheFullQuiz(quiz!).catchError((_) {});
    } else {
      error = result['message'];
      state = LoadState.error;
    }
    notifyListeners();
  }
}

// ── QUIZ CREATE CONTROLLER ────────────────
// After a successful saveQuiz API call, the quiz + its questions
// are written into the local SQFlite cache so topic-search works.
class QuizCreateController extends ChangeNotifier {
  final TeacherService _service = TeacherService();
  final LocalQuizDb    _local   = LocalQuizDb();

  LoadState generateState = LoadState.idle;
  LoadState saveState     = LoadState.idle;
  Map<String, dynamic>? generatedQuestions;
  String? generateError;
  String? saveError;
  String? savedQuizCode;

  // Keep a copy of the save payload so we can store it locally
  Map<String, dynamic>? _lastSavePayload;

  Future<void> generateQuiz(Map<String, dynamic> payload) async {
    generateState = LoadState.loading;
    generateError = null;
    notifyListeners();

    final result = await _service.generateQuiz(payload);

    if (result['success'] == true) {
      generatedQuestions = result['data']['questions'];
      generateState      = LoadState.success;
    } else {
      generateError = result['message'];
      generateState = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> saveQuiz(Map<String, dynamic> payload) async {
    saveState = LoadState.loading;
    saveError = null;
    _lastSavePayload = payload;
    notifyListeners();

    final result = await _service.saveQuiz(payload);

    if (result['success'] == true) {
      savedQuizCode = result['data']['quiz_code'];
      saveState     = LoadState.success;
      notifyListeners();

      // ── Cache quiz + questions locally ───────
      _cacheLocally(payload, savedQuizCode!).catchError((_) {});

      return true;
    } else {
      saveError = result['message'];
      saveState = LoadState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> savePoll(Map<String, dynamic> payload) async {
    saveState = LoadState.loading;
    saveError = null;
    _lastSavePayload = payload;
    notifyListeners();

    final result = await _service.savePoll(payload);

    if (result['success'] == true) {
      savedQuizCode = result['data']['quiz_code'] ?? result['data']['poll_code'];
      saveState     = LoadState.success;
      notifyListeners();

      // ── Cache poll questions locally (same schema) ──
      _cacheLocally(payload, savedQuizCode!).catchError((_) {});

      return true;
    } else {
      saveError = result['message'];
      saveState = LoadState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> _cacheLocally(
      Map<String, dynamic> payload, String quizCode) async {
    final rawQuestions = payload['questions'] as List<dynamic>? ?? [];
    final questions = rawQuestions
        .map((q) => Map<String, dynamic>.from(q as Map))
        .toList();

    await _local.cacheQuiz(
      quizCode:    quizCode,
      quizName:    payload['quiz_name'] ?? '',
      topic:       payload['topic']     ?? '',
      courseId:    payload['course_id'] ?? 0,
      teacherId:   payload['teacher_id'] ?? 0,
      description: payload['description'],
      quizDate:    payload['quiz_date'],
      startTime:   payload['start_time'],
      endTime:     payload['end_time'],
      difficulty:  payload['difficulty'],
      questions:   questions,
    );
  }

  void reset() {
    generateState      = LoadState.idle;
    saveState          = LoadState.idle;
    generatedQuestions = null;
    generateError      = null;
    saveError          = null;
    savedQuizCode      = null;
    _lastSavePayload   = null;
    notifyListeners();
  }
}
