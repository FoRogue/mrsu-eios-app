import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../repositories/communication_repository.dart';

class ChatController extends ChangeNotifier {
  final CommunicationRepository _repository = CommunicationRepository();

  List<ChatMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;

  Future<void> loadMessages(int subjectId) async {
    isLoading = true;
    notifyListeners(); // Говорим UI показать лоадер

    try {
      messages = await _repository.getMessages(subjectId);
    } catch (e) {
      debugPrint('Ошибка загрузки сообщений: $e');
    } finally {
      isLoading = false;
      notifyListeners(); // Говорим UI перерисоваться с данными
    }
  }

  Future<bool> sendMessage(int subjectId, String text) async {
    if (text.trim().isEmpty) return false;

    isSending = true;
    notifyListeners();

    final success = await _repository.sendMessage(subjectId, text.trim());
    if (success) {
      await loadMessages(subjectId); // Перезагружаем список
    }

    isSending = false;
    notifyListeners();

    return success;
  }
}