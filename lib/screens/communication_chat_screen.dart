import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../controllers/chat_controller.dart';

class CommunicationChatScreen extends StatefulWidget {
  final int subjectId;
  final String subjectTitle;

  const CommunicationChatScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
  });

  @override
  State<CommunicationChatScreen> createState() =>
      _CommunicationChatScreenState();
}

class _CommunicationChatScreenState extends State<CommunicationChatScreen> {
  final ChatController _controller = ChatController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Запускаем логику в контроллере
    _controller.loadMessages(widget.subjectId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final success = await _controller.sendMessage(
      widget.subjectId,
      _messageController.text,
    );
    if (success) {
      _messageController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось отправить сообщение'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subjectTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // ListenableBuilder автоматически перерисовывает экран, когда в контроллере вызывается notifyListeners()
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Здесь пока нет сообщений. Напишите первым!',
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _controller.messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
              ),
              _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(msg) {
    return Card(
      color: msg.isTeacher ? Colors.purple.shade50 : Colors.white,
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
                    msg.authorFio,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: msg.isTeacher ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ),
                if (msg.isTeacher)
                  const Icon(Icons.school, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(msg.text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                msg.formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
            _controller.isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _handleSend,
                  ),
          ],
        ),
      ),
    );
  }
}
