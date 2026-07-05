<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Course;
use App\Models\ExamUser;

class CourseController extends Controller
{
    // Create Course (Teacher ko assign karega)
    public function store(Request $request)
    {
        $request->validate([
            'course_title' => 'required',
            'course_code' => 'required|unique:courses,course_code',
            'teacher_id' => 'required|exists:exam_users,id'
        ]);

        $teacher = ExamUser::where('id', $request->teacher_id)
                            ->where('role', 'teacher')
                            ->first();

        if (!$teacher) {
            return response()->json(['message' => 'Invalid Teacher'], 400);
        }

        $course = Course::create([
            'course_title' => $request->course_title,
            'course_code' => $request->course_code,
            'teacher_id' => $request->teacher_id,
            'description' => $request->description,
        ]);

        return response()->json([
            'message' => 'Course created successfully',
            'course' => $course
        ]);
    }

    // Show only logged-in teacher courses
    public function teacherCourses($teacher_id)
    {
        $courses = Course::where('teacher_id', $teacher_id)->get();

        return response()->json($courses);
    }
}