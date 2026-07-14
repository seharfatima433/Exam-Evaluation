@extends('layouts.app')

@section('content')
<div class="max-w-md mx-auto bg-white p-8 rounded-2xl shadow-xl mt-10 border border-gray-100">
    <h2 class="text-3xl font-extrabold mb-6 text-center text-indigo-700">Welcome Back</h2>
    
    @if($errors->any())
        <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6 rounded">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="POST" action="{{ route('login.post') }}">
        @csrf
        <div class="mb-5">
            <label class="block text-gray-700 font-medium mb-2">Email Address</label>
            <input type="email" name="email" required class="w-full border-2 border-gray-200 p-3 rounded-xl focus:outline-none focus:border-indigo-500 transition">
        </div>
        <div class="mb-6">
            <label class="block text-gray-700 font-medium mb-2">Password</label>
            <input type="password" name="password" required class="w-full border-2 border-gray-200 p-3 rounded-xl focus:outline-none focus:border-indigo-500 transition">
        </div>
        <button type="submit" class="w-full bg-indigo-600 text-white font-bold p-3 rounded-xl hover:bg-indigo-700 shadow-md transition transform hover:-translate-y-0.5">
            Login to Account
        </button>
    </form>
</div>
@endsection
