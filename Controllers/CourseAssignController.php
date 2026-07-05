<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CourseAssignController extends Controller
{

    // ✅ ASSIGN COURSE
    public function assignCourse(Request $request)
    {
        $request->validate([
            'course_id' => 'required|exists:courses,id',
            'user_ids' => 'nullable|array',
            'user_ids.*' => 'exists:exam_users,id',
            'user_id' => 'nullable|exists:exam_users,id',
        ]);

        // single + multiple users
        $userIds = $request->user_ids ?? ($request->user_id ? [$request->user_id] : []);

        if (empty($userIds)) {
            return response()->json([
                'status' => false,
                'message' => 'No students provided'
            ], 400);
        }

        foreach ($userIds as $user_id) {

            // check student role
            $user = DB::table('exam_users')
                ->where('id', $user_id)
                ->where('role', 'student')
                ->first();

            if (!$user) continue;

            // existing record check
            $record = DB::table('course_user')
                ->where('user_id', $user_id)
                ->where('course_id', $request->course_id)
                ->first();

            if ($record) {

                // increase count
                DB::table('course_user')
                    ->where('id', $record->id)
                    ->update([
                        'assign_count' => $record->assign_count + 1,
                        'updated_at' => now()
                    ]);

            } else {

                // first time assign
                DB::table('course_user')->insert([
                    'user_id' => $user_id,
                    'course_id' => $request->course_id,
                    'assign_count' => 1,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            }
        }

        return response()->json([
            'status' => true,
            'message' => 'Course assigned successfully'
        ]);
    }


    // ✅ LOGIN STUDENT COURSES
public function studentCourses($rollno)
{
    $courses = DB::table('course_user')
        ->join('exam_users', 'course_user.user_id', '=', 'exam_users.id')
        ->join('courses', 'course_user.course_id', '=', 'courses.id')
        ->where('exam_users.rollno', $rollno)
        ->select(
            'exam_users.name as student_name',
            'exam_users.rollno',
            'courses.id',
            'courses.course_title',
            'courses.course_code',
            'course_user.assign_count'
        )
        ->get();

    return response()->json([
        'status' => true,
        'courses' => $courses
    ]);
}

    // ✅ GET SPECIFIC STUDENT COURSES
    public function getStudentCourses($user_id)
    {
        $data = DB::table('course_user')
            ->join('exam_users', 'course_user.user_id', '=', 'exam_users.id')
            ->join('courses', 'course_user.course_id', '=', 'courses.id')
            ->where('course_user.user_id', $user_id)
            ->select(
                'exam_users.name as student_name',
                'courses.course_title',
                'courses.course_code',
                'course_user.assign_count'
            )
            ->get();

        return response()->json([
            'status' => true,
            'data' => $data
        ]);
    }


    // ✅ REMOVE COURSE
    public function removeCourse(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:exam_users,id',
            'course_id' => 'required|exists:courses,id',
        ]);

        $record = DB::table('course_user')
            ->where('user_id', $request->user_id)
            ->where('course_id', $request->course_id)
            ->first();

        if (!$record) {
            return response()->json([
                'status' => false,
                'message' => 'Course not found'
            ], 404);
        }

        // decrease count
        if ($record->assign_count > 1) {

            DB::table('course_user')
                ->where('id', $record->id)
                ->update([
                    'assign_count' => $record->assign_count - 1,
                    'updated_at' => now()
                ]);

            return response()->json([
                'status' => true,
                'message' => 'Assign count decreased'
            ]);
        }

        // delete record
        DB::table('course_user')
            ->where('id', $record->id)
            ->delete();

        return response()->json([
            'status' => true,
            'message' => 'Course removed completely'
        ]);
    }
}