<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class QuizResultController extends Controller
{
    private $apiKey = 'YOUR_ANTHROPIC_API_KEY';

    // ✅ This model works with this API key (same as quiz generation controller)
    private $model  = 'claude-haiku-4-5-20251001';

    // ✅ Default weights: 20% keywords, 80% AI/context
    private $defaultKeywordWeight = 20;
    private $defaultAiWeight = 80;

    /*
    |-------------------------------------------------
    | SUBMIT QUIZ (WITH SHORT ANSWER AI CHECKING)
    |-------------------------------------------------
    */
    public function submitQuiz(Request $request)
    {
        set_time_limit(600);
        ini_set('memory_limit', '1G');
        ini_set('max_execution_time', 600);
        ini_set('max_input_time', 600);

        $request->validate([
            'quiz_id'    => 'required|exists:quizzes,id',
            'student_id' => 'required|exists:exam_users,id',
            'answers'    => 'required|array'
        ]);

        $quiz_id    = $request->quiz_id;
        $student_id = $request->student_id;
        $answers    = $request->answers;

        $quiz = DB::table('quizzes')->where('id', $quiz_id)->first();

        if (!$quiz) {
            return response()->json(['status' => false, 'message' => 'Quiz not found']);
        }

        $isEnrolled = DB::table('course_user')
            ->where('user_id', $student_id)
            ->where('course_id', $quiz->course_id)
            ->exists();

        if (!$isEnrolled) {
            return response()->json([
                'status'  => false,
                'message' => 'You are not enrolled in the course of this quiz. Cannot submit.'
            ], 403);
        }

        $course       = DB::table('courses')->where('id', $quiz->course_id)->first();
        $course_name  = $course ? $course->course_title : null;
        $subject_name = $course ? $course->course_title : 'General';

        $already = DB::table('quiz_results')
            ->where('quiz_id', $quiz_id)
            ->where('student_id', $student_id)
            ->exists();

        if ($already) {
            return response()->json(['status' => false, 'message' => 'Quiz already submitted']);
        }

        $questions = DB::table('questions')->where('quiz_id', $quiz_id)->get();

        if ($questions->isEmpty()) {
            return response()->json(['status' => false, 'message' => 'No questions found']);
        }

        $correct          = 0;    // integer — count of questions passed threshold (display)
        $wrong            = 0;    // integer — count of questions failed threshold (display)
        $totalScore       = 0.0;  // float  — accumulates proportional marks for percentage
        $shortAnswersData = [];

        foreach ($questions as $q) {
            $studentAnswer = $answers[$q->id] ?? null;

            if ($q->type == 'short') {
                $keywords      = array_map('trim', explode(',', $q->correct_answer));
                $keywordWeight = isset($q->keyword_weight) ? (int)$q->keyword_weight : $this->defaultKeywordWeight;
                $keywordWeight = max(20, min(80, $keywordWeight));
                $aiWeight      = 100 - $keywordWeight;

                $checkResult = $this->checkShortAnswer(
                    $q->question,
                    $studentAnswer,
                    $keywords,
                    $keywordWeight,
                    $aiWeight,
                    $subject_name
                );

                $shortAnswersData[] = [
                    'question_id'       => $q->id,
                    'question'          => $q->question,
                    'student_answer'    => $studentAnswer,
                    'expected_keywords' => $keywords,
                    'keyword_weight'    => $keywordWeight,
                    'ai_weight'         => $aiWeight,
                    'keyword_score'     => $checkResult['keyword_score'],
                    'ai_score'          => $checkResult['ai_score'],
                    'final_score'       => $checkResult['final_score'],
                    'feedback'          => $checkResult['feedback'],
                    'is_correct'        => $checkResult['final_score'] >= 60
                ];

                // ✅ Proportional: 66.4% AI score → 0.664 marks towards total
                $proportionalMark = $checkResult['final_score'] / 100;
                $totalScore += $proportionalMark;

                // For display counts: still show pass/fail threshold
                if ($checkResult['final_score'] >= 60) {
                    $correct++;
                } else {
                    $wrong++;
                }

            } elseif (in_array($q->type, ['mcq', 'fill'])) {
                if (strtoupper(trim((string)$studentAnswer)) == strtoupper(trim((string)$q->correct_answer))) {
                    $correct++;
                    $totalScore += 1.0;  // full 1 mark for correct MCQ/fill
                } else {
                    $wrong++;
                    // $totalScore += 0 (no marks for wrong MCQ)
                }
            }
        }

        $total      = $questions->count();
        // ✅ Percentage based on proportional totalScore (not binary correct count)
        $percentage = ($total > 0) ? ($totalScore / $total) * 100 : 0;

        // Calculate obtained score based on total_marks (proportional to percentage)
        $totalMarks = isset($quiz->total_marks) && $quiz->total_marks > 0 ? (float)$quiz->total_marks : $total;
        $obtainedScore = ($percentage / 100) * $totalMarks;

        $resultId = DB::table('quiz_results')->insertGetId([
            'quiz_id'             => $quiz_id,
            'student_id'          => $student_id,
            'course_id'           => $quiz->course_id,
            'course_name'         => $course_name,
            'total_questions'     => $total,
            'correct_answers'     => $correct,          // integer count (display)
            'wrong_answers'       => $wrong,             // integer count (display)
            'score'               => round($obtainedScore, 2),  // actual marks obtained
            'percentage'          => round($percentage, 2),
            'status'              => 'submitted',
            'submitted_at'        => now(),
            'is_result_published' => 0,
            'created_at'          => now(),
            'updated_at'          => now()
        ]);

        if (!empty($shortAnswersData)) {
            DB::table('quiz_results')
                ->where('id', $resultId)
                ->update(['short_answers_data' => json_encode($shortAnswersData)]);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Quiz submitted successfully',
            'data'    => [
                'quiz_id'       => $quiz_id,
                'quiz_code'     => $quiz->quiz_code,
                'student_id'    => $student_id,
                'course_id'     => $quiz->course_id,
                'course_name'   => $course_name,
                'status'        => 'submitted',
                'correct'       => $correct,
                'wrong'         => $wrong,
                'score'         => round($obtainedScore, 2),
                'total_marks'   => $totalMarks,
                'percentage'    => round($percentage, 2),
                'short_answers' => $shortAnswersData
            ]
        ]);
    }

    /*
    |-------------------------------------------------
    | SHORT ANSWER CHECKING (2-LAYER WITH DYNAMIC WEIGHT)
    |-------------------------------------------------
    */
    private function checkShortAnswer($question, $studentAnswer, $keywords, $keywordWeight, $aiWeight, $subject_name = 'General')
    {
        if (empty($studentAnswer)) {
            return [
                'keyword_score' => 0,
                'ai_score'      => 0,
                'final_score'   => 0,
                'feedback'      => 'No answer provided'
            ];
        }

        // Layer 1: Keyword Matching (from database)
        $keywordScore = $this->keywordMatch($studentAnswer, $keywords);

        // Layer 2: AI Contextual Evaluation (Claude API)
        $aiResult = $this->aiEvaluate($question, $studentAnswer, $keywords, $subject_name);

        $finalScore = ($keywordScore * $keywordWeight / 100) + ($aiResult['score'] * $aiWeight / 100);

        return [
            'keyword_score' => round($keywordScore, 2),
            'ai_score'      => $aiResult['score'],
            'final_score'   => round($finalScore, 2),
            'feedback'      => $aiResult['feedback']
        ];
    }

    /*
    |-------------------------------------------------
    | KEYWORD MATCHING (LAYER 1) — Database keywords
    |-------------------------------------------------
    */
    private function keywordMatch($answer, $keywords)
    {
        if (empty($keywords) || empty($answer)) return 0;

        $answerLower = strtolower($answer);
        $matched     = 0;

        foreach ($keywords as $keyword) {
            if (!empty($keyword) && strpos($answerLower, strtolower($keyword)) !== false) {
                $matched++;
            }
        }

        return ($matched / count($keywords)) * 100;
    }

    /*
    |-------------------------------------------------
    | AI EVALUATION — LAYER 2 (FIXED)
    | Fix 1: Correct model name
    | Fix 2: Strip markdown ```json``` blocks before json_decode
    | Fix 3: Log actual API error body so you can debug
    |-------------------------------------------------
    */
    private function aiEvaluate($question, $answer, $keywords, $subject_name = 'General')
    {
        if (empty($answer)) {
            return ['score' => 0, 'feedback' => 'No answer provided'];
        }

        $subject = trim($subject_name) ?: 'General';

        $prompt = "You are a {$subject} teacher evaluating a short answer.

Question: $question

Student Answer: $answer

Expected Keywords: " . implode(', ', $keywords) . "

IMPORTANT RULES:
1. DO NOT penalize grammar or spelling mistakes
2. Focus ONLY on concept correctness and understanding
3. Check if the student understood the main idea
4. Even if keywords are missing but concept is correct, give good score
5. Different wording, same meaning = GOOD score
6. LENGTH SHOULD NOT BE PENALIZED - Short answers can be perfect too!
7. If answer is short but accurate, give 90+ score

Score based on:
- Concept understanding (70% importance)
- Semantic meaning (20% importance)
- Keyword usage in context (10% importance)

Score Guide:
90-100: Perfect understanding, concept fully correct
70-89: Good understanding, minor gaps
50-69: Partial understanding, some concept missing
0-49: Wrong concept or completely off topic

Return ONLY valid JSON (no markdown, no explanation):
{\"score\": 0-100, \"feedback\": \"short feedback in 1-2 lines\"}";

        try {
            $response = Http::withHeaders([
                'x-api-key'         => $this->apiKey,
                'anthropic-version' => '2023-06-01',
                'content-type'      => 'application/json',
            ])->timeout(60)->post('https://api.anthropic.com/v1/messages', [
                'model'      => $this->model,
                'max_tokens' => 200,
                'messages'   => [
                    ['role' => 'user', 'content' => $prompt]
                ]
            ]);

            // ✅ FIX 3: Log the real error body if API call fails
            if (!$response->successful()) {
                $errorBody = $response->body();
                \Log::error('Claude API HTTP Error ' . $response->status() . ': ' . $errorBody);
                return [
                    'score'    => $this->keywordMatch($answer, $keywords),
                    'feedback' => 'AI error (' . $response->status() . '): ' . substr($errorBody, 0, 100)
                ];
            }

            $result  = $response->json();
            $content = $result['content'][0]['text'] ?? '';

            // ✅ FIX 2: Strip markdown code fences before decoding
            // Claude sometimes returns: ```json\n{"score":85,...}\n```
            $cleaned = trim($content);
            $cleaned = preg_replace('/^```(?:json)?\s*/i', '', $cleaned);
            $cleaned = preg_replace('/\s*```$/', '', $cleaned);
            $cleaned = trim($cleaned);

            $jsonData = json_decode($cleaned, true);

            if ($jsonData && isset($jsonData['score'])) {
                return [
                    'score'    => min(100, max(0, (int)$jsonData['score'])),
                    'feedback' => $jsonData['feedback'] ?? 'Evaluated by AI'
                ];
            }

            // Log if JSON still fails to parse after stripping
            \Log::warning('Claude JSON parse failed. Raw content: ' . $content);
            return [
                'score'    => $this->keywordMatch($answer, $keywords),
                'feedback' => 'AI response parse error. Keyword score used.'
            ];

        } catch (\Exception $e) {
            \Log::error('Claude API Exception: ' . $e->getMessage());
            return [
                'score'    => $this->keywordMatch($answer, $keywords),
                'feedback' => 'AI unavailable: ' . $e->getMessage()
            ];
        }
    }

    /*
    |-------------------------------------------------
    | SINGLE QUIZ RESULT
    |-------------------------------------------------
    */
    public function getResult($quiz_id, $student_id)
    {
        $quiz = DB::table('quizzes')->where('id', $quiz_id)->first();

        if (!$quiz) {
            return response()->json(['status' => false, 'message' => 'Quiz not found']);
        }

        $isEnrolled = DB::table('course_user')
            ->where('user_id', $student_id)
            ->where('course_id', $quiz->course_id)
            ->exists();

        if (!$isEnrolled) {
            return response()->json([
                'status'  => false,
                'message' => 'You are not enrolled in the course of this quiz. Cannot view result.'
            ], 403);
        }

        $quizEndDateTime = Carbon::parse($quiz->quiz_date . ' ' . $quiz->end_time);
        $currentTime     = Carbon::now('Asia/Karachi');

        if ($currentTime->lt($quizEndDateTime)) {
            return response()->json([
                'status'      => false,
                'message'     => 'Result will be available after quiz ends',
                'unlock_date' => $quiz->quiz_date,
                'unlock_time' => date('H:i:s', strtotime($quiz->end_time)),
                'server_time' => $currentTime->format('Y-m-d H:i:s')
            ]);
        }

        $result = DB::table('quiz_results')
            ->where('quiz_id', $quiz_id)
            ->where('student_id', $student_id)
            ->first();

        if (!$result) {
            return response()->json(['status' => false, 'message' => 'Result not found']);
        }

        if ($result->is_result_published == 0) {
            DB::table('quiz_results')
                ->where('id', $result->id)
                ->update(['is_result_published' => 1, 'updated_at' => now()]);
        }

        $shortAnswers = [];
        if (!empty($result->short_answers_data)) {
            $shortAnswers = json_decode($result->short_answers_data, true);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Result unlocked successfully',
            'data'    => [
                'quiz_id'              => $result->quiz_id,
                'quiz_code'            => $quiz->quiz_code,
                'quiz_name'            => $quiz->quiz_name,
                'student_id'           => $result->student_id,
                'course_id'            => $result->course_id,
                'course_name'          => $result->course_name,
                'total_questions'      => $result->total_questions,
                'correct_answers'      => $result->correct_answers,
                'wrong_answers'        => $result->wrong_answers,
                'score'                => $result->score,
                'total_marks'          => $quiz->total_marks ?? $result->total_questions,
                'percentage'           => $result->percentage,
                'submitted_at'         => Carbon::parse($result->submitted_at)->format('Y-m-d H:i:s'),
                'quiz_date'            => $quiz->quiz_date,
                'start_time'           => date('H:i:s', strtotime($quiz->start_time)),
                'end_time'             => date('H:i:s', strtotime($quiz->end_time)),
                'short_answers_detail' => $shortAnswers
            ]
        ]);
    }

    /*
    |-------------------------------------------------
    | ALL PAST RESULTS OF STUDENT (ALL ENROLLED COURSES)
    |-------------------------------------------------
    */
    public function getAllStudentResults($student_id)
    {
        $studentCourses = DB::table('course_user')
            ->where('user_id', $student_id)
            ->pluck('course_id')
            ->toArray();

        if (empty($studentCourses)) {
            return response()->json(['status' => false, 'message' => 'Student is not enrolled in any course']);
        }

        $results = DB::table('quiz_results')
            ->join('quizzes', 'quiz_results.quiz_id', '=', 'quizzes.id')
            ->where('quiz_results.student_id', $student_id)
            ->whereIn('quiz_results.course_id', $studentCourses)
            ->select(
                'quiz_results.id',
                'quiz_results.quiz_id',
                'quiz_results.student_id',
                'quiz_results.course_id',
                'quiz_results.course_name',
                'quiz_results.total_questions',
                'quiz_results.correct_answers',
                'quiz_results.wrong_answers',
                'quiz_results.score',
                'quiz_results.percentage',
                'quiz_results.status',
                'quiz_results.submitted_at',
                'quiz_results.is_result_published',
                'quiz_results.short_answers_data',
                'quizzes.quiz_code',
                'quizzes.quiz_name',
                'quizzes.total_marks',
                'quizzes.quiz_date',
                'quizzes.start_time',
                'quizzes.end_time'
            )
            ->orderBy('quiz_results.id', 'DESC')
            ->get();

        if ($results->isEmpty()) {
            return response()->json(['status' => false, 'message' => 'No past results found for your enrolled courses']);
        }

        $finalResults = [];

        foreach ($results as $result) {
            $quizEndDateTime = Carbon::parse($result->quiz_date . ' ' . $result->end_time);

            if (Carbon::now('Asia/Karachi')->gte($quizEndDateTime)) {
                if ($result->is_result_published == 0) {
                    DB::table('quiz_results')
                        ->where('id', $result->id)
                        ->update(['is_result_published' => 1, 'updated_at' => now()]);
                }

                $shortAnswers = [];
                if (!empty($result->short_answers_data)) {
                    $shortAnswers = json_decode($result->short_answers_data, true);
                }

                $finalResults[] = [
                    'quiz_id'         => $result->quiz_id,
                    'quiz_name'       => $result->quiz_name,
                    'quiz_code'       => $result->quiz_code,
                    'student_id'      => $result->student_id,
                    'course_id'       => $result->course_id,
                    'course_name'     => $result->course_name,
                    'total_questions' => $result->total_questions,
                    'correct_answers' => $result->correct_answers,
                    'wrong_answers'   => $result->wrong_answers,
                    'score'           => $result->score,
                    'total_marks'     => $result->total_marks ?? $result->total_questions,
                    'percentage'      => $result->percentage,
                    'quiz_date'       => $result->quiz_date,
                    'start_time'      => date('H:i:s', strtotime($result->start_time)),
                    'end_time'        => date('H:i:s', strtotime($result->end_time)),
                    'submitted_at'    => Carbon::parse($result->submitted_at)->format('Y-m-d H:i:s'),
                    'short_answers'   => $shortAnswers
                ];
            }
        }

        return response()->json([
            'status'           => true,
            'message'          => 'Past results fetched successfully for your enrolled courses',
            'enrolled_courses' => $studentCourses,
            'total_results'    => count($finalResults),
            'data'             => $finalResults
        ]);
    }

    /*
    |-------------------------------------------------
    | STUDENT RESULTS BY SPECIFIC COURSE
    |-------------------------------------------------
    */
    public function getStudentCourseResults($student_id, $course_id)
    {
        $isEnrolled = DB::table('course_user')
            ->where('user_id', $student_id)
            ->where('course_id', $course_id)
            ->exists();

        if (!$isEnrolled) {
            return response()->json([
                'status'  => false,
                'message' => 'You are not enrolled in this course. Cannot view results.'
            ], 403);
        }

        $course = DB::table('courses')->where('id', $course_id)->first();

        $results = DB::table('quiz_results')
            ->join('quizzes', 'quiz_results.quiz_id', '=', 'quizzes.id')
            ->where('quiz_results.student_id', $student_id)
            ->where('quiz_results.course_id', $course_id)
            ->select('quiz_results.*', 'quizzes.total_marks', 'quizzes.quiz_name', 'quizzes.quiz_code', 'quizzes.quiz_date', 'quizzes.start_time', 'quizzes.end_time')
            ->orderBy('quiz_results.id', 'DESC')
            ->get();

        if ($results->isEmpty()) {
            return response()->json(['status' => false, 'message' => 'No results found for this course']);
        }

        $finalResults = [];

        foreach ($results as $result) {
            $quizEndDateTime = Carbon::parse($result->quiz_date . ' ' . $result->end_time);

            if (Carbon::now('Asia/Karachi')->gte($quizEndDateTime)) {
                if ($result->is_result_published == 0) {
                    DB::table('quiz_results')
                        ->where('id', $result->id)
                        ->update(['is_result_published' => 1, 'updated_at' => now()]);
                }

                $shortAnswers = [];
                if (!empty($result->short_answers_data)) {
                    $shortAnswers = json_decode($result->short_answers_data, true);
                }

                $finalResults[] = [
                    'quiz_id'         => $result->quiz_id,
                    'quiz_name'       => $result->quiz_name,
                    'quiz_code'       => $result->quiz_code,
                    'student_id'      => $result->student_id,
                    'course_id'       => $result->course_id,
                    'course_name'     => $result->course_name,
                    'total_questions' => $result->total_questions,
                    'correct_answers' => $result->correct_answers,
                    'wrong_answers'   => $result->wrong_answers,
                    'score'           => $result->score,
                    'total_marks'     => $result->total_marks ?? $result->total_questions,
                    'percentage'      => $result->percentage,
                    'quiz_date'       => $result->quiz_date,
                    'start_time'      => date('H:i:s', strtotime($result->start_time)),
                    'end_time'        => date('H:i:s', strtotime($result->end_time)),
                    'submitted_at'    => Carbon::parse($result->submitted_at)->format('Y-m-d H:i:s'),
                    'short_answers'   => $shortAnswers
                ];
            }
        }

        return response()->json([
            'status'        => true,
            'message'       => 'Course results fetched successfully',
            'course_id'     => $course_id,
            'course_name'   => $course ? $course->course_title : null,
            'total_results' => count($finalResults),
            'data'          => $finalResults
        ]);
    }
}
