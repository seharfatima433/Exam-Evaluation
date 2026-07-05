<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ExamUser;
use App\Models\Course;

class AdminController extends Controller
{
    // ===============================
    // Teacher Add
    // ===============================
    public function addTeacher(Request $request)
    {
        $request->validate([
            'name'     => 'required',
            'email'    => 'required|email|unique:exam_users,email',
            'password' => 'required',
        ]);

        $teacher = ExamUser::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => $request->password,
            'role'     => 'teacher',
            'rollno'   => null,
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Teacher added successfully',
            'data'    => $teacher
        ]);
    }

    // ===============================
    // Saare Teachers
    // ===============================
    public function getTeachers()
    {
        $teachers = ExamUser::where('role', 'teacher')
            ->get(['id', 'name', 'email']);

        return response()->json([
            'status'   => true,
            'teachers' => $teachers
        ]);
    }

    // ===============================
    // Saare Courses
    // ===============================
    public function getCourses()
    {
        $courses = Course::with('teacher:id,name')
            ->get(['id', 'course_title', 'course_code', 'teacher_id', 'is_active']);

        return response()->json([
            'status'  => true,
            'courses' => $courses
        ]);
    }

    // ===============================
    // Teacher ko Multiple Courses Assign
    // course_ids array mein do — sab update ho jayenge
    // ===============================
    public function assignCoursesToTeacher(Request $request)
    {
        $request->validate([
            'teacher_id'   => 'required|exists:exam_users,id',
            'course_ids'   => 'required|array',
            'course_ids.*' => 'exists:courses,id',
        ]);

        $teacher = ExamUser::where('id', $request->teacher_id)
            ->where('role', 'teacher')
            ->first();

        if (!$teacher) {
            return response()->json([
                'status'  => false,
                'message' => 'Selected user is not a teacher'
            ], 400);
        }

        // Saare selected courses mein teacher_id update karo
        Course::whereIn('id', $request->course_ids)
            ->update(['teacher_id' => $request->teacher_id]);

        $assignedCourses = Course::where('teacher_id', $request->teacher_id)
            ->get(['id', 'course_title', 'course_code']);

        return response()->json([
            'status'  => true,
            'message' => 'Courses assigned successfully',
            'teacher' => $teacher->name,
            'courses' => $assignedCourses
        ]);
    }

    // ===============================
    // Teacher se Course Hatao
    // teacher_id null kar do
    // ===============================
    public function removeCourseFromTeacher(Request $request)
    {
        $request->validate([
            'course_id' => 'required|exists:courses,id',
        ]);

        Course::where('id', $request->course_id)
            ->update(['teacher_id' => null]);

        return response()->json([
            'status'  => true,
            'message' => 'Course removed from teacher successfully',
        ]);
    }

    // ===============================
    // Ek Teacher ke Courses
    // ===============================
    public function getTeacherCourses($teacher_id)
    {
        $teacher = ExamUser::where('id', $teacher_id)
            ->where('role', 'teacher')
            ->first(['id', 'name', 'email']);

        if (!$teacher) {
            return response()->json([
                'status'  => false,
                'message' => 'Teacher not found'
            ], 404);
        }

        $courses = Course::where('teacher_id', $teacher_id)
            ->get(['id', 'course_title', 'course_code', 'is_active']);

        return response()->json([
            'status'  => true,
            'teacher' => $teacher->name,
            'courses' => $courses
        ]);
    }
        // ===============================
    // Student Add (Admin)
    // ===============================
    public function addStudent(Request $request)
    {
        $request->validate([
            'name'     => 'required',
            'email'    => 'required|email|unique:exam_users,email',
            'password' => 'required',
            'rollno'   => 'required|unique:exam_users,rollno',
        ]);

        $student = ExamUser::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => $request->password,
            'role'     => 'student',
            'rollno'   => $request->rollno,
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Student added successfully',
            'data'    => $student
        ]);
    }

    // ===============================
    // All Students (Admin View)
    // ===============================
    public function getStudents()
    {
        $students = ExamUser::where('role', 'student')
            ->get(['id', 'name', 'email', 'rollno']);

        return response()->json([
            'status'   => true,
            'students' => $students
        ]);
    }
}