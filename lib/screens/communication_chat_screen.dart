import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../core/constants.dart';

class CommunicationChatScreen extends StatefulWidget {
  final int subjectId;
  final String subjectTitle;

  const CommunicationChatScreen({super.key, required this.subjectId, required this.subjectTitle});

  @override
  State<CommunicationChatScreen> createState() => _CommunicationChatScreenState();
}

class _CommunicationChatScreenState extends State<CommunicationChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _apiService.getCommunicationMessages(widget.subjectId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final success = await _apiService.sendCommunicationMessage(widget.subjectId, text);

    if (success) {
      _messageController.clear();
      await _loadMessages(); // Сразу подгружаем новые сообщения
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить сообщение'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isSending = false);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('Здесь пока нет сообщений. Напишите первым!'))
                : ListView.builder(
              reverse: true, // Сообщения идут снизу вверх
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final user = msg['User'] != null ? msg['User']['FIO'] : 'Неизвестный';
                final isTeacher = msg['IsTeacher'] ?? false;
                final date = _formatDate(msg['CreateDate'] ?? '');
                final text = msg['Text'] ?? '';

                return Card(
                  color: isTeacher ? Colors.purple.shade50 : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                user,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTeacher ? AppColors.primary : Colors.black87,
                                ),
                              ),
                            ),
                            if (isTeacher)
                              const Icon(Icons.school, size: 16, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(text, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, -1), blurRadius: 4)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Введите сообщение...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                      : IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}