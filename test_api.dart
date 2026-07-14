import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://bgnuf22eight.com/Exam-app/exam-evaluation-app/public/api/quiz/IVWKIQ');
  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print(body);
  } catch (e) {
    print('Error: $e');
  }
}
