import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/globals.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';

class ApiService {
  Future<dynamic> _getAuthorizedRequest(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _forceLogout();
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        debugPrint('Ошибка 401: Токен протух. Выкидываем на логин.');
        _forceLogout();
        return null;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        debugPrint('Ошибка API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка сети: $e');
      return null;
    }
  }

  Future<dynamic> _postAuthorizedRequest(String endpoint, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _forceLogout();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        _forceLogout();
        return null;
      } else {
        debugPrint('Ошибка API POST: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка сети POST: $e');
      return false;
    }
  }

  void _forceLogout() async {
    await AuthService().logout();
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  // --- УСПЕВАЕМОСТЬ И ПРЕДМЕТЫ ---

  Future<List<Map<String, dynamic>>> getSubjects({int? year, int? semester, bool isMessages = false}) async {
    String endpoint = 'StudentSemester?selector=current';

    if (year != null && semester != null) {
      String formattedYear = '$year - ${year + 1}';
      String encodedYear = Uri.encodeComponent(formattedYear);

      endpoint = 'StudentSemester?year=$encodedYear&period=$semester';

      if (isMessages) {
        endpoint = 'StudentSemester?t=m&year=$encodedYear&period=$semester';
      }
    }

    debugPrint('➡️ ОТПРАВЛЯЕМ ЗАПРОС: $endpoint');
    final data = await _getAuthorizedRequest(endpoint);
    debugPrint('⬅️ ОТВЕТ СЕРВЕРА: $data');

    if (data == null) return [];

    List<Map<String, dynamic>> subjects = [];
    try {
      if (data is Map && data.containsKey('RecordBooks')) {
        final recordBooks = data['RecordBooks'] as List? ?? [];
        for (var book in recordBooks) {
          final disciplines = book['Disciplines'] as List? ?? [];
          for (var discipline in disciplines) {
            subjects.add({
              'id': int.tryParse(discipline['Id'].toString()) ?? 0,
              'title': discipline['Title'] ?? 'Без названия'
            });
          }
        }
      } else if (data is List) {
        if (data.isNotEmpty && data[0] is Map && data[0].containsKey('Year') && data[0].containsKey('Period')) {
          debugPrint('⚠️ СЕРВЕР ВЕРНУЛ СПИСОК СЕМЕСТРОВ. Запрашиваем текущий семестр.');
          return await getSubjects();
        }

        for (var item in data) {
          if (item is Map) {
            if (item.containsKey('Disciplines')) {
              final disciplines = item['Disciplines'] as List? ?? [];
              for (var discipline in disciplines) {
                subjects.add({
                  'id': int.tryParse(discipline['Id'].toString()) ?? 0,
                  'title': discipline['Title'] ?? 'Без названия'
                });
              }
            } else if (item.containsKey('Id') && item.containsKey('Title')) {
              subjects.add({
                'id': int.tryParse(item['Id'].toString()) ?? 0,
                'title': item['Title'] ?? 'Без названия'
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга предметов: $e');
    }
    return subjects;
  }

  // ВОТ ЭТОТ МЕТОД ПОТЕРЯЛСЯ (ДЕТАЛИ ПРЕДМЕТА И ОЦЕНКИ)
  Future<Map<String, dynamic>?> getSubjectDetails(int subjectId) async {
    final disciplineData = await _getAuthorizedRequest('Discipline/$subjectId');
    final ratingPlanData = await _getAuthorizedRequest('StudentRatingPlan/$subjectId');

    if (disciplineData == null || ratingPlanData == null) return null;

    return {
      'title': disciplineData['Title'] ?? 'Без названия',
      'sections': ratingPlanData['Sections'] ?? [],
    };
  }

  // --- РАСПИСАНИЕ ---
  Future<List<dynamic>> getSchedule(String date) async {
    final data = await _getAuthorizedRequest('StudentTimeTable?date=$date');
    if (data is List) return data;
    if (data is Map) return [data];
    return [];
  }

  // --- ОБЩЕНИЕ (COMMUNICATIONS) ---
  Future<List<Map<String, dynamic>>> getCommunicationMessages(int subjectId) async {
    final data = await _getAuthorizedRequest('ForumMessage?disciplineId=$subjectId&count=50');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<bool> sendCommunicationMessage(int subjectId, String text) async {
    final response = await _postAuthorizedRequest('ForumMessage', {
      'DisciplineId': subjectId,
      'Text': text,
    });
    return response == true;
  }
}