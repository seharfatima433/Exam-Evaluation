<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EduQuiz Web Version</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-800 font-sans">
    <nav class="bg-indigo-600 text-white p-4 flex justify-between items-center shadow-lg">
        <div class="text-xl font-bold flex items-center gap-2">
            <span>✨</span> EduQuiz Web
        </div>
        @if(Session::has('user'))
            <div class="flex items-center gap-4">
                <span class="font-medium">{{ Session::get('user')['name'] ?? 'User' }}</span>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="bg-red-500 hover:bg-red-600 px-4 py-1.5 rounded-full text-sm font-bold transition">Logout</button>
                </form>
            </div>
        @endif
    </nav>
    <main class="p-8">
        @yield('content')
    </main>
</body>
</html>
