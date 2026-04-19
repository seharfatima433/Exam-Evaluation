import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quiz_model.dart';

/// Local SQFlite cache for quizzes fetched from the API.
/// Stores full quiz data (questions + answers) so they are
/// available offline and for the topic-suggestion feature.
class LocalQuizDb {
  static final LocalQuizDb _instance = LocalQuizDb._internal();
  factory LocalQuizDb() => _instance;
  LocalQuizDb._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'quiz_cache.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // Quizzes table – one row per quiz
        await db.execute('''
          CREATE TABLE quizzes (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            quiz_code   TEXT UNIQUE NOT NULL,
            quiz_name   TEXT NOT NULL,
            topic       TEXT NOT NULL,
            description TEXT,
            quiz_date   TEXT,
            start_time  TEXT,
            end_time    TEXT,
            difficulty  TEXT,
            course_id   INTEGER,
            teacher_id  INTEGER,
            cached_at   INTEGER
          )
        ''');

        // Questions table – one row per question, linked to quiz
        await db.execute('''
          CREATE TABLE questions (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            quiz_code      TEXT NOT NULL,
            type           TEXT NOT NULL,
            question       TEXT NOT NULL,
            option_a       TEXT,
            option_b       TEXT,
            option_c       TEXT,
            option_d       TEXT,
            correct_answer TEXT
          )
        ''');

        await db.execute(
            'CREATE INDEX idx_topic ON quizzes (topic COLLATE NOCASE)');
        await db.execute(
            'CREATE INDEX idx_qcode ON questions (quiz_code)');
      },
    );
  }

  // ── Insert / update a saved quiz (called after API save) ─────
  Future<void> cacheQuiz({
    required String quizCode,
    required String quizName,
    required String topic,
    required int courseId,
    required int teacherId,
    String? description,
    String? quizDate,
    String? startTime,
    String? endTime,
    String? difficulty,
    required List<Map<String, dynamic>> questions,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      // Upsert quiz row
      await txn.insert(
        'quizzes',
        {
          'quiz_code':   quizCode,
          'quiz_name':   quizName,
          'topic':       topic.toLowerCase().trim(),
          'description': description,
          'quiz_date':   quizDate,
          'start_time':  startTime,
          'end_time':    endTime,
          'difficulty':  difficulty,
          'course_id':   courseId,
          'teacher_id':  teacherId,
          'cached_at':   DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete old questions then re-insert
      await txn.delete('questions',
          where: 'quiz_code = ?', whereArgs: [quizCode]);

      for (final q in questions) {
        await txn.insert('questions', {
          'quiz_code':      quizCode,
          'type':           q['type'] ?? '',
          'question':       q['question'] ?? '',
          'option_a':       q['option_a'],
          'option_b':       q['option_b'],
          'option_c':       q['option_c'],
          'option_d':       q['option_d'],
          'correct_answer': q['correct_answer'] ?? q['answer'] ?? '',
        });
      }
    });
  }

  // ── Cache a FullQuiz fetched from the API (QuizViewScreen) ───
  Future<void> cacheFullQuiz(FullQuiz quiz, {int? teacherId}) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.insert(
        'quizzes',
        {
          'quiz_code':   quiz.quizCode,
          'quiz_name':   quiz.quizName,
          'topic':       quiz.quizName.toLowerCase().trim(), // best guess
          'description': quiz.description,
          'quiz_date':   quiz.quizDate,
          'start_time':  quiz.startTime,
          'end_time':    quiz.endTime,
          'difficulty':  null,
          'course_id':   null,
          'teacher_id':  teacherId,
          'cached_at':   DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // don't overwrite good data
      );

      // insert questions if not already there
      final existing = await txn.query('questions',
          where: 'quiz_code = ?', whereArgs: [quiz.quizCode]);
      if (existing.isEmpty) {
        for (final q in quiz.questions) {
          await txn.insert('questions', {
            'quiz_code':      quiz.quizCode,
            'type':           q.type,
            'question':       q.question,
            'option_a':       q.optionA,
            'option_b':       q.optionB,
            'option_c':       q.optionC,
            'option_d':       q.optionD,
            'correct_answer': q.correctAnswer ?? '',
          });
        }
      }
    });
  }

  // ── Search quizzes whose topic contains [query] ───────────────
  Future<List<CachedQuizMeta>> searchByTopic(String query) async {
    if (query.trim().isEmpty) return [];
    final database = await db;
    final rows = await database.query(
      'quizzes',
      where: 'topic LIKE ?',
      whereArgs: ['%${query.toLowerCase().trim()}%'],
      orderBy: 'cached_at DESC',
    );
    return rows.map(CachedQuizMeta.fromRow).toList();
  }

  // ── Fetch all questions for a quiz code ───────────────────────
  Future<List<Map<String, dynamic>>> getQuestions(String quizCode) async {
    final database = await db;
    return database.query('questions',
        where: 'quiz_code = ?', whereArgs: [quizCode]);
  }

  // ── Get a single cached quiz meta ─────────────────────────────
  Future<CachedQuizMeta?> getMeta(String quizCode) async {
    final database = await db;
    final rows = await database.query('quizzes',
        where: 'quiz_code = ?', whereArgs: [quizCode], limit: 1);
    if (rows.isEmpty) return null;
    return CachedQuizMeta.fromRow(rows.first);
  }
}

// ── Lightweight model for quiz list / search results ─────────────
class CachedQuizMeta {
  final String quizCode;
  final String quizName;
  final String topic;
  final String? difficulty;
  final String? quizDate;
  final int? totalQuestions; // loaded lazily if needed

  const CachedQuizMeta({
    required this.quizCode,
    required this.quizName,
    required this.topic,
    this.difficulty,
    this.quizDate,
    this.totalQuestions,
  });

  factory CachedQuizMeta.fromRow(Map<String, dynamic> row) =>
      CachedQuizMeta(
        quizCode:   row['quiz_code'] as String,
        quizName:   row['quiz_name'] as String,
        topic:      row['topic'] as String,
        difficulty: row['difficulty'] as String?,
        quizDate:   row['quiz_date'] as String?,
      );
}
