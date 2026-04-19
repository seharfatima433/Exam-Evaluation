import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
      notifyListeners();
      return true;
    } else {
      errorMessage = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    currentUser = null;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
