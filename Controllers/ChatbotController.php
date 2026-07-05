<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Illuminate\Http\JsonResponse;

class ChatbotController extends Controller
{
    private $apiKey = 'YOUR_ANTHROPIC_API_KEY';
    private $model  = 'claude-haiku-4-5-20251001';

    // ═══════════════════════════════════════════════════
    //  Claude API call (with retry, max 3)
    // ═══════════════════════════════════════════════════
    private function callClaude(string $prompt, int $maxTokens = 8000): ?array
    {
        $attempt = 0;
        while ($attempt < 3) {
            $attempt++;
            try {
                $response = Http::timeout(90)
                    ->withHeaders([
                        'x-api-key'         => $this->apiKey,
                        'anthropic-version' => '2023-06-01',
                        'content-type'      => 'application/json',
                    ])
                    ->post('https://api.anthropic.com/v1/messages', [
                        'model'      => $this->model,
                        'max_tokens' => $maxTokens,
                        'messages'   => [
                            ['role' => 'user', 'content' => $prompt],
                        ],
                    ]);

                if ($response->successful()) {
                    $body = $response->json();
                    $text = $body['content'][0]['text'] ?? '';
                    $json = $this->extractJson($text);
                    if ($json !== null) {
                        return $json;
                    }
                }
                if ($response->status() === 429) {
                    sleep(5);
                }
            } catch (\Exception $e) {
                \Log::error("Claude API attempt {$attempt} failed: " . $e->getMessage());
                sleep(2);
            }
        }
        return null;
    }

    // ═══════════════════════════════════════════════════
    //  Extract JSON from Claude text response
    // ═══════════════════════════════════════════════════
    private function extractJson(string $text): ?array
    {
        $decoded = json_decode($text, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
            return $decoded;
        }
        if (preg_match('/```json\s*([\s\S]*?)\s*```/i', $text, $m)) {
            $decoded = json_decode($m[1], true);
            if (json_last_error() === JSON_ERROR_NONE) return $decoded;
        }
        if (preg_match('/(\{[\s\S]*\})/s', $text, $m)) {
            $decoded = json_decode($m[1], true);
            if (json_last_error() === JSON_ERROR_NONE) return $decoded;
        }
        return null;
    }

    // ═══════════════════════════════════════════════════
    //  POST /api/chatbot
    // ═══════════════════════════════════════════════════
    public function generateQuestions(Request $request): JsonResponse
    {
        set_time_limit(300);
        ignore_user_abort(true);

        $data = $request->validate([
            'topic'      => 'required|string|max:300',
            'difficulty' => 'nullable|string',
            'is_poll'    => 'nullable|boolean',
            'categories' => 'required|array',
        ]);

        $jobId  = (string) Str::uuid();
        $isPoll = (bool) ($data['is_poll'] ?? false);

        // Store initial "processing" state
        Cache::put("job_{$jobId}", [
            'status'    => 'processing',
            'is_poll'   => $isPoll,
            'message'   => 'Job is processing...',
            'questions' => null,
        ], now()->addHours(2));

        // Send response to client first, then process
        $responseData = json_encode([
            'status'  => true,
            'job_id'  => $jobId,
            'is_poll' => $isPoll,
            'message' => 'Job created. Check status with job_id',
        ]);

        http_response_code(200);
        header('Content-Type: application/json');
        header('Content-Length: ' . strlen($responseData));
        header('Connection: close');

        echo $responseData;

        if (function_exists('ob_end_flush')) {
            @ob_end_flush();
        }
        flush();

        if (function_exists('fastcgi_finish_request')) {
            fastcgi_finish_request();
        }

        // Now do the actual generation
        $this->doGeneration($jobId, $data);

        return response()->json([], 200)->header('X-Already-Sent', 'true');
    }

