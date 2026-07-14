<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    private $baseUrl = 'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

    public function attempt($quizCode)
    {
        $user = Session::get('user');
        if (!$user) return redirect()->route('login');

        // Note: Real-time timer and tab-switching logic requires JavaScript on the frontend.
        // This controller sets up the view and passes the quiz data.
        $response = Http::withToken(Session::get('token'))->get($this->baseUrl . '/quiz/' . $quizCode);
        
        if ($response->successful()) {
            $quiz = $response->json();
            return view('quiz.attempt', compact('quiz', 'user'));
        }

        return back()->withErrors(['message' => 'Quiz not found or API error.']);
    }

    public function submit(Request $request)
    {
        // Submit quiz answers to the existing API
        $response = Http::withToken(Session::get('token'))->post($this->baseUrl . '/quiz/submit', $request->all());
        
        if ($response->successful()) {
            return redirect()->route('dashboard')->with('success', 'Quiz submitted successfully!');
        }

        return back()->withErrors(['message' => 'Failed to submit quiz.']);
    }
}
