import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../core/constants.dart';
import '../models/test_models.dart';
import '../widgets/test/question_view.dart';

class TestPassingScreen extends StatefulWidget {
  final int profileId;

  const TestPassingScreen({super.key, required this.profileId});

  @override
  State<TestPassingScreen> createState() => _TestPassingScreenState();
}

class _TestPassingScreenState extends State<TestPassingScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _session;
  Map<String, dynamic>? _currentQuestion;

  bool _isLoading = true;
  bool _isSaving = false;

  List<int> _sessionQuestionsIds = [];
  int _currentQuestionIndex = 0;
  final Map<int, Map<String, dynamic>> _questionsCache = {};

  int? _selectedSingleAnswer;
  List<int> _selectedMultipleAnswers = [];
  final TextEditingController _textAnswerController = TextEditingController();

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[TEST_PASS] initState: Запуск теста с profileId: ${widget.profileId}',
    );
    _initTest();
  }

  @override
  void dispose() {
    debugPrint('[TEST_PASS] dispose: Очистка ресурсов (Таймер, Контроллеры)');
    _timer?.cancel();
    _textAnswerController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    if (_timer != null && _timer!.isActive) return;
    _secondsLeft = seconds;
    debugPrint('[TIMER] Таймер запущен: $_secondsLeft секунд');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        if (_secondsLeft % 60 == 0) {
          debugPrint('[TIMER] Осталось времени: ${_secondsLeft ~/ 60} мин.');
        }
      } else {
        debugPrint('[TIMER] Время вышло! Остановка таймера.');
        timer.cancel();
      }
    });
  }

  Future<void> _initTest() async {
    debugPrint('[TEST_PASS] _initTest: Запрос на старт сессии...');
    final session = await _apiService.startTestSession(widget.profileId);

    if (!mounted) return;

    if (session != null) {
      final sessionId = session['Id'] ?? session['id'];
      debugPrint('[TEST_PASS] _initTest: Сессия получена. ID: $sessionId');
      setState(() => _session = session);

      final sessionQIds =
          session['SessionQuestionsId'] ?? session['sessionQuestionsId'];
      if (sessionQIds != null) {
        _sessionQuestionsIds = List<int>.from(sessionQIds);
      }

      if (_sessionQuestionsIds.isNotEmpty) {
        await _loadQuestion(_sessionQuestionsIds[0]);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuestion(int questionId) async {
    debugPrint('[TEST_PASS] _loadQuestion: Запрос вопроса ID: $questionId');

    if (!_questionsCache.containsKey(questionId)) {
      final question = await _apiService.getTestQuestion(questionId);
      if (!mounted) return;

      if (question != null) {
        _questionsCache[questionId] = question;
        final secLeft = question['SecondsLeft'] ?? question['secondsLeft'];
        if (secLeft != null) {
          _startTimer(secLeft);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _currentQuestion = _questionsCache[questionId];
      _restoreAnswersFromCache();
      _isLoading = false;
      _isSaving = false;
    });
  }

  void _restoreAnswersFromCache() {
    _selectedSingleAnswer = null;
    _selectedMultipleAnswers.clear();
    _textAnswerController.clear();

    if (_currentQuestion == null) return;

    int qType =
        _currentQuestion!['QuestionType'] ??
        _currentQuestion!['questionType'] ??
        0;
    List<dynamic> answers =
        _currentQuestion!['SessionQuestionAnswers'] ??
        _currentQuestion!['sessionQuestionAnswers'] ??
        [];

    for (var ans in answers) {
      final isSelected = ans['Selected'] ?? ans['selected'] ?? false;
      final ansId = ans['Id'] ?? ans['id'] ?? 0;

      if (isSelected == true) {
        if (qType == 0) {
          _selectedSingleAnswer = ansId;
        } else {
          _selectedMultipleAnswers.add(ansId);
        }
      }
    }

    final shortAnswer =
        _currentQuestion!['ShortAnswer'] ?? _currentQuestion!['shortAnswer'];
    if (shortAnswer != null) {
      _textAnswerController.text = shortAnswer.toString();
    }
  }

  Future<bool> _saveCurrentAnswer() async {
    if (_currentQuestion == null) return true;

    int currentQId = _currentQuestion!['Id'] ?? _currentQuestion!['id'] ?? _sessionQuestionsIds[_currentQuestionIndex];
    debugPrint('[TEST_PASS] _saveCurrentAnswer: Начало сохранения ответа для вопроса ID: $currentQId');

    try {
      int qType = _currentQuestion!['QuestionType'] ?? _currentQuestion!['questionType'] ?? 0;
      List<dynamic> originalAnswers = _currentQuestion!['SessionQuestionAnswers'] ?? _currentQuestion!['sessionQuestionAnswers'] ?? [];

      List<PassSessionQuestionAnswer>? answersDto;

      if (originalAnswers.isNotEmpty) {
        answersDto = [];
        for (var ans in originalAnswers) {
          int ansId = ans['Id'] ?? ans['id'] ?? 0;
          dynamic rawOrder = ans['Order'] ?? ans['order'];
          int? ansOrder = rawOrder is int ? rawOrder : null;

          bool isSelected = false;
          if (qType == 0) {
            isSelected = (ansId == _selectedSingleAnswer);
          } else if (qType == 1) {
            isSelected = _selectedMultipleAnswers.contains(ansId);
          } else {
            isSelected = ans['Selected'] ?? ans['selected'] ?? false;
          }

          answersDto.add(PassSessionQuestionAnswer(
            id: ansId,
            selected: isSelected,
            order: ansOrder,
          ));
        }
      }

      String? finalShortAnswer;
      if (qType == 4) {
        String text = _textAnswerController.text.trim();
        finalShortAnswer = text.isEmpty ? "" : text; // По твоему опыту, сервер лучше переваривает пустую строку для текста
      }

      int? finalStars;
      if (qType == 10) {
        dynamic rawStars = _currentQuestion!['SelectedStars'] ?? _currentQuestion!['selectedStars'];
        finalStars = rawStars is int ? rawStars : null;
      }

      final dto = PassSessionQuestion(
        id: currentQId,
        shortAnswer: finalShortAnswer,
        selectedStars: finalStars,
        sessionQuestionAnswers: answersDto,
      );

      debugPrint('\n=== [ЛОГ] ОТПРАВЛЯЕМ DTO ПО ДОКУМЕНТАЦИИ ===');
      debugPrint(jsonEncode(dto.toJson()));

      // Возвращаем старый вызов, который ждет объект PassSessionQuestion
      final response = await _apiService.saveTestAnswer(dto);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return false;

      // ОБРАБОТКА ТАЙМАУТОВ И ОШИБОК...
      if (response == false) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка сервера МГУ (500).'), backgroundColor: Colors.red));
        return false;
      }

      if (response is Map && (response.containsKey('Message') || response.containsKey('message'))) {
        final msg = response['Message'] ?? response['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red));
        if (msg.toString().contains("Время")) {
          await _finishTest();
        }
        return false;
      }

      // Обновление локального кэша
      _currentQuestion!['SessionQuestionAnswers'] = originalAnswers.map((ans) {
        var updated = Map<String, dynamic>.from(ans);
        int ansId = ans['Id'] ?? ans['id'] ?? 0;

        bool isSelected = false;
        if (qType == 0) {
          isSelected = (ansId == _selectedSingleAnswer);
        } else if (qType == 1) {
          isSelected = _selectedMultipleAnswers.contains(ansId);
        } else {
          isSelected = ans['Selected'] ?? ans['selected'] ?? false;
        }

        updated['Selected'] = isSelected;
        updated['selected'] = isSelected;
        return updated;
      }).toList();

      if (qType == 4) _currentQuestion!['ShortAnswer'] = finalShortAnswer;
      if (qType == 10) _currentQuestion!['SelectedStars'] = finalStars;

      _questionsCache[currentQId] = _currentQuestion!;

      return true;

    } catch (e, stacktrace) {
      debugPrint('!!! [ЛОГ КРАШ] ОШИБКА DART ПРИ СОХРАНЕНИИ: $e');
      return false;
    }
  }

  Future<void> _goToQuestion(int index) async {
    if (_isSaving || index == _currentQuestionIndex) return;
    setState(() => _isSaving = true);
    if (await _saveCurrentAnswer()) {
      setState(() {
        _currentQuestionIndex = index;
        _currentQuestion = null;
      });
      await _loadQuestion(_sessionQuestionsIds[index]);
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _submitAndNext() async {
    if (_isSaving) return;
    if (_currentQuestionIndex == _sessionQuestionsIds.length - 1) {
      setState(() => _isSaving = true);
      if (await _saveCurrentAnswer()) {
        await _finishTest();
      } else {
        setState(() => _isSaving = false);
      }
    } else {
      await _goToQuestion(_currentQuestionIndex + 1);
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();
    final sessionId = _session!['Id'] ?? _session!['id'];
    final result = await _apiService.finishTestSession(sessionId);

    if (!mounted) return;

    final score = result?['Score'] ?? result?['score'] ?? 'На проверке';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Тест завершен 🎉'),
        content: Text('Результат: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Отлично',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  bool _isQuestionAnswered(int index) {
    if (index == _currentQuestionIndex) {
      return _selectedSingleAnswer != null ||
          _selectedMultipleAnswers.isNotEmpty ||
          _textAnswerController.text.trim().isNotEmpty;
    }
    int qId = _sessionQuestionsIds[index];
    if (!_questionsCache.containsKey(qId)) return false;

    final q = _questionsCache[qId]!;
    final shortAnswer = q['ShortAnswer'] ?? q['shortAnswer'];
    if (shortAnswer?.toString().trim().isNotEmpty ?? false) return true;

    final answers =
        q['SessionQuestionAnswers'] ?? q['sessionQuestionAnswers'] ?? [];
    return answers.any(
      (ans) => (ans['Selected'] == true || ans['selected'] == true),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тестирование'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String timeStr =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldLeave =
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Покинуть тест?'),
                content: const Text(
                  'Вы можете вернуться позже, но таймер не остановится. Выйти?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Остаться',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Выйти',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldLeave) {
          if (!mounted) return;
          if (_isSaving) return;
          setState(() => _isSaving = true);
          await _saveCurrentAnswer();
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Вопрос ${_currentQuestionIndex + 1} из ${_sessionQuestionsIds.length}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_secondsLeft > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '⏱ $timeStr',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 70,
                  color: Colors.white,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sessionQuestionsIds.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      bool isCurrent = index == _currentQuestionIndex;
                      bool isAnswered = _isQuestionAnswered(index);
                      return GestureDetector(
                        onTap: () => _goToQuestion(index),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.primary
                                : (isAnswered
                                      ? AppColors.primary.withOpacity(0.15)
                                      : Colors.transparent),
                            border: Border.all(
                              color: isCurrent || isAnswered
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : (isAnswered
                                        ? AppColors.primary
                                        : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _currentQuestion == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Expanded(
                              child: QuestionView(
                                question: _currentQuestion!,
                                selectedSingleAnswer: _selectedSingleAnswer,
                                selectedMultipleAnswers:
                                    _selectedMultipleAnswers,
                                textAnswerController: _textAnswerController,
                                onSingleAnswerChanged: (val) =>
                                    setState(() => _selectedSingleAnswer = val),
                                onMultipleAnswerChanged: (id, val) =>
                                    setState(() {
                                      if (val)
                                        _selectedMultipleAnswers.add(id);
                                      else
                                        _selectedMultipleAnswers.remove(id);
                                    }),
                                onTextChanged: () => setState(() {}),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _submitAndNext,
                                  child: Text(
                                    _currentQuestionIndex ==
                                            _sessionQuestionsIds.length - 1
                                        ? 'Завершить тест'
                                        : 'Ответить и продолжить',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            if (_isSaving)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
