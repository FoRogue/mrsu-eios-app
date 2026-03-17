import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../core/constants.dart';

class QuestionView extends StatelessWidget {
  final Map<String, dynamic> question;
  final int? selectedSingleAnswer;
  final List<int> selectedMultipleAnswers;
  final TextEditingController textAnswerController;
  final Function(int?) onSingleAnswerChanged;
  final Function(int, bool) onMultipleAnswerChanged;
  final VoidCallback onTextChanged;

  const QuestionView({
    super.key,
    required this.question,
    required this.selectedSingleAnswer,
    required this.selectedMultipleAnswers,
    required this.textAnswerController,
    required this.onSingleAnswerChanged,
    required this.onMultipleAnswerChanged,
    required this.onTextChanged,
  });

  String _processHtml(String rawHtml) {
    // Безопасное логирование без вложенных кавычек в интерполяции
    String shortHtml = rawHtml.length > 50
        ? '${rawHtml.substring(0, 50)}...'
        : rawHtml;

    String html = rawHtml;
    // Универсальная замена путей для картинок с экранированием
    html = html.replaceAll('src="/', 'src="https://p.mrsu.ru/');
    html = html.replaceAll('src=\'/', 'src=\'https://p.mrsu.ru/');
    html = html.replaceAll('src="Data/', 'src="https://p.mrsu.ru/Data/');
    html = html.replaceAll('src=\'Data/', 'src=\'https://p.mrsu.ru/Data/');

    return html;
  }

  @override
  Widget build(BuildContext context) {
    // Безопасное извлечение ключей (с учетом регистра)
    final qId = question['Id'] ?? question['id'] ?? 0;

    final List<dynamic> qAnswers =
        question['SessionQuestionAnswers'] ??
        question['sessionQuestionAnswers'] ??
        [];
    final String rawHtmlText =
        question['HtmlText'] ??
        question['htmlText'] ??
        'Текст вопроса отсутствует';
    final String qTypeName =
        question['QuestionTypeName'] ?? question['questionTypeName'] ?? '';
    final int qType = question['QuestionType'] ?? question['questionType'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (qTypeName.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                qTypeName,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Html(data: _processHtml(rawHtmlText)),

          const SizedBox(height: 24),

          if (qAnswers.isEmpty)
            TextField(
              controller: textAnswerController,
              minLines: 1,
              maxLines: null,
              maxLength: 128,
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => onTextChanged(),
              decoration: InputDecoration(
                labelText: 'Введите ваш ответ',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            )
          else if (qType == 0)
            ...qAnswers.map((ans) {
              final ansId = ans['Id'] ?? ans['id'] ?? 0;
              final ansHtml = ans['HtmlText'] ?? ans['htmlText'] ?? '';
              return RadioListTile<int>(
                title: Html(data: _processHtml(ansHtml)),
                value: ansId,
                groupValue: selectedSingleAnswer,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => onSingleAnswerChanged(val),
              );
            })
          else
            ...qAnswers.map((ans) {
              final ansId = ans['Id'] ?? ans['id'] ?? 0;
              final ansHtml = ans['HtmlText'] ?? ans['htmlText'] ?? '';
              return CheckboxListTile(
                title: Html(data: _processHtml(ansHtml)),
                value: selectedMultipleAnswers.contains(ansId),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) =>
                    onMultipleAnswerChanged(ansId, val ?? false),
              );
            }),
        ],
      ),
    );
  }
}