    // ═══════════════════════════════════════════════════
    //  Actual generation logic (runs after response sent)
    // ═══════════════════════════════════════════════════
    private function doGeneration(string $jobId, array $data): void
    {
        try {
            $topic      = $data['topic'];
            $difficulty = $data['difficulty'] ?? 'medium';
            $isPoll     = (bool) ($data['is_poll'] ?? false);
            $categories = $data['categories'];

            $mcqCount   = (int) ($categories['mcqs']            ?? 0);
            $shortCount = (int) ($categories['short_questions'] ?? 0);
            $fillCount  = (int) ($categories['fill_blanks']     ?? 0);

            $allQuestions = [
                'mcqs'            => [],
                'short_questions' => [],
                'fill_blanks'     => [],
            ];

            // ── 1. MCQs ──────────────────────────────────────
            if ($mcqCount > 0) {
                \Log::info("Job {$jobId}: Generating {$mcqCount} MCQs...");
                $mcqs = $this->generateMCQs($topic, $difficulty, $mcqCount, $isPoll);
                if ($mcqs !== null) {
                    $allQuestions['mcqs'] = $mcqs;
                }
                \Log::info("Job {$jobId}: MCQs done, got " . count($allQuestions['mcqs']));
            }

            // ── 2. Short Questions ────────────────────────────
            if ($shortCount > 0) {
                \Log::info("Job {$jobId}: Generating {$shortCount} short questions...");
                $shorts = $this->generateShortQuestions($topic, $difficulty, $shortCount);
                if ($shorts !== null) {
                    $allQuestions['short_questions'] = $shorts;
                }
                \Log::info("Job {$jobId}: Short done, got " . count($allQuestions['short_questions']));
            }

            // ── 3. Fill-in-the-Blanks ─────────────────────────
            if ($fillCount > 0) {
                \Log::info("Job {$jobId}: Generating {$fillCount} fill blanks...");
                $fills = $this->generateFillBlanks($topic, $difficulty, $fillCount);
                if ($fills !== null) {
                    $allQuestions['fill_blanks'] = $fills;
                }
                \Log::info("Job {$jobId}: Fill blanks done, got " . count($allQuestions['fill_blanks']));
            }

            $summary = [
                'mcqs'            => count($allQuestions['mcqs']),
                'short_questions' => count($allQuestions['short_questions']),
                'fill_blanks'     => count($allQuestions['fill_blanks']),
            ];

            Cache::put("job_{$jobId}", [
                'status'    => 'completed',
                'is_poll'   => $isPoll,
                'summary'   => $summary,
                'questions' => $allQuestions,
                'message'   => 'Generation completed!',
            ], now()->addHours(2));

            \Log::info("Job {$jobId}: COMPLETED. Summary: " . json_encode($summary));

        } catch (\Exception $e) {
            \Log::error("Job {$jobId} failed: " . $e->getMessage());
            Cache::put("job_{$jobId}", [
                'status'  => 'failed',
                'message' => 'Generation failed: ' . $e->getMessage(),
                'questions' => null,
            ], now()->addHours(2));
        }
    }

    // ═══════════════════════════════════════════════════
    //  GET /api/generation-status/{jobId}
    // ═══════════════════════════════════════════════════
    public function checkStatus(string $jobId): JsonResponse
    {
        $cached = Cache::get("job_{$jobId}");

        if ($cached === null) {
            return response()->json([
                'status'  => false,
                'message' => 'Job not found. It may have expired.',
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data'   => $cached,
        ]);
    }

    // ═══════════════════════════════════════════════════
    //  Generate MCQ questions in batches of 20
    // ═══════════════════════════════════════════════════
    private function generateMCQs(string $topic, string $difficulty, int $count, bool $isPoll = false): ?array
    {
        $pollNote = $isPoll
            ? 'These are for a poll — questions should be opinion or preference based.'
            : 'These are for an exam — questions should be knowledge or skill based.';

        $allMCQs = [];
        $batchSize = 20;
        $numBatches = ceil($count / $batchSize);

        for ($batch = 0; $batch < $numBatches; $batch++) {
            $currentCount = min($batchSize, $count - ($batch * $batchSize));
            $startNo = ($batch * $batchSize) + 1;

            $prompt = <<<PROMPT
Generate exactly {$currentCount} multiple choice questions about "{$topic}" at {$difficulty} difficulty.
{$pollNote}

Start the numbering from {$startNo}.
Return ONLY a valid JSON object — no explanation, no markdown, just JSON:
{
  "questions": [
    {
      "no": {$startNo},
      "question": "Question text?",
      "option_a": "Option A",
      "option_b": "Option B",
      "option_c": "Option C",
      "option_d": "Option D",
      "correct_answer": "A"
    }
  ]
}

Rules:
- correct_answer must be exactly one letter: A, B, C, or D
- Generate exactly {$currentCount} questions
- Questions must cover different aspects of the topic
PROMPT;

            $result = $this->callClaude($prompt, min(8000, $currentCount * 300));
            if ($result === null) {
                \Log::warning("MCQ generation batch " . ($batch + 1) . " returned null.");
                continue;
            }

            $questions = $result['questions'] ?? $result;
            if (is_array($questions)) {
                foreach ($questions as $q) {
                    if (!is_array($q) || empty($q['question'])) continue;
                    $allMCQs[] = [
                        'no'             => count($allMCQs) + 1,
                        'question'       => $q['question'],
                        'option_a'       => $q['option_a'] ?? ($q['options'][0] ?? ''),
                        'option_b'       => $q['option_b'] ?? ($q['options'][1] ?? ''),
                        'option_c'       => $q['option_c'] ?? ($q['options'][2] ?? ''),
                        'option_d'       => $q['option_d'] ?? ($q['options'][3] ?? ''),
                        'correct_answer' => strtoupper(trim($q['correct_answer'] ?? 'A')),
                    ];
                }
            }

            if ($batch < $numBatches - 1) {
                sleep(1);
            }
        }

        return empty($allMCQs) ? null : $allMCQs;
    }

    // ═══════════════════════════════════════════════════
    //  Generate Short Answer questions
    // ═══════════════════════════════════════════════════
    private function generateShortQuestions(string $topic, string $difficulty, int $count): ?array
    {
        $allShorts = [];
        $batchSize = 20;
        $numBatches = ceil($count / $batchSize);

        for ($batch = 0; $batch < $numBatches; $batch++) {
            $currentCount = min($batchSize, $count - ($batch * $batchSize));
            $startNo = ($batch * $batchSize) + 1;

            $prompt = <<<PROMPT
Generate exactly {$currentCount} short answer questions about "{$topic}" at {$difficulty} difficulty.

Start the numbering from {$startNo}.

Return ONLY a valid JSON object:
{
  "questions": [
    {
      "no": {$startNo},
      "question": "Question text?",
      "keywords": [
        "keyword1",
        "keyword2",
        "keyword3",
        "keyword4",
        "keyword5"
      ]
    }
  ]
}

Rules:
- Generate exactly {$currentCount} questions
- Do NOT generate complete answers
- Generate 5-10 important keywords/concepts for each question
- Keywords should represent the core concepts needed in a correct answer
PROMPT;

            $result = $this->callClaude($prompt, min(6000, $currentCount * 200));
            if ($result === null) {
                \Log::warning("Short questions generation batch " . ($batch + 1) . " returned null.");
                continue;
            }

            $questions = $result['questions'] ?? $result;
            if (is_array($questions)) {
                foreach ($questions as $q) {
                    if (!is_array($q) || empty($q['question'])) continue;
                    
                    // FIXED: Extracting keywords into correct_answer OR sending keywords directly!
                    $keywordsStr = (isset($q['keywords']) && is_array($q['keywords'])) ? implode(', ', $q['keywords']) : '';
                    $correctAnswer = $q['correct_answer'] ?? $q['answer'] ?? $keywordsStr;
                    
                    $allShorts[] = [
                        'no'             => count($allShorts) + 1,
                        'question'       => $q['question'],
                        'correct_answer' => $correctAnswer,
                        'keywords'       => $q['keywords'] ?? null,
                    ];
                }
            }

            if ($batch < $numBatches - 1) {
                sleep(1);
            }
        }

        return empty($allShorts) ? null : $allShorts;
    }

    // ═══════════════════════════════════════════════════
    //  Generate Fill-in-the-Blank questions
    // ═══════════════════════════════════════════════════
    private function generateFillBlanks(string $topic, string $difficulty, int $count): ?array
    {
        $allFills = [];
        $batchSize = 20;
        $numBatches = ceil($count / $batchSize);

        for ($batch = 0; $batch < $numBatches; $batch++) {
            $currentCount = min($batchSize, $count - ($batch * $batchSize));
            $startNo = ($batch * $batchSize) + 1;

            $prompt = <<<PROMPT
Generate exactly {$currentCount} fill-in-the-blank questions about "{$topic}" at {$difficulty} difficulty.

Start the numbering from {$startNo}.
Return ONLY a valid JSON object — no explanation, no markdown, just JSON:
{
  "questions": [
    {
      "no": {$startNo},
      "question": "The process of converting source code into machine code is called ______.",
      "correct_answer": "compilation"
    }
  ]
}

Rules:
- Each question must have exactly ONE blank shown as ______ (six underscores)
- correct_answer is the single word or short phrase that fills the blank
- Generate exactly {$currentCount} questions
- Questions must cover different aspects of the topic
PROMPT;

            $result = $this->callClaude($prompt, max(2000, $currentCount * 150));
            if ($result === null) {
                \Log::warning("Fill blanks generation batch " . ($batch + 1) . " returned null.");
                continue;
            }

            $questions = $result['questions'] ?? $result;
            if (is_array($questions)) {
                foreach ($questions as $q) {
                    if (!is_array($q) || empty($q['question'])) continue;
                    
                    $keywordsStr = (isset($q['keywords']) && is_array($q['keywords'])) ? implode(', ', $q['keywords']) : '';
                    $correctAnswer = $q['correct_answer'] ?? $q['answer'] ?? $keywordsStr;
                    
                    $allFills[] = [
                        'no'             => count($allFills) + 1,
                        'question'       => $q['question'],
                        'correct_answer' => $correctAnswer,
                        'keywords'       => $q['keywords'] ?? null,
                    ];
                }
            }

            if ($batch < $numBatches - 1) {
                sleep(1);
            }
        }

        return empty($allFills) ? null : $allFills;
    }
}