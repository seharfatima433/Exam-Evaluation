<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    private $baseUrl = 'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

    public function index()
    {
        return view('chatbot.index');
    }

    public function ask(Request $request)
    {
        $response = Http::withToken(Session::get('token'))->post($this->baseUrl . '/chatbot', [
            'prompt' => $request->prompt,
            'type' => $request->type ?? 'quiz'
        ]);

        if ($response->successful()) {
            return response()->json($response->json());
        }

        return response()->json(['error' => 'AI Generation failed.'], 500);
    }
}
