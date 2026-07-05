<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Quiz;
use App\Models\Question;
use App\Models\Option;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class QuizController extends Controller
{
    // ===============================
    // Calculate Duration Helper
    // ===============================
    private function calculateDuration($start_time, $end_time)
    {
        $start = Carbon::parse($start_time);
        $end = Carbon::parse($end_time);
        
        if ($end->lt($start)) {
            $end->addDay();
        }
        
        return $end->diffInMinutes($start);
    }

    // ===============================
    // Save Quiz
    // ===============================
    public function saveQuiz(Request $request)
    {
        $request->validate([
            'quiz_name'   => 'required',
            'teacher_id'  => 'required',
            'course_id'   => 'required',
            'quiz_date'   => 'required|date',
            'start_time'  => 'required',
            'end_time'    => 'required',
            'questions'   => 'required|array',
            'total_marks' => 'nullable|numeric',
        ]);

        DB::beginTransaction();

        try {
            // Auto calculate duration
            $duration = $this->calculateDuration($request->start_time, $request->end_time);

            $quiz = Quiz::create([
                'quiz_code'       => strtoupper(Str::random(6)),
                'quiz_name'       => $request->quiz_name,
                'description'     => $request->description,
                'teacher_id'      => $request->teacher_id,
                'course_id'       => $request->course_id,
                'quiz_date'       => $request->quiz_date,
                'start_time'      => date('H:i:s', strtotime($request->start_time)),
                'end_time'        => date('H:i:s', strtotime($request->end_time)),
                'duration'        => $duration,
                'total_questions' => count($request->questions),
                'total_marks'     => $request->total_marks ?? count($request->questions),
                'difficulty'      => $request->difficulty ?? 'medium',
                'is_poll'         => $request->is_poll ?? false,
            ]);

            foreach ($request->questions as $q) {

                $type = strtolower($q['type'] ?? 'mcq');

                $typeMap = [
                    'mcqs'            => 'mcq',
                    'mcq'             => 'mcq',
                    'short_questions' => 'short',
                    'short'           => 'short',
                    'long_questions'  => 'long',
                    'long'            => 'long',
                    'fill_blanks'     => 'fill',
                    'fill'            => 'fill',
                ];

                $type = $typeMap[$type] ?? 'mcq';

                $question = Question::create([
                    'quiz_id'        => $quiz->id,
                    'type'           => $type,
                    'question'       => $q['question'],
                    'correct_answer' => $q['correct_answer'] ?? null,
                ]);

                if ($type === 'mcq') {

                    $options = [];

                    if (isset($q['option_a'])) {
                        $options = array_filter([
                            $q['option_a'] ?? null,
                            $q['option_b'] ?? null,
                            $q['option_c'] ?? null,
                            $q['option_d'] ?? null,
                        ]);
                    } elseif (isset($q['options'])) {
                        $options = array_values(array_filter((array) $q['options']));
                    }

                    foreach ($options as $opt) {
                        if (!empty(trim($opt))) {
                            Option::create([
                                'question_id' => $question->id,
                                'option_text' => $opt,
                            ]);
                        }
                    }
                }
            }

            DB::commit();

            return response()->json([
                'status'    => true,
                'message'   => 'Quiz saved successfully',
                'quiz_id'   => $quiz->id,
                'quiz_code' => $quiz->quiz_code,
                'duration'  => $duration,
                'is_poll'   => (bool) $quiz->is_poll,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status'  => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ===============================
    // STUDENT SIDE - Get Quiz by Code
    // ===============================
    public function getQuizByCode($code)
    {
        $quiz = Quiz::with('questions.options')
            ->where('quiz_code', $code)
            ->first();

        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found',
            ]);
        }

        // Auto calculate duration
        $duration = $this->calculateDuration($quiz->start_time, $quiz->end_time);

        $allQuestions = [];

        foreach ($quiz->questions as $q) {
            if ($q->type == 'mcq') {
                $allQuestions[] = [
                    'question_id'    => $q->id,
                    'type'           => $q->type,
                    'question'       => $q->question,
                    'option_a'       => $q->options[0]->option_text ?? null,
                    'option_b'       => $q->options[1]->option_text ?? null,
                    'option_c'       => $q->options[2]->option_text ?? null,
                    'option_d'       => $q->options[3]->option_text ?? null,
                    'correct_answer' => $q->correct_answer,
                ];
            } else {
                $allQuestions[] = [
                    'question_id'    => $q->id,
                    'type'           => $q->type,
                    'question'       => $q->question,
                    'correct_answer' => $q->correct_answer,
                ];
            }
        }

        return response()->json([
            'status'          => true,
            'quiz_id'         => $quiz->id,
            'quiz_code'       => $quiz->quiz_code,
            'quiz_name'       => $quiz->quiz_name,
            'description'     => $quiz->description,
            'quiz_date'       => $quiz->quiz_date,
            'start_time'      => date('H:i:s', strtotime($quiz->start_time)),
            'end_time'        => date('H:i:s', strtotime($quiz->end_time)),
            'duration'        => $duration,
            'is_poll'         => (bool) $quiz->is_poll,
            'total_questions' => count($allQuestions),
            'total_marks'     => $quiz->total_marks ?? count($allQuestions),
            'questions'       => $allQuestions,
        ]);
    }

    // ===============================
    // TEACHER SIDE - Get Quiz by Code
    // ===============================
    public function getQuizByCodeForTeacher($code)
    {
        $quiz = Quiz::with('questions.options')
            ->where('quiz_code', $code)
            ->first();

        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found',
            ]);
        }

        // Auto calculate duration
        $duration = $this->calculateDuration($quiz->start_time, $quiz->end_time);

        $allQuestions = [];

        foreach ($quiz->questions as $q) {
            if ($q->type == 'mcq') {
                $allQuestions[] = [
                    'question_id'    => $q->id,
                    'type'           => $q->type,
                    'question'       => $q->question,
                    'option_a'       => $q->options[0]->option_text ?? null,
                    'option_b'       => $q->options[1]->option_text ?? null,
                    'option_c'       => $q->options[2]->option_text ?? null,
                    'option_d'       => $q->options[3]->option_text ?? null,
                    'correct_answer' => $q->correct_answer,
                ];
            } else {
                $allQuestions[] = [
                    'question_id'    => $q->id,
                    'type'           => $q->type,
                    'question'       => $q->question,
                    'correct_answer' => $q->correct_answer,
                ];
            }
        }

        return response()->json([
            'status'          => true,
            'quiz_id'         => $quiz->id,
            'quiz_code'       => $quiz->quiz_code,
            'quiz_name'       => $quiz->quiz_name,
            'description'     => $quiz->description,
            'quiz_date'       => $quiz->quiz_date,
            'start_time'      => date('H:i:s', strtotime($quiz->start_time)),
            'end_time'        => date('H:i:s', strtotime($quiz->end_time)),
            'duration'        => $duration,
            'is_poll'         => (bool) $quiz->is_poll,
            'total_questions' => count($allQuestions),
            'total_marks'     => $quiz->total_marks ?? count($allQuestions),
            'questions'       => $allQuestions,
        ]);
    }

    // ===============================
    // GET COURSE QUIZZES
    // ===============================
    public function getCourseQuizzes($teacher_id, $course_id)
    {
        $quizzes = Quiz::where('teacher_id', $teacher_id)
            ->where('course_id', $course_id)
            ->orderBy('created_at', 'desc')
            ->get([
                'id',
                'quiz_code',
                'quiz_name',
                'description',
                'quiz_date',
                'start_time',
                'end_time',
                'difficulty',
                'total_questions',
                'total_marks',
                'course_id',
                'is_poll',
                'created_at',
            ]);

        // Add calculated duration to each quiz
        $quizzes->transform(function ($quiz) {
            $quiz->start_time = date('H:i:s', strtotime($quiz->start_time));
            $quiz->end_time   = date('H:i:s', strtotime($quiz->end_time));
            $quiz->duration   = $this->calculateDuration($quiz->start_time, $quiz->end_time);
            return $quiz;
        });

        return response()->json([
            'status'  => true,
            'quizzes' => $quizzes,
        ]);
    }
}