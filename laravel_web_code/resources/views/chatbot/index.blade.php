@extends('layouts.app')

@section('content')
<div class="max-w-4xl mx-auto bg-white p-8 rounded-2xl shadow-xl mt-5 h-[80vh] flex flex-col">
    <div class="flex justify-between items-center mb-6">
        <h2 class="text-3xl font-extrabold text-indigo-700">AI Chatbot (Quiz Generator)</h2>
        <span class="bg-purple-100 text-purple-800 px-4 py-2 rounded-full font-bold text-sm">Powered by Llama/Groq</span>
    </div>

    <!-- Chat History -->
    <div id="chat-history" class="flex-1 border p-4 rounded-xl overflow-y-auto bg-gray-50 space-y-4 mb-4">
        <div class="bg-indigo-100 p-3 rounded-lg w-3/4">
            Hello! I am your AI assistant. What kind of quiz would you like to generate today?
        </div>
    </div>

    <!-- Chat Input -->
    <div class="flex gap-2">
        <input type="text" id="prompt" class="flex-1 border-2 border-gray-300 p-3 rounded-xl focus:outline-none focus:border-indigo-500" placeholder="Type your prompt here... e.g. Create a quiz on Flutter">
        <button onclick="sendPrompt()" class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-6 rounded-xl shadow-lg transition">
            Send Prompt
        </button>
    </div>
</div>

<script>
    function sendPrompt() {
        const prompt = document.getElementById('prompt').value;
        if(!prompt) return;

        // Add to history
        const history = document.getElementById('chat-history');
        history.innerHTML += `<div class="bg-white border p-3 rounded-lg w-3/4 ml-auto text-right mb-2 shadow-sm">${prompt}</div>`;
        document.getElementById('prompt').value = '';

        // Add loading indicator
        history.innerHTML += `<div id="loading" class="text-gray-500 italic mt-2">AI is thinking...</div>`;
        history.scrollTop = history.scrollHeight;

        // Call API
        fetch("{{ route('chatbot.ask') }}", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-TOKEN": "{{ csrf_token() }}"
            },
            body: JSON.stringify({ prompt: prompt })
        })
        .then(res => res.json())
        .then(data => {
            document.getElementById('loading').remove();
            // Handle generation-status/jobId or final response here
            history.innerHTML += `<div class="bg-indigo-100 p-3 rounded-lg w-3/4 mt-2">Generation started! Check dashboard.</div>`;
            history.scrollTop = history.scrollHeight;
        });
    }
</script>
@endsection
