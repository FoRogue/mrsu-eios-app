import '../api/api_service.dart';
import '../models/chat_message.dart';

class CommunicationRepository {
  final ApiService _apiService = ApiService();

  Future<List<ChatMessage>> getMessages(int subjectId) async {
    final rawData = await _apiService.getCommunicationMessages(subjectId);
    // Мапим сырые словари в наши надежные объекты
    return rawData.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<bool> sendMessage(int subjectId, String text) async {
    return await _apiService.sendCommunicationMessage(subjectId, text);
  }
}