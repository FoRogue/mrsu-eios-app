import 'package:flutter/material.dart';

class AppColors {
  // Цвета из брендбука МГУ им. Н.П. Огарева
  static const Color primary = Color(0xFF6C3F99); // Фирменный фиолетовый
  static const Color secondary = Color(0xFFF8BA32); // Фирменный желтый
  static const Color background = Color(0xFFF5F5F5); // Светло-серый фон
}

class ApiConstants {
  static const String tokenUrl = 'https://p.mrsu.ru/OAuth/Token';
  static const String baseUrl = 'https://papi.mrsu.ru/v1';
  static const String clientId = '8';
  static const String clientSecret = 'qweasd';
}