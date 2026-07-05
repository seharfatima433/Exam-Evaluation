# AI-Based Quiz Evaluation System
### Technical Documentation — EduQuiz Application

---

## 1. Overview

This system evaluates student short-answer responses using a **2-Layer Hybrid Evaluation Model**. It combines traditional keyword-based matching with modern AI-powered semantic analysis to produce a fair, accurate, and context-aware score.

The goal is to move beyond simple right/wrong grading by understanding **what the student actually means**, even if they express it differently from the expected answer.

---

## 2. System Architecture

```
Student Submits Quiz
        │
        ▼
┌───────────────────────────────────────────┐
│         Question Type Router              │
└───────────────────────────────────────────┘
        │                   │
        ▼                   ▼
 MCQ / Fill-in-Blank    Short Answer
 (Exact Match)          (2-Layer AI)
        │                   │
        ▼                   ▼
   Binary Score      Layer 1 + Layer 2
  (1 correct,        (Proportional Score)
   0 wrong)
        │                   │
        └──────────┬─────────┘
                   ▼
         Final Result Saved
         to Database + Shown
         to Student
```

---

## 3. Question Types Supported

| Type | Evaluation Method | Scoring |
|------|-------------------|---------|
| **MCQ** (Multiple Choice) | Exact string match | Binary: 1 or 0 |
| **Fill in the Blank** | Case-insensitive exact match | Binary: 1 or 0 |
| **Short Answer** | 2-Layer AI Hybrid | Proportional: 0.0 to 1.0 |

---

## 4. Short Answer Evaluation — 2-Layer Model

### Layer 1: Keyword Matching (20% Weight)

The teacher enters expected keywords when creating a short-answer question in the database. These are stored as a comma-separated list (e.g., `overfitting, training, testing, bias, variance`).

When the student submits their answer, the system:
1. Splits the keyword string from the database
2. Checks if each keyword appears anywhere in the student's answer (case-insensitive)
3. Calculates a keyword score

**Formula:**
```
Keyword Score = (Number of Matched Keywords / Total Keywords) × 100
```

**Example:**
- Expected keywords: `overfitting, training, testing, bias` (4 total)
- Student used: `overfitting`, `training`, `testing` (3 matched)
- Keyword Score = (3/4) × 100 = **75%**

**Purpose:** Ensures important subject-specific terminology is present in the answer.

---

### Layer 2: AI Contextual Evaluation (80% Weight)

The student's answer, question, and expected keywords are sent to the **Claude AI model (Anthropic)** via API. The AI evaluates the answer based on:

| Criterion | Weight |
|-----------|--------|
| Concept understanding — Did the student grasp the core idea? | 70% |
| Semantic meaning — Is the meaning correct even with different words? | 20% |
| Keyword usage in context — Are terms used meaningfully? | 10% |

**Important AI Rules:**
- ✅ Grammar and spelling mistakes are **NOT penalized**
- ✅ Different wording with same meaning = **Good score**
- ✅ Short but accurate answers are rewarded (90+ score)
- ✅ Focus is purely on **conceptual correctness**

**AI Score Guide:**

| Score Range | Meaning |
|-------------|---------|
| 90–100 | Perfect understanding, concept fully correct |
| 70–89 | Good understanding, minor gaps |
| 50–69 | Partial understanding, some concept missing |
| 0–49 | Wrong concept or completely off topic |

---

## 5. Final Score Calculation

```
Final Score = (Keyword Score × 20%) + (AI Score × 80%)
```

**Example with real data:**

| | Score | Weight | Contribution |
|--|-------|--------|-------------|
| Layer 1 (Keywords) | 30% | 20% | 6.0 marks |
| Layer 2 (AI Eval) | 72% | 80% | 57.6 marks |
| **Final Score** | **63.6%** | — | — |

---

## 6. Proportional Marks System

Unlike traditional binary grading (fully correct = 1 mark, wrong = 0 marks), short-answer questions award **proportional marks** based on the final percentage score.

```
Marks Earned = Final Score (%) / 100
```

**Example:**

| Question | Type | Result | Marks Earned |
|----------|------|--------|-------------|
| Q1 — What is AI? | MCQ | Correct | 1.0 |
| Q2 — Define overfitting | Short Answer | 63.6% Final Score | 0.636 |
| Q3 — What is bias? | MCQ | Wrong | 0.0 |
| **Total** | | | **1.636 / 3** |

**Overall Percentage:**
```
Percentage = (Total Marks Earned / Total Questions) × 100
           = (1.636 / 3) × 100 = 54.5%
```

---

## 7. Why This Approach?

### Problem with Keyword-Only Grading

A student who writes:
> *"The model memorizes training data and fails to generalize to new data"*

should receive credit for understanding overfitting — even if the exact word `overfitting` was not used.

Traditional keyword matching would give this a **0%** because the keyword is missing.

### Problem with Binary Grading for Short Answers

Grading a conceptual answer as simply "correct" or "wrong" is unfair. A student with **partial understanding** (70% correct concept) should receive **partial marks**, not zero.

### Our Solution

The **2-Layer Model** solves both problems:
- **Keywords** ensure subject vocabulary is checked
- **AI** evaluates actual conceptual understanding
- **Proportional marks** reward partial knowledge fairly

---

## 8. Data Stored Per Question

For each short-answer question, the following is saved in the database:

| Field | Description | Example |
|-------|-------------|---------|
| `question` | The exam question | "Explain overfitting" |
| `student_answer` | Student's submitted answer | "In overfitting model..." |
| `expected_keywords` | Keywords from teacher | ["overfitting", "bias"] |
| `keyword_weight` | Weight for keyword layer | 20 |
| `ai_weight` | Weight for AI layer | 80 |
| `keyword_score` | Score from Layer 1 | 30.0 |
| `ai_score` | Score from Layer 2 (Claude AI) | 72.0 |
| `final_score` | Weighted combined score | 63.6 |
| `feedback` | AI-generated feedback text | "Good grasp of..." |
| `is_correct` | True if final_score ≥ 60% | true |

---

## 9. Technology Stack

| Component | Technology |
|-----------|------------|
| Backend API | Laravel (PHP) |
| AI Model | Claude AI by Anthropic |
| Mobile Frontend | Flutter (Dart) |
| Database | MySQL |
| Authentication | Token-based with SharedPreferences |

---

## 10. Student Result View

After the quiz ends, students can view their detailed results including:
- Overall percentage and score
- Per-question breakdown for short answers
- Keyword score vs AI score comparison
- AI-generated personalized feedback per question
- Color-coded pass (green) / fail (red) indicators

---

*Document prepared for EduQuiz AI Examination Evaluation System*
*June 2026*
