@extends('layouts.app')

@section('content')
<div class="max-w-4xl mx-auto bg-white p-8 rounded-2xl shadow-xl mt-5">
    <div class="flex justify-between items-center mb-6">
        <h2 class="text-3xl font-extrabold text-indigo-700">Quiz: {{ $quiz['quiz_title'] ?? 'Untitled Quiz' }}</h2>
        <div id="timer" class="text-xl font-bold text-red-600 bg-red-100 px-4 py-2 rounded-full">
            Time Left: 00:00
        </div>
    </div>

    <form method="POST" action="{{ route('quiz.submit') }}">
        @csrf
        <input type="hidden" name="quiz_id" value="{{ $quiz['id'] ?? '' }}">
        
        <!-- Display Questions here. This requires a loop over $quiz['questions'] -->
        <div class="space-y-6">
            @if(isset($quiz['questions']) && is_array($quiz['questions']))
                @foreach($quiz['questions'] as $index => $question)
                <div class="p-4 border rounded-lg bg-gray-50">
                    <h4 class="font-bold text-lg mb-3">{{ $index + 1 }}. {{ $question['question_text'] }}</h4>
                    <!-- Example options, adjust based on your API response structure -->
                    <div class="space-y-2">
                        <label class="flex items-center gap-2">
                            <input type="radio" name="answers[{{ $question['id'] }}]" value="A"> Option A
                        </label>
                        <label class="flex items-center gap-2">
                            <input type="radio" name="answers[{{ $question['id'] }}]" value="B"> Option B
                        </label>
                    </div>
                </div>
                @endforeach
            @else
                <p>No questions found in this quiz.</p>
            @endif
        </div>

        <div class="mt-8">
            <button type="submit" class="bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-8 rounded-xl shadow-lg transition w-full text-lg">
                Submit Quiz
            </button>
        </div>
    </form>
</div>

<!-- JavaScript for basic timer & Tab Switching prevention -->
<script>
    // Note: This is basic JS logic for Tab Switching. 
    // In a full production app, you will map this to the /quiz-attempt/tab-switch API
    document.addEventListener("visibilitychange", () => {
        if (document.visibilityState === 'hidden') {
            alert('Warning: Tab switching detected! This will be reported.');
            // Send API request here using JS fetch()
        }
    });
</script>
@endsection
