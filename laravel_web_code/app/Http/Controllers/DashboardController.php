<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;

class DashboardController extends Controller
{
    private $baseUrl = 'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

    public function index()
    {
        $user = Session::get('user');
        if (!$user) return redirect()->route('login');

        // Role check from user object
        if (isset($user['role']) && strtolower($user['role']) == 'teacher') {
            // Fetch Teacher Courses via API
            $response = Http::withToken(Session::get('token'))
                            ->get($this->baseUrl . '/teacher-courses/' . $user['id']);
            $courses = $response->successful() ? $response->json()['courses'] ?? [] : [];
            return view('dashboard.teacher', compact('user', 'courses'));
        } else {
            // Student logic (e.g. results)
            $response = Http::withToken(Session::get('token'))
                            ->get($this->baseUrl . '/student/results/' . $user['id']);
            $results = $response->successful() ? $response->json()['results'] ?? [] : [];
            return view('dashboard.student', compact('user', 'results'));
        }
    }
}
