// Файл: lib/core/constants_example.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C3F99);
  static const Color secondary = Color(0xFFF8BA32);
  static const Color background = Color(0xFFF5F5F5);
}

class ApiConstants {
  static const String tokenUrl = 'https://p.mrsu.ru/OAuth/Token';
  static const String baseUrl = 'https://papi.mrsu.ru/v1';

  // ВНИМАНИЕ: Для запуска приложения создайте файл constants.dart
  // и вставьте сюда реальные ключи!
  static const String clientId = 'YOUR_CLIENT_ID_HERE';
  static const String clientSecret = 'YOUR_CLIENT_SECRET_HERE';
}