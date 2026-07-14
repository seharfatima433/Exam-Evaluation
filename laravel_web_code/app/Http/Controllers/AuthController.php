<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Session;

class AuthController extends Controller
{
    private $baseUrl = 'https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api';

    public function showLoginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $response = Http::post($this->baseUrl . '/login', [
            'email' => $request->email,
            'password' => $request->password,
            'fcm_token' => 'web_token_placeholder'
        ]);

        if ($response->successful()) {
            $data = $response->json();
            
            // API credentials ko Session mein save karein
            Session::put('user', $data['user']);
            Session::put('token', $data['token']);

            return redirect()->route('dashboard');
        }

        return back()->withErrors(['email' => 'Invalid credentials. API login failed.']);
    }

    public function logout()
    {
        Session::flush();
        return redirect()->route('login');
    }
}
