@extends('layouts.app')

@section('content')
<div class="max-w-5xl mx-auto">
    <div class="flex justify-between items-center mb-8">
        <h2 class="text-3xl font-bold text-gray-800">Teacher Dashboard</h2>
        <span class="bg-indigo-100 text-indigo-800 px-4 py-2 rounded-full font-bold">API Connected</span>
    </div>

    <h3 class="text-xl font-bold text-gray-700 mb-4">My Courses</h3>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        @forelse($courses as $course)
        <div class="bg-white p-6 rounded-2xl shadow-lg border-l-4 border-indigo-500 hover:shadow-xl transition">
            <h3 class="font-extrabold text-xl mb-2 text-indigo-700">{{ $course['course_name'] ?? 'Unnamed Course' }}</h3>
            <p class="text-gray-500 text-sm font-medium">Code: {{ $course['course_code'] ?? 'N/A' }}</p>
        </div>
        @empty
        <div class="col-span-3 bg-white p-6 rounded-2xl shadow text-center text-gray-500">
            No courses found for this teacher.
        </div>
        @endforelse
    </div>
</div>
@endsection
