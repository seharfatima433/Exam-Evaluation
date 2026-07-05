import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../models/user_model.dart';

// ── SSL bypass for dev ─────────────────────
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (_, __, ___) => true;
}

// ─────────────────────────────────────────────────────────────
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    HttpOverrides.global = MyHttpOverrides();
  }

  // ── LOGIN ─────────────────────────────────
  Future<Map<String, dynamic>> login(String input, String password) async {
    final body = <String, String>{'password': password};
    if (input.contains('@')) {
      body['email'] = input;
    } else {
      body['rollno'] = input;
    }

    try {
      final response = await http
          .post(Uri.parse(ApiConstants.login), body: body)
          .timeout(ApiConstants.timeout);

      // Guard: server might return an HTML error page instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server returned an unexpected response. Please try again later. (status: ${response.statusCode})',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data);
        return {'success': true, 'user': user, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed (${response.statusCode})',
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'No internet connection.'};
    } on HttpException {
      return {'success': false, 'message': 'Server not reachable.'};
    } on FormatException {
      return {'success': false, 'message': 'Failed to read server response. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
