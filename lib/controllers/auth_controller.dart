import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_sender_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;

  Future<bool> login(String input, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _service.login(input, password);

    isLoading = false;
    if (result['success'] == true) {
      currentUser = result['user'] as UserModel;
      
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(result['data']));

      notifyListeners();
      return true;
    } else {
      errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_session');
    if (userStr != null) {
      final data = jsonDecode(userStr);
      currentUser = UserModel.fromJson(data);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    currentUser = null;
    errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await FCMSenderService.clearFCMData();
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
