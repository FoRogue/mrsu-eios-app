import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/globals.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';
import '../models/test_models.dart';

class ApiService {
  // Настоящая цепная очередь. По умолчанию - завершенный Future.
  static Future<void> _taskQueue = Future.value();

  // Функция, которая выстраивает запросы строго друг за другом
  Future<T> _executeLocked<T>(Future<T> Function() requestAction) async {
    // 1. Сохраняем ссылку на текущий конец очереди
    final previousTask = _taskQueue;

    // 2. Создаем новый замок для текущего запроса
    final completer = Completer<void>();

    // 3. Ставим наш замок в конец очереди, чтобы следующие запросы ждали уже нас
    _taskQueue = completer.future;

    // 4. ПОЛНАЯ БЛОКИРОВКА: Ждем, пока ВСЕ предыдущие запросы в очереди не отработают
    try {
      await previousTask;
    } catch (
      _
    ) {} // Если предыдущий запрос упал с ошибкой, нам плевать, мы все равно идем дальше

    // 5. Теперь наша очередь. Делаем запрос к API.
    try {
      return await requestAction();
    } finally {
      // 6. Запрос завершен (успешно или с ошибкой). Снимаем наш замок, чтобы следующий в очереди мог пойти.
      completer.complete();
    }
  }

  Future<dynamic> _getAuthorizedRequest(String endpoint) async {
    return _executeLocked(() async {
      debugPrint('[API GET] Инициализация запроса к: $endpoint');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint('[API GET] Токен отсутствует. Принудительный логаут.');
        _forceLogout();
        return null;
      }

      try {
        debugPrint(
          '[API GET] Отправка запроса: ${ApiConstants.baseUrl}/$endpoint',
        );
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
          headers: {'Authorization': 'Bearer $token'},
        );

        debugPrint('[API GET] Получен ответ. Статус: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint(
            '[API GET] Успех 200. Длина ответа: ${response.body.length} симв.',
          );
          return json.decode(response.body);
        } else if (response.statusCode == 423) {
          debugPrint('[API GET] Ошибка 423 (Время вышло): ${response.body}');
          return json.decode(response.body);
        } else if (response.statusCode == 401) {
          debugPrint(
            '[API GET] Ошибка 401 (Не авторизован). Принудительный логаут.',
          );
          _forceLogout();
          return null;
        } else if (response.statusCode == 404) {
          debugPrint(
            '[API GET] Ошибка 404 (Не найдено). Возвращаем пустой список.',
          );
          return [];
        } else {
          debugPrint(
            '[API GET] Необработанная ошибка API: ${response.statusCode} | Тело: ${response.body}',
          );
          return null;
        }
      } catch (e) {
        debugPrint('[API GET] Ошибка сети (Exception): $e');
        return null;
      }
    });
  }

  Future<dynamic> _postAuthorizedRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _executeLocked(() async {
      debugPrint('[API POST] Инициализация запроса к: $endpoint');
      debugPrint('[API POST] Тело запроса: ${json.encode(body)}');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint('[API POST] Токен отсутствует. Принудительный логаут.');
        _forceLogout();
        return null;
      }

      try {
        debugPrint(
          '[API POST] Отправка запроса: ${ApiConstants.baseUrl}/$endpoint',
        );
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        debugPrint('[API POST] Получен ответ. Статус: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.body.isNotEmpty) {
            debugPrint('[API POST] Успех. Разбор тела ответа.');
            return json.decode(response.body);
          }
          debugPrint('[API POST] Успех. Тело ответа пустое, возвращаем true.');
          return true;
        } else if (response.statusCode == 401) {
          debugPrint('[API POST] Ошибка 401. Принудительный логаут.');
          _forceLogout();
          return null;
        } else {
          debugPrint(
            '[API POST] Ошибка API: ${response.statusCode} | Тело: ${response.body}',
          );
          return false;
        }
      } catch (e) {
        debugPrint('[API POST] Ошибка сети (Exception): $e');
        return false;
      }
    });
  }

  Future<dynamic> _putAuthorizedRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _executeLocked(() async {
      debugPrint('[API PUT] Инициализация запроса к: $endpoint');
      debugPrint('[API PUT] Тело запроса: ${json.encode(body)}');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint('[API PUT] Токен отсутствует. Принудительный логаут.');
        _forceLogout();
        return null;
      }

      try {
        debugPrint(
          '[API PUT] Отправка запроса: ${ApiConstants.baseUrl}/$endpoint',
        );
        final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/$endpoint'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        debugPrint('[API PUT] Получен ответ. Статус: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          if (response.body.isNotEmpty) {
            debugPrint('[API PUT] Успех. Разбор тела ответа.');
            return json.decode(response.body);
          }
          debugPrint('[API PUT] Успех. Возвращаем true.');
          return true;
        } else if (response.statusCode == 423) {
          debugPrint('[API PUT] Ошибка 423 (Время вышло): ${response.body}');
          return json.decode(response.body);
        } else if (response.statusCode == 401) {
          debugPrint('[API PUT] Ошибка 401. Принудительный логаут.');
          _forceLogout();
          return null;
        } else {
          debugPrint('[API PUT] Ошибка API: ${response.statusCode}');

          // Разбиваем длинную строку ответа на куски по 800 символов, чтобы консоль её не обрезала
          final errorBody = response.body;
          final pattern = RegExp('.{1,800}');
          for (var match in pattern.allMatches(errorBody)) {
            debugPrint(match.group(0));
          }
          return false;
        }
      } catch (e) {
        debugPrint('[API PUT] Ошибка сети (Exception): $e');
        return false;
      }
    });
  }

  void _forceLogout() async {
    debugPrint('[AUTH] Вызван _forceLogout. Переход на LoginScreen.');
    await AuthService().logout();
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- УСПЕВАЕМОСТЬ И ПРЕДМЕТЫ ---
  Future<List<Map<String, dynamic>>> getSubjects({
    int? year,
    int? semester,
    bool isMessages = false,
  }) async {
    debugPrint(
      '[API SERVICE] Вызван getSubjects (year: $year, semester: $semester, isMessages: $isMessages)',
    );
    String endpoint = 'StudentSemester?selector=current';
    if (year != null && semester != null) {
      String formattedYear = '$year - ${year + 1}';
      String encodedYear = Uri.encodeComponent(formattedYear);
      endpoint = 'StudentSemester?year=$encodedYear&period=$semester';
      if (isMessages) {
        endpoint = 'StudentSemester?t=m&year=$encodedYear&period=$semester';
      }
    }
    final data = await _getAuthorizedRequest(endpoint);
    if (data == null) {
      debugPrint('[API SERVICE] getSubjects: data is null, возвращаем []');
      return [];
    }
    List<Map<String, dynamic>> subjects = [];
    try {
      if (data is Map && data.containsKey('RecordBooks')) {
        debugPrint('[API SERVICE] getSubjects: Парсинг структуры RecordBooks');
        final recordBooks = data['RecordBooks'] as List? ?? [];
        for (var book in recordBooks) {
          final disciplines = book['Disciplines'] as List? ?? [];
          for (var discipline in disciplines) {
            subjects.add({
              'id': int.tryParse(discipline['Id'].toString()) ?? 0,
              'title': discipline['Title'] ?? 'Без названия',
            });
          }
        }
      } else if (data is List) {
        debugPrint('[API SERVICE] getSubjects: Парсинг структуры List');
        if (data.isNotEmpty &&
            data[0] is Map &&
            data[0].containsKey('Year') &&
            data[0].containsKey('Period')) {
          debugPrint(
            '[API SERVICE] getSubjects: Обнаружен корневой список периодов, рекурсивный вызов getSubjects()',
          );
          return await getSubjects();
        }
        for (var item in data) {
          if (item is Map) {
            if (item.containsKey('Disciplines')) {
              final disciplines = item['Disciplines'] as List? ?? [];
              for (var discipline in disciplines) {
                subjects.add({
                  'id': int.tryParse(discipline['Id'].toString()) ?? 0,
                  'title': discipline['Title'] ?? 'Без названия',
                });
              }
            } else if (item.containsKey('Id') && item.containsKey('Title')) {
              subjects.add({
                'id': int.tryParse(item['Id'].toString()) ?? 0,
                'title': item['Title'] ?? 'Без названия',
              });
            }
          }
        }
      }
      debugPrint(
        '[API SERVICE] getSubjects: Успешно распарсено ${subjects.length} предметов',
      );
    } catch (e) {
      debugPrint('[API SERVICE] getSubjects ОШИБКА ПАРСИНГА: $e');
    }
    return subjects;
  }

  Future<Map<String, dynamic>?> getSubjectDetails(int subjectId) async {
    debugPrint(
      '[API SERVICE] Вызван getSubjectDetails для subjectId: $subjectId',
    );
    final disciplineData = await _getAuthorizedRequest('Discipline/$subjectId');
    final ratingPlanData = await _getAuthorizedRequest(
      'StudentRatingPlan/$subjectId',
    );
    if (disciplineData == null || ratingPlanData == null) {
      debugPrint(
        '[API SERVICE] getSubjectDetails: Не удалось получить данные дисциплины или рейтинга',
      );
      return null;
    }
    return {
      'title': disciplineData['Title'] ?? 'Без названия',
      'sections': ratingPlanData['Sections'] ?? [],
    };
  }

  // --- РАСПИСАНИЕ ---
  Future<List<dynamic>> getSchedule(String date) async {
    debugPrint('[API SERVICE] Вызван getSchedule для date: $date');
    final data = await _getAuthorizedRequest('StudentTimeTable?date=$date');
    if (data is List) return data;
    if (data is Map) return [data];
    return [];
  }

  // --- ОБЩЕНИЕ ---
  Future<List<Map<String, dynamic>>> getCommunicationMessages(
    int subjectId,
  ) async {
    debugPrint(
      '[API SERVICE] Вызван getCommunicationMessages для subjectId: $subjectId',
    );
    final data = await _getAuthorizedRequest(
      'ForumMessage?disciplineId=$subjectId&count=50',
    );
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<bool> sendCommunicationMessage(int subjectId, String text) async {
    debugPrint(
      '[API SERVICE] Вызван sendCommunicationMessage для subjectId: $subjectId',
    );
    final response = await _postAuthorizedRequest('ForumMessage', {
      'DisciplineId': subjectId,
      'Text': text,
    });
    return response == true;
  }

  // --- ТЕСТЫ ---
  Future<List<dynamic>> getAvailableTests({
    bool isArchive = false,
    int count = 20,
    int offset = 0,
  }) async {
    debugPrint(
      '[API SERVICE] Вызван getAvailableTests (isArchive: $isArchive, offset: $offset)',
    );
    final data = await _getAuthorizedRequest(
      'TestProfileForPass?archive=$isArchive&count=$count&offset=$offset',
    );
    if (data is Map && data.containsKey('Items')) return data['Items'];
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>?> startTestSession(int profileId) async {
    debugPrint(
      '[API SERVICE] Вызван startTestSession для profileId: $profileId',
    );
    final response = await _postAuthorizedRequest(
      'Session?profileId=$profileId',
      {},
    );
    if (response is Map<String, dynamic>) {
      debugPrint(
        '[API SERVICE] startTestSession: Сессия успешно начата. Session ID: ${response['Id']}',
      );
      return response;
    }
    debugPrint('[API SERVICE] startTestSession: Не удалось начать сессию');
    return null;
  }

  Future<Map<String, dynamic>?> getTestQuestion(int questionId) async {
    debugPrint(
      '[API SERVICE] Вызван getTestQuestion для questionId: $questionId',
    );
    final data = await _getAuthorizedRequest('SessionQuestion/$questionId');
    if (data is Map<String, dynamic>) {
      debugPrint('[API SERVICE] getTestQuestion: Вопрос успешно получен');
      return data;
    }
    debugPrint('[API SERVICE] getTestQuestion: Ошибка получения вопроса');
    return null;
  }

  Future<dynamic> saveTestAnswer(PassSessionQuestion answer) async {
    debugPrint(
      '[API SERVICE] Вызван saveTestAnswer для вопроса ID: ${answer.id}',
    );
    final response = await _putAuthorizedRequest(
      'SessionQuestion',
      answer.toJson(),
    );
    return response;
  }

  Future<Map<String, dynamic>?> finishTestSession(int sessionId) async {
    debugPrint(
      '[API SERVICE] Вызван finishTestSession для sessionId: $sessionId',
    );
    final response = await _postAuthorizedRequest(
      'TestPoolResult?sessionId=$sessionId',
      {},
    );
    if (response is Map<String, dynamic>) {
      debugPrint('[API SERVICE] finishTestSession: Сессия успешно завершена');
      return response;
    }
    debugPrint('[API SERVICE] finishTestSession: Ошибка завершения сессии');
    return null;
  }

  Future<List<dynamic>> getTestResults(int profileId) async {
    debugPrint('[API SERVICE] Вызван getTestResults для profileId: $profileId');
    final data = await _getAuthorizedRequest(
      'TestPoolResult?profileId=$profileId&count=20&offset=0',
    );
    if (data is Map && data.containsKey('Items')) return data['Items'];
    if (data is List) return data;
    return [];
  }

  Future<String?> getRawToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    debugPrint('[API SERVICE] Вызван getUserProfile');
    final data = await _getAuthorizedRequest('User');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }
}
