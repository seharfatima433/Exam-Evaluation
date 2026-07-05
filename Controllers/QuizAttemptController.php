<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Quiz;
use App\Models\QuizAttempt;

class QuizAttemptController extends Controller
{

    // ==========================================
    // STUDENT ENTER QUIZ CODE
    // ==========================================
    public function store(Request $request)
    {
        $request->validate([
            'quiz_code'  => 'required|string',
            'student_id' => 'required|integer|exists:exam_users,id',
        ]);

        // ==========================================
        // STUDENT FIND
        // ==========================================
        $student = DB::table('exam_users')
            ->where('id', $request->student_id)
            ->first();

        if (!$student) {
            return response()->json([
                'status'  => false,
                'message' => 'Student not found'
            ], 404);
        }

        // ==========================================
        // QUIZ FIND
        // ==========================================
        $quiz = Quiz::where('quiz_code', $request->quiz_code)->first();

        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz code invalid'
            ], 404);
        }

        // ==========================================
        // CHECK COURSE ASSIGNED - STUDENT MUST BE ENROLLED IN THE SPECIFIC COURSE
        // ==========================================
        $isEnrolledInQuizCourse = DB::table('course_user')
            ->where('user_id', $student->id)
            ->where('course_id', $quiz->course_id)
            ->exists();

        if (!$isEnrolledInQuizCourse) {
            return response()->json([
                'status'  => false,
                'message' => 'This quiz belongs to course ID: ' . $quiz->course_id . '. You are not enrolled in this course. Please contact your teacher.'
            ], 403);
        }

        // ==========================================
        // TIME CHECK — Pakistan Timezone
        // ==========================================
        $now = now('Asia/Karachi');

        $startDateTime = \Carbon\Carbon::parse(
            $quiz->quiz_date . ' ' . $quiz->start_time,
            'Asia/Karachi'
        );

        $endDateTime = \Carbon\Carbon::parse(
            $quiz->quiz_date . ' ' . $quiz->end_time,
            'Asia/Karachi'
        );

        // Handle midnight crossing
        if ($endDateTime->lt($startDateTime)) {
            $endDateTime->addDay();
        }

        if ($now->lt($startDateTime)) {
            return response()->json([
                'status'          => false,
                'message'         => 'Quiz not started yet',
                'quiz_start_time' => $startDateTime->format('H:i:s'),
            ]);
        }

        if ($now->gt($endDateTime)) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz time expired',
            ]);
        }

        // ==========================================
        // CHECK ALREADY SUBMITTED OR ABNORMAL EXIT (ABANDONED/STARTED)
        // ==========================================
        $existingAttempt = QuizAttempt::where('quiz_id', $quiz->id)
            ->where('student_id', $student->id)
            ->first();

        if ($existingAttempt) {
            if ($existingAttempt->status === 'submitted') {
                return response()->json([
                    'status'  => false,
                    'message' => 'You have already submitted this quiz'
                ], 403);
            }

            // Block reentry if they already have an attempt in progress/abandoned and teacher has not unlocked it
            if (!$existingAttempt->allowed_reentry) {
                return response()->json([
                    'status'      => false,
                    'quizStatus'  => 'locked',
                    'message'     => 'Re-entry Blocked! You left the quiz or switched tabs. Please ask your teacher to unlock your attempt.'
                ], 403);
            }
        }

        // ==========================================
        // LOAD QUIZ QUESTIONS
        // ==========================================
        $quiz->load('questions.options');

        $allQuestions = [];

        foreach ($quiz->questions as $q) {

            if ($q->type === 'mcq') {
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

        // ==========================================
        // SAVE OR UPDATE ATTEMPT
        // ==========================================
        $attempt = QuizAttempt::where('quiz_id', $quiz->id)
            ->where('student_id', $student->id)
            ->first();

        if (!$attempt) {
            $attempt = new QuizAttempt();
            $attempt->quiz_id = $quiz->id;
            $attempt->student_id = $student->id;
        }

        $attempt->student_name = $student->name;
        $attempt->student_identifier = $student->rollno;
        $attempt->quiz_code = $quiz->quiz_code;
        $attempt->course_name = $quiz->course_name ?? null;
        $attempt->loaded_at = now('Asia/Karachi');
        $attempt->last_active_at = now('Asia/Karachi');
        $attempt->status = 'started';
        $attempt->allowed_reentry = 0; // Reset to blocked
        $attempt->save();

        // ==========================================
        // SUCCESS
        // ==========================================
        return response()->json([
            'status'          => true,
            'message'         => 'Quiz loaded successfully',
            'quiz_id'         => $quiz->id,
            'course_id'       => $quiz->course_id,
            'quiz_name'       => $quiz->quiz_name,
            'quiz_code'       => $quiz->quiz_code,
            'quiz_date'       => $quiz->quiz_date,
            'start_time'      => $startDateTime->format('H:i:s'),
            'end_time'        => $endDateTime->format('H:i:s'),
            'is_poll'         => (bool) $quiz->is_poll,
            'total_questions' => count($allQuestions),
            'questions'       => $allQuestions,
            'attempt'         => [
                'attempt_id' => $attempt->id,
                'loaded_at'  => $attempt->loaded_at,
                'status'     => $attempt->status,
            ],
        ]);
    }

    // ==========================================
    // TRACK TAB SWITCH
    // ==========================================
    public function trackTabSwitch(Request $request)
    {
        \Illuminate\Support\Facades\Log::info('trackTabSwitch hit', $request->all());

        $request->validate([
            'quiz_id'    => 'required|integer|exists:quizzes,id',
            'student_id' => 'required|integer|exists:exam_users,id',
        ]);

        $attempt = QuizAttempt::where('quiz_id', $request->quiz_id)
            ->where('student_id', $request->student_id)
            ->first();

        if (!$attempt) {
            \Illuminate\Support\Facades\Log::warning('trackTabSwitch: attempt not found', $request->all());
            return response()->json([
                'status'  => false,
                'message' => 'Attempt not found'
            ], 404);
        }

        // Increment tab switch count and mark as abandoned
        $attempt->tab_switch_count = $attempt->tab_switch_count + 1;
        $attempt->status = 'abandoned';
        $attempt->allowed_reentry = 0;
        $attempt->save();

        \Illuminate\Support\Facades\Log::info('trackTabSwitch updated successfully', [
            'attempt_id' => $attempt->id,
            'tab_switch_count' => $attempt->tab_switch_count
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Tab switch tracked and attempt locked due to violation.',
            'tab_switch_count' => $attempt->tab_switch_count
        ]);
    }

    // ==========================================
    // TRACK SCREEN CLOSE / ABANDONED
    // ==========================================
    public function trackScreenClose(Request $request)
    {
        \Illuminate\Support\Facades\Log::info('trackScreenClose hit', $request->all());

        $request->validate([
            'quiz_id'    => 'required|integer|exists:quizzes,id',
            'student_id' => 'required|integer|exists:exam_users,id',
        ]);

        $attempt = QuizAttempt::where('quiz_id', $request->quiz_id)
            ->where('student_id', $request->student_id)
            ->first();

        if (!$attempt) {
            \Illuminate\Support\Facades\Log::warning('trackScreenClose: attempt not found', $request->all());
            return response()->json([
                'status'  => false,
                'message' => 'Attempt not found'
            ], 404);
        }

        // Only update if not already submitted
        if ($attempt->status !== 'submitted') {
            $attempt->status = 'abandoned';
            $attempt->allowed_reentry = 0; // Explicitly block re-entry
            $attempt->last_active_at = now('Asia/Karachi');
            $attempt->save();

            \Illuminate\Support\Facades\Log::info('trackScreenClose updated status to abandoned', [
                'attempt_id' => $attempt->id
            ]);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Screen close tracked'
        ]);
    }

    // ==========================================
    // UPDATE LAST ACTIVE (Heartbeat)
    // ==========================================
    public function updateHeartbeat(Request $request)
    {
        $request->validate([
            'quiz_id'    => 'required|integer|exists:quizzes,id',
            'student_id' => 'required|integer|exists:exam_users,id',
        ]);

        $attempt = QuizAttempt::where('quiz_id', $request->quiz_id)
            ->where('student_id', $request->student_id)
            ->first();

        if ($attempt) {
            $attempt->last_active_at = now('Asia/Karachi');
            $attempt->save();
        }

        return response()->json([
            'status' => true,
            'message' => 'Heartbeat updated'
        ]);
    }

    // ==========================================
    // MARK QUIZ AS SUBMITTED
    // ==========================================
    public function markSubmitted(Request $request)
    {
        $request->validate([
            'quiz_id'    => 'required|integer|exists:quizzes,id',
            'student_id' => 'required|integer|exists:exam_users,id',
        ]);

        $attempt = QuizAttempt::where('quiz_id', $request->quiz_id)
            ->where('student_id', $request->student_id)
            ->first();

        if ($attempt) {
            $attempt->status = 'submitted';
            $attempt->last_active_at = now('Asia/Karachi');
            $attempt->save();
        }

        return response()->json([
            'status' => true,
            'message' => 'Quiz marked as submitted'
        ]);
    }

    // ==========================================
    // TEACHER SEE QUIZ ATTEMPTS (with full tracking)
    // ==========================================
    public function index($quiz_code)
    {
        $quiz = Quiz::where('quiz_code', $quiz_code)->first();

        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found',
            ], 404);
        }

        // Get all enrolled students in the quiz course
        $enrolledStudents = DB::table('course_user')
            ->join('exam_users', 'course_user.user_id', '=', 'exam_users.id')
            ->where('course_user.course_id', $quiz->course_id)
            ->select([
                'exam_users.id as student_id',
                'exam_users.name as student_name',
                'exam_users.rollno as student_identifier'
            ])
            ->get();

        // Get all attempts for this quiz
        $attemptsMap = QuizAttempt::where('quiz_id', $quiz->id)
            ->get()
            ->keyBy('student_id');

        $now = now('Asia/Karachi');
        $report = [];

        foreach ($enrolledStudents as $student) {
            $attempt = $attemptsMap->get($student->student_id);

            if ($attempt) {
                $lastActive = \Carbon\Carbon::parse($attempt->last_active_at);
                $minutesDiff = $lastActive->diffInMinutes($now);
                
                $isActive = ($attempt->status === 'started' && $minutesDiff < 2);

                $report[] = [
                    'id'                 => $attempt->id,
                    'student_id'         => $student->student_id,
                    'student_name'       => $student->student_name,
                    'student_identifier' => $student->student_identifier,
                    'loaded_at'          => $attempt->loaded_at,
                    'last_active_at'     => $attempt->last_active_at,
                    'status'             => $attempt->status,
                    'tab_switch_count'   => $attempt->tab_switch_count,
                    'allowed_reentry'    => $attempt->allowed_reentry,
                    'is_active'          => $isActive,
                    'inactive_minutes'   => $minutesDiff,
                ];
            } else {
                // Not started yet
                $report[] = [
                    'id'                 => null,
                    'student_id'         => $student->student_id,
                    'student_name'       => $student->student_name,
                    'student_identifier' => $student->student_identifier,
                    'loaded_at'          => null,
                    'last_active_at'     => null,
                    'status'             => 'not_started',
                    'tab_switch_count'   => 0,
                    'allowed_reentry'    => 0,
                    'is_active'          => false,
                    'inactive_minutes'   => 0,
                ];
            }
        }

        // Sort: Active and Abandoned first, then not started, then submitted
        usort($report, function($a, $b) {
            $statusOrder = [
                'started'     => 1,
                'abandoned'   => 2,
                'not_started' => 3,
                'submitted'   => 4,
            ];
            $orderA = $statusOrder[$a['status']] ?? 9;
            $orderB = $statusOrder[$b['status']] ?? 9;
            return $orderA <=> $orderB;
        });

        // Calculate active count
        $activeCount = collect($report)->where('is_active', true)->count();

        return response()->json([
            'status'       => true,
            'quiz_code'    => $quiz_code,
            'quiz_name'    => $quiz->quiz_name,
            'course_id'    => $quiz->course_id,
            'total_loaded' => count($report),
            'active_count' => $activeCount,
            'attempts'     => $report,
        ]);
    }

    // ==========================================
    // TEACHER GET ACTIVE STUDENTS (Real-time)
    // ==========================================
    public function getActiveStudents($quiz_id)
    {
        // Verify quiz exists
        $quiz = Quiz::find($quiz_id);
        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found'
            ], 404);
        }

        $now = now('Asia/Karachi');
        $twoMinutesAgo = $now->copy()->subMinutes(2);

        $activeStudents = QuizAttempt::where('quiz_id', $quiz_id)
            ->where('status', 'started')
            ->where('last_active_at', '>=', $twoMinutesAgo)
            ->orderBy('last_active_at', 'desc')
            ->get([
                'id',
                'student_id',
                'student_name',
                'student_identifier',
                'loaded_at',
                'last_active_at',
                'tab_switch_count',
            ]);

        return response()->json([
            'status' => true,
            'quiz_id' => $quiz_id,
            'quiz_name' => $quiz->quiz_name,
            'course_id' => $quiz->course_id,
            'total_active' => $activeStudents->count(),
            'data' => $activeStudents
        ]);
    }

    // ==========================================
    // TEACHER GET ABANDONED STUDENTS
    // ==========================================
    public function getAbandonedStudents($quiz_id)
    {
        // Verify quiz exists
        $quiz = Quiz::find($quiz_id);
        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found'
            ], 404);
        }

        $abandonedStudents = QuizAttempt::where('quiz_id', $quiz_id)
            ->where('status', 'abandoned')
            ->orderBy('updated_at', 'desc')
            ->get([
                'id',
                'student_id',
                'student_name',
                'student_identifier',
                'loaded_at',
                'last_active_at',
                'tab_switch_count',
            ]);

        return response()->json([
            'status' => true,
            'quiz_id' => $quiz_id,
            'quiz_name' => $quiz->quiz_name,
            'course_id' => $quiz->course_id,
            'total_abandoned' => $abandonedStudents->count(),
            'data' => $abandonedStudents
        ]);
    }

    // ==========================================
    // TEACHER ALLOW RE-ENTRY (UNLOCK ATTEMPT)
    // ==========================================
    public function allowReentry(Request $request)
    {
        $request->validate([
            'attempt_id' => 'required|integer|exists:quiz_attempts,id',
        ]);

        $attempt = QuizAttempt::find($request->attempt_id);

        if (!$attempt) {
            return response()->json([
                'status'  => false,
                'message' => 'Attempt not found'
            ], 404);
        }

        // Get the associated quiz
        $quiz = Quiz::find($attempt->quiz_id);

        if (!$quiz) {
            return response()->json([
                'status'  => false,
                'message' => 'Quiz not found'
            ], 404);
        }

        // TIME CHECK — Teacher can only allow within scheduled time of quiz
        $now = now('Asia/Karachi');

        $startDateTime = \Carbon\Carbon::parse(
            $quiz->quiz_date . ' ' . $quiz->start_time,
            'Asia/Karachi'
        );

        $endDateTime = \Carbon\Carbon::parse(
            $quiz->quiz_date . ' ' . $quiz->end_time,
            'Asia/Karachi'
        );

        if ($endDateTime->lt($startDateTime)) {
            $endDateTime->addDay();
        }

        if ($now->lt($startDateTime) || $now->gt($endDateTime)) {
            return response()->json([
                'status'  => false,
                'message' => 'Cannot unlock attempt outside scheduled quiz time.'
            ], 403);
        }

        // Unlock for re-entry and reset status back to started
        $attempt->allowed_reentry = 1;
        $attempt->status = 'started';
        $attempt->save();

        return response()->json([
            'status'  => true,
            'message' => 'Attempt unlocked successfully. Student can now re-enter the quiz.'
        ]);
    }
}