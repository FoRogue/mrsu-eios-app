import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../controllers/test_session_controller.dart';
import '../widgets/test/question_view.dart';

class TestPassingScreen extends StatefulWidget {
  final int profileId;
  const TestPassingScreen({super.key, required this.profileId});

  @override
  State<TestPassingScreen> createState() => _TestPassingScreenState();
}

class _TestPassingScreenState extends State<TestPassingScreen> {
  late final TestSessionController _controller;
  final TextEditingController _textAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TestSessionController(profileId: widget.profileId);
    _controller.initTest();

    // Синхронизируем текстовое поле с контроллером
    _textAnswerController.addListener(() {
      _controller.textAnswer = _textAnswerController.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleFinishTest() async {
    final result = await _controller.finishTest();
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
              Navigator.pop(context); // Закрываем модалку
              Navigator.pop(context); // Выходим из экрана теста
            },
            child: const Text('Отлично', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Тестирование'), backgroundColor: AppColors.primary),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        String timeStr = '${_controller.secondsLeft ~/ 60}:${(_controller.secondsLeft % 60).toString().padLeft(2, '0')}';

        // Обновляем текст в контроллере при загрузке нового вопроса
        if (_textAnswerController.text != _controller.textAnswer) {
          _textAnswerController.text = _controller.textAnswer;
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final bool shouldLeave = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Покинуть тест?'),
                content: const Text('Вы можете вернуться позже, но таймер не остановится. Выйти?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Остаться', style: TextStyle(color: Colors.grey))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Выйти', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ) ?? false;

            if (shouldLeave) {
              if (!mounted) return;
              _controller.isSaving = true; // Блокируем UI
              await _controller.saveCurrentAnswer();
              if (mounted) Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Вопрос ${_controller.currentQuestionIndex + 1} из ${_controller.sessionQuestionsIds.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (_controller.secondsLeft > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: Text('⏱ $timeStr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    // ЛЕНТА ВОПРОСОВ
                    Container(
                      height: 70,
                      color: Colors.white,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _controller.sessionQuestionsIds.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          bool isCurrent = index == _controller.currentQuestionIndex;
                          bool isAnswered = _controller.isQuestionAnswered(index);
                          return GestureDetector(
                            onTap: () => _controller.goToQuestion(index),
                            child: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent ? AppColors.primary : (isAnswered ? AppColors.primary.withOpacity(0.15) : Colors.transparent),
                                border: Border.all(
                                  color: isCurrent || isAnswered ? AppColors.primary : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : (isAnswered ? AppColors.primary : Colors.black87),
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
                    // САМ ВОПРОС
                    Expanded(
                      child: _controller.currentQuestion == null
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                        children: [
                          Expanded(
                            child: QuestionView(
                              question: _controller.currentQuestion!,
                              selectedSingleAnswer: _controller.selectedSingleAnswer,
                              selectedMultipleAnswers: _controller.selectedMultipleAnswers,
                              textAnswerController: _textAnswerController,
                              onSingleAnswerChanged: (val) {
                                _controller.selectedSingleAnswer = val;
                                _controller.notifyListeners();
                              },
                              onMultipleAnswerChanged: (id, val) {
                                if (val) _controller.selectedMultipleAnswers.add(id);
                                else _controller.selectedMultipleAnswers.remove(id);
                                _controller.notifyListeners();
                              },
                              onTextChanged: () => _controller.notifyListeners(),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  bool isFinished = await _controller.submitAndNext();
                                  if (isFinished) await _handleFinishTest();
                                },
                                child: Text(
                                  _controller.currentQuestionIndex == _controller.sessionQuestionsIds.length - 1
                                      ? 'Завершить тест'
                                      : 'Ответить и продолжить',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_controller.isSaving)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}