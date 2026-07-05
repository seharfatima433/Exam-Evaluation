<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Quiz;
use App\Models\Course;
use App\Models\ExamUser;
use Illuminate\Support\Facades\DB;

class ExamQuizController extends Controller
{
    /*
    |-----------------------------------------
    | QUIZ OPEN (ATTEMPT SAVE ONLY)
    |-----------------------------------------
    */
    public function index($quiz_id, $student_id)
{
    $quiz = Quiz::findOrFail($quiz_id);

    $course = Course::find($quiz->course_id);

    $user = ExamUser::find($student_id);

    if (!$user) {
        return response()->json([
            'status' => false,
            'message' => 'Student not found'
        ]);
    }

    DB::table('quiz_attempts')->updateOrInsert(
        [
            'quiz_id' => $quiz->id,
            'student_id' => $student_id
        ],
        [
            'student_name' => $user->name ?? null,
            'student_identifier' => $user->rollno ?? null,
            'course_name' => $course->course_title ?? null,
            'quiz_code' => $quiz->quiz_code ?? null,
            'loaded_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]
    );

    return response()->json([
        'status' => true,
        'user_name' => $user->name ?? null,
        'roll_no' => $user->rollno ?? null,
        'course_name' => $course ? $course->course_title : 'Course Not Found',
        'quiz_code' => $quiz->quiz_code,
    ]);
}

    /*
    |-----------------------------------------
    | START QUIZ (OPTIONAL - SIMPLE RESPONSE)
    |-----------------------------------------
    */
    public function store(Request $request)
{
    $user = ExamUser::where('rollno', $request->roll_no)->first();
    $quiz = Quiz::where('quiz_code', $request->quiz_code)->first();

    if (!$user || !$quiz) {
        return response()->json([
            'status' => false,
            'message' => 'Student or Quiz not found'
        ]);
    }

    return response()->json([
        'status' => true,
        'message' => 'Quiz Started Successfully'
    ]);
}
}