@extends('layouts.app')

@section('content')
<div class="max-w-5xl mx-auto">
    <div class="flex justify-between items-center mb-8">
        <h2 class="text-3xl font-bold text-gray-800">Student Dashboard</h2>
        <span class="bg-green-100 text-green-800 px-4 py-2 rounded-full font-bold">API Connected</span>
    </div>

    <h3 class="text-xl font-bold text-gray-700 mb-4">My Quiz Results</h3>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        @forelse($results as $result)
        <div class="bg-white p-6 rounded-2xl shadow-lg border-l-4 border-green-500 hover:shadow-xl transition flex justify-between items-center">
            <div>
                <h3 class="font-extrabold text-lg text-green-700">Quiz ID: {{ $result['quiz_id'] ?? 'N/A' }}</h3>
                <p class="text-gray-500 text-sm mt-1">Submitted Attempt</p>
            </div>
            <div class="text-2xl font-black text-gray-800">
                Score: {{ $result['score'] ?? '0' }}
            </div>
        </div>
        @empty
        <div class="col-span-2 bg-white p-6 rounded-2xl shadow text-center text-gray-500">
            No past results found for this student.
        </div>
        @endforelse
    </div>
</div>
@endsection
