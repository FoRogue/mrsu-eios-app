import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/test_models.dart';

class TestSessionController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final int profileId;

  TestSessionController({required this.profileId});

  Map<String, dynamic>? session;
  Map<String, dynamic>? currentQuestion;

  bool isLoading = true;
  bool isSaving = false;

  List<int> sessionQuestionsIds = [];
  int currentQuestionIndex = 0;
  final Map<int, Map<String, dynamic>> _questionsCache = {};

  // Состояние ответов на текущий вопрос
  int? selectedSingleAnswer;
  List<int> selectedMultipleAnswers = [];
  String textAnswer = '';

  Timer? _timer;
  int secondsLeft = 0;

  Future<void> initTest() async {
    isLoading = true;
    notifyListeners();

    final response = await _apiService.startTestSession(profileId);
    if (response != null) {
      session = response;
      final sessionQIds = session!['SessionQuestionsId'] ?? session!['sessionQuestionsId'];
      if (sessionQIds != null) {
        sessionQuestionsIds = List<int>.from(sessionQIds);
      }
      if (sessionQuestionsIds.isNotEmpty) {
        await loadQuestion(sessionQuestionsIds[0]);
      } else {
        isLoading = false;
        notifyListeners();
      }
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer(int seconds) {
    if (_timer != null && _timer!.isActive) return;
    secondsLeft = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        secondsLeft--;
        notifyListeners(); // Обновляем UI каждую секунду
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> loadQuestion(int questionId) async {
    if (!_questionsCache.containsKey(questionId)) {
      final question = await _apiService.getTestQuestion(questionId);
      if (question != null) {
        _questionsCache[questionId] = question;
        final secLeft = question['SecondsLeft'] ?? question['secondsLeft'];
        if (secLeft != null) _startTimer(secLeft);
      }
    }

    currentQuestion = _questionsCache[questionId];
    _restoreAnswersFromCache();

    isLoading = false;
    isSaving = false;
    notifyListeners();
  }

  void _restoreAnswersFromCache() {
    selectedSingleAnswer = null;
    selectedMultipleAnswers.clear();
    textAnswer = '';

    if (currentQuestion == null) return;

    int qType = currentQuestion!['QuestionType'] ?? currentQuestion!['questionType'] ?? 0;
    List<dynamic> answers = currentQuestion!['SessionQuestionAnswers'] ?? currentQuestion!['sessionQuestionAnswers'] ?? [];

    for (var ans in answers) {
      final isSelected = ans['Selected'] ?? ans['selected'] ?? false;
      final ansId = ans['Id'] ?? ans['id'] ?? 0;

      if (isSelected == true) {
        if (qType == 0) selectedSingleAnswer = ansId;
        else selectedMultipleAnswers.add(ansId);
      }
    }

    final shortAnswer = currentQuestion!['ShortAnswer'] ?? currentQuestion!['shortAnswer'];
    if (shortAnswer != null) {
      textAnswer = shortAnswer.toString();
    }
  }

  Future<bool> saveCurrentAnswer() async {
    if (currentQuestion == null) return true;

    int currentQId = currentQuestion!['Id'] ?? currentQuestion!['id'] ?? sessionQuestionsIds[currentQuestionIndex];
    int qType = currentQuestion!['QuestionType'] ?? currentQuestion!['questionType'] ?? 0;
    List<dynamic> originalAnswers = currentQuestion!['SessionQuestionAnswers'] ?? currentQuestion!['sessionQuestionAnswers'] ?? [];

    List<PassSessionQuestionAnswer>? answersDto;

    if (originalAnswers.isNotEmpty) {
      answersDto = [];
      for (var ans in originalAnswers) {
        int ansId = ans['Id'] ?? ans['id'] ?? 0;
        dynamic rawOrder = ans['Order'] ?? ans['order'];
        int? ansOrder = rawOrder is int ? rawOrder : null;

        bool isSelected = false;
        if (qType == 0) isSelected = (ansId == selectedSingleAnswer);
        else if (qType == 1) isSelected = selectedMultipleAnswers.contains(ansId);
        else isSelected = ans['Selected'] ?? ans['selected'] ?? false;

        answersDto.add(PassSessionQuestionAnswer(id: ansId, selected: isSelected, order: ansOrder));
      }
    }

    final dto = PassSessionQuestion(
      id: currentQId,
      shortAnswer: qType == 4 ? (textAnswer.trim().isEmpty ? "" : textAnswer.trim()) : null,
      selectedStars: qType == 10 ? (currentQuestion!['SelectedStars'] ?? currentQuestion!['selectedStars'] as int?) : null,
      sessionQuestionAnswers: answersDto,
    );

    final response = await _apiService.saveTestAnswer(dto);

    if (response == false) return false;
    if (response is Map && (response.containsKey('Message') || response.containsKey('message'))) return false;

    // Обновляем локальный кэш, чтобы при возврате назад не делать запрос
    currentQuestion!['SessionQuestionAnswers'] = originalAnswers.map((ans) {
      var updated = Map<String, dynamic>.from(ans);
      int ansId = ans['Id'] ?? ans['id'] ?? 0;
      bool isSelected = false;
      if (qType == 0) isSelected = (ansId == selectedSingleAnswer);
      else if (qType == 1) isSelected = selectedMultipleAnswers.contains(ansId);
      updated['Selected'] = isSelected;
      updated['selected'] = isSelected;
      return updated;
    }).toList();

    if (qType == 4) currentQuestion!['ShortAnswer'] = textAnswer;
    _questionsCache[currentQId] = currentQuestion!;

    return true;
  }

  Future<void> goToQuestion(int index) async {
    if (isSaving || index == currentQuestionIndex) return;

    isSaving = true;
    notifyListeners();

    if (await saveCurrentAnswer()) {
      currentQuestionIndex = index;
      currentQuestion = null;
      await loadQuestion(sessionQuestionsIds[index]);
    } else {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> submitAndNext() async {
    if (isSaving) return false;

    if (currentQuestionIndex == sessionQuestionsIds.length - 1) {
      isSaving = true;
      notifyListeners();
      return await saveCurrentAnswer(); // Возвращаем true, если это последний вопрос и он сохранен
    } else {
      await goToQuestion(currentQuestionIndex + 1);
      return false;
    }
  }

  Future<dynamic> finishTest() async {
    _timer?.cancel();
    final sessionId = session!['Id'] ?? session!['id'];
    return await _apiService.finishTestSession(sessionId);
  }

  bool isQuestionAnswered(int index) {
    if (index == currentQuestionIndex) {
      return selectedSingleAnswer != null || selectedMultipleAnswers.isNotEmpty || textAnswer.trim().isNotEmpty;
    }
    int qId = sessionQuestionsIds[index];
    if (!_questionsCache.containsKey(qId)) return false;

    final q = _questionsCache[qId]!;
    final shortAns = q['ShortAnswer'] ?? q['shortAnswer'];
    if (shortAns?.toString().trim().isNotEmpty ?? false) return true;

    final answers = q['SessionQuestionAnswers'] ?? q['sessionQuestionAnswers'] ?? [];
    return answers.any((ans) => (ans['Selected'] == true || ans['selected'] == true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}