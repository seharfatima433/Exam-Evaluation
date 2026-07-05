<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ExamUser;

class ExamUserController extends Controller
{
    // Create User
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:exam_users,email',
            'password' => 'required',
            'role' => 'required|in:teacher,student,admin',
        ]);

        if ($request->role == 'student') {
            $request->validate([
                'rollno' => 'required'
            ]);
        }

        $user = ExamUser::create([
            'name'     => $request->name,
            'rollno'   => $request->role == 'student' ? $request->rollno : null,
            'email'    => $request->email,
            'password' => $request->password,
            'role'     => $request->role,
        ]);

        return response()->json([
            'message' => 'User created successfully',
            'data'    => $user
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'password' => 'required',
        ]);

        // Admin Login
        if ($request->email) {
            $user = ExamUser::where('email', $request->email)
                            ->where('role', 'admin')
                            ->first();

            if ($user && $user->password === $request->password) {
                return response()->json([
                    'message' => 'Admin Login Successfully',
                    'role'    => $user->role,
                    'user'    => $user
                ]);
            }
        }

        // Student Login
        if ($request->rollno) {
            $user = ExamUser::where('rollno', $request->rollno)
                            ->where('role', 'student')
                            ->first();

            if ($user && $user->password === $request->password) {
                return response()->json([
                    'message' => 'Student Login Successfully',
                    'role'    => $user->role,
                    'user'    => $user
                ]);
            }

            return response()->json([
                'message' => 'Invalid Roll No or Password'
            ], 401);
        }

        // Teacher Login
        if ($request->email) {
            $user = ExamUser::where('email', $request->email)
                            ->where('role', 'teacher')
                            ->first();

            if ($user && $user->password === $request->password) {
                return response()->json([
                    'message' => 'Teacher Login Successfully',
                    'role'    => $user->role,
                    'user'    => $user
                ]);
            }

            return response()->json([
                'message' => 'Invalid Email or Password'
            ], 401);
        }

        return response()->json([
            'message' => 'Please provide Roll No (for student) or Email (for teacher/admin)'
        ], 400);
    }

    // Student List
    public function students()
    {
        return ExamUser::where('role', 'student')->get();
    }

    // Teacher List  <-- ye missing tha
    public function teachers()
    {
        return ExamUser::where('role', 'teacher')->get();
    }

    // All Users List
    public function index()
    {
        return ExamUser::all();
    }
}