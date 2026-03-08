import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthService {
  // Метод возвращает true, если вход успешен, и false, если ошибка
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': ApiConstants.clientId,
          'client_secret': ApiConstants.clientSecret,
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];

        // Сохраняем токен
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        return true;
      }
      return false; // Неверный логин/пароль
    } catch (e) {
      print('Ошибка сети AuthService: $e');
      return false;
    }
  }

  // Метод для выхода из аккаунта
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}