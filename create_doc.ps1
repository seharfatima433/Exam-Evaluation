Add-Type -AssemblyName System.IO.Compression.FileSystem

$outputPath = "D:\flutter projects\ai_exam_evaluation\Quiz_Checking_Explanation.docx"
$tempDir    = "D:\flutter projects\ai_exam_evaluation\_docx_temp"

# Clean up and recreate temp directory
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path "$tempDir\_rels"          | Out-Null
New-Item -ItemType Directory -Path "$tempDir\word"           | Out-Null
New-Item -ItemType Directory -Path "$tempDir\word\_rels"     | Out-Null
New-Item -ItemType Directory -Path "$tempDir\word\theme"     | Out-Null
New-Item -ItemType Directory -Path "$tempDir\docProps"       | Out-Null

# [Content_Types].xml
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml"  ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml"   ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@ | Set-Content "$tempDir\[Content_Types].xml" -Encoding UTF8

# _rels/.rels
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@ | Set-Content "$tempDir\_rels\.rels" -Encoding UTF8

# word/_rels/document.xml.rels
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@ | Set-Content "$tempDir\word\_rels\document.xml.rels" -Encoding UTF8

# word/styles.xml
@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:pPr><w:outlineLvl w:val="0"/><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:pPr><w:outlineLvl w:val="1"/><w:spacing w:before="200" w:after="80"/></w:pPr>
    <w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr>
  </w:style>
</w:styles>
'@ | Set-Content "$tempDir\word\styles.xml" -Encoding UTF8

# Helper to make a paragraph XML
function Para($text, $style="Normal", $bold=$false, $italic=$false, $size=22) {
    $bTag   = if ($bold)   { "<w:b/>" }   else { "" }
    $iTag   = if ($italic) { "<w:i/>" }   else { "" }
    $styleTag = "<w:pStyle w:val=`"$style`"/>"
    return "<w:p><w:pPr>$styleTag</w:pPr><w:r><w:rPr>$bTag$iTag<w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/></w:rPr><w:t xml:space=`"preserve`">$text</w:t></w:r></w:p>"
}

function EmptyPara() {
    return "<w:p><w:pPr><w:pStyle w:val=`"Normal`"/></w:pPr></w:p>"
}

# Build document body
$body = @()

$body += Para "AI-Based Quiz Checking System" "Heading1"
$body += Para "How Short Answer Questions Are Evaluated" "Normal" $false $true 22
$body += EmptyPara

$body += Para "Overview" "Heading2"
$body += Para "Short answer questions in this system are checked using a 2-Layer Hybrid Evaluation Method. The student answer is evaluated in two stages: first by matching keywords from the database, and then by an AI model that understands the meaning and concept of the answer."
$body += EmptyPara

$body += Para "Layer 1 - Keyword Matching  (20% Weight)" "Heading2"
$body += Para "The teacher defines a list of expected keywords when creating a question (e.g., overfitting, training, testing, bias). When the student submits an answer, the system counts how many of those keywords appear in the response."
$body += EmptyPara
$body += Para "Formula:" "Normal" $true
$body += Para "Keyword Score = (Matched Keywords / Total Keywords) x 100"
$body += EmptyPara
$body += Para "Example:" "Normal" $true
$body += Para "Expected keywords: overfitting, training, testing, bias  (4 total)"
$body += Para "Student used: overfitting, training, testing  (3 matched)"
$body += Para "Keyword Score = (3 / 4) x 100 = 75%"
$body += EmptyPara

$body += Para "Layer 2 - AI Contextual Evaluation  (80% Weight)" "Heading2"
$body += Para "The student's answer is sent to Claude AI (Anthropic) which evaluates whether the student understood the concept correctly. The AI focuses on meaning, not on exact words."
$body += EmptyPara
$body += Para "The AI checks:" "Normal" $true
$body += Para "  - Concept understanding (70%) - Did the student grasp the main idea?"
$body += Para "  - Semantic meaning (20%) - Is the meaning correct even with different words?"
$body += Para "  - Keyword usage in context (10%) - Are terms used meaningfully?"
$body += EmptyPara
$body += Para "Important Rules:" "Normal" $true
$body += Para "  - Grammar and spelling mistakes are NOT penalized"
$body += Para "  - Different wording with same meaning = Good score"
$body += Para "  - Short but accurate answers are fully rewarded"
$body += Para "  - Only conceptual correctness is judged"
$body += EmptyPara
$body += Para "AI Score Guide:" "Normal" $true
$body += Para "  90 to 100 :  Perfect understanding, concept fully correct"
$body += Para "  70 to 89  :  Good understanding, minor gaps"
$body += Para "  50 to 69  :  Partial understanding, some concept missing"
$body += Para "  0 to 49   :  Wrong concept or completely off topic"
$body += EmptyPara

$body += Para "Final Score Calculation" "Heading2"
$body += Para "Formula:" "Normal" $true
$body += Para "Final Score = (Keyword Score x 20%) + (AI Score x 80%)"
$body += EmptyPara
$body += Para "Example with real data:" "Normal" $true
$body += Para "Layer 1 Keyword Score  :  30%  x  20%  =  6.0"
$body += Para "Layer 2 AI Score       :  72%  x  80%  =  57.6"
$body += Para "Final Score            :  6.0 + 57.6   =  63.6%"
$body += EmptyPara

$body += Para "Proportional Marks" "Heading2"
$body += Para "Instead of binary grading (1 or 0), short answer questions give proportional marks. A student who scores 63.6% on a 1-mark question receives 0.636 marks. This ensures partial understanding is rewarded fairly."
$body += EmptyPara
$body += Para "Formula:" "Normal" $true
$body += Para "Marks Earned = Final Score (%) / 100"
$body += EmptyPara

$body += Para "Why This Approach?" "Heading2"
$body += Para "Traditional keyword-only checking fails when students write correct answers using different vocabulary. For example, a student writing 'the model memorizes training data and fails to generalize' should receive credit for understanding overfitting - even if that exact word was not used. The AI layer evaluates the meaning behind the answer, making grading more accurate and fair."

$bodyXml = $body -join "`n"

# word/document.xml
$docXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$bodyXml
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$docXml | Set-Content "$tempDir\word\document.xml" -Encoding UTF8

# Remove old docx if exists
if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

# Zip it up as .docx
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $outputPath)

# Cleanup temp
Remove-Item $tempDir -Recurse -Force

Write-Host "Document created: $outputPath"
