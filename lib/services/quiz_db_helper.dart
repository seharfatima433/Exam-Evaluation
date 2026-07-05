import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuizDbHelper {
  static final QuizDbHelper instance = QuizDbHelper._init();
  static Database? _database;

  QuizDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quiz_drafts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const nullableIntegerType = 'INTEGER';

    await db.execute('''
CREATE TABLE quiz_drafts (
  id $idType,
  student_id $integerType,
  quiz_id $integerType,
  answers_json $textType,
  flagged_json $textType,
  current_index $integerType,
  end_time_ms $nullableIntegerType,
  UNIQUE(student_id, quiz_id)
)
''');
  }

  Future<void> saveDraft({
    required int studentId,
    required int quizId,
    required Map<int, String> answers,
    required List<int> flaggedQuestions,
    required int currentIndex,
    int? endTimeMs,
  }) async {
    final db = await instance.database;

    final stringAnswers = answers.map((k, v) => MapEntry(k.toString(), v));
    final answersJson = jsonEncode(stringAnswers);
    final flaggedJson = jsonEncode(flaggedQuestions);

    await db.insert(
      'quiz_drafts',
      {
        'student_id': studentId,
        'quiz_id': quizId,
        'answers_json': answersJson,
        'flagged_json': flaggedJson,
        'current_index': currentIndex,
        'end_time_ms': endTimeMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadDraft(int studentId, int quizId) async {
    final db = await instance.database;

    final maps = await db.query(
      'quiz_drafts',
      columns: ['answers_json', 'flagged_json', 'current_index', 'end_time_ms'],
      where: 'student_id = ? AND quiz_id = ?',
      whereArgs: [studentId, quizId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<void> clearDraft(int studentId, int quizId) async {
    final db = await instance.database;

    await db.delete(
      'quiz_drafts',
      where: 'student_id = ? AND quiz_id = ?',
      whereArgs: [studentId, quizId],
    );
  }
}
