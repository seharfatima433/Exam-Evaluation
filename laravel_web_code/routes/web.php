<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\ChatbotController;

Route::get('/', function () {
    return redirect()->route('login');
});

// Authentication
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [AuthController::class, 'login'])->name('login.post');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Core Features
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

// Quiz Features
Route::get('/quiz/attempt/{code}', [QuizController::class, 'attempt'])->name('quiz.attempt');
Route::post('/quiz/submit', [QuizController::class, 'submit'])->name('quiz.submit');

// Chatbot Features
Route::get('/chatbot', [ChatbotController::class, 'index'])->name('chatbot');
Route::post('/chatbot/ask', [ChatbotController::class, 'ask'])->name('chatbot.ask');
