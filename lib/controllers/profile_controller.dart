import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../models/user_profile.dart';
import '../screens/login_screen.dart';

class ProfileController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserProfile? userProfile;
  bool isLoading = true;

  void init() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final rawData = await _apiService.getUserProfile();
      if (rawData != null) {
        userProfile = UserProfile.fromJson(rawData);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    // 1. Очищаем токен из памяти телефона
    await AuthService().logout();

    // 2. Если экран еще жив, перекидываем на логин и сбрасываем историю навигации
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) =>
            false, // Эта строчка запрещает вернуться назад кнопкой "Назад"
      );
    }
  }
}
