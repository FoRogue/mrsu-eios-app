class ChatMessage {
  final String text;
  final String authorFio;
  final bool isTeacher;
  final DateTime? createDate;

  ChatMessage({
    required this.text,
    required this.authorFio,
    required this.isTeacher,
    this.createDate,
  });

  // Фабрика для безопасного парсинга того, что прислал ApiService
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['Text']?.toString() ?? '',
      authorFio: json['User'] != null ? json['User']['FIO']?.toString() ?? 'Неизвестный' : 'Неизвестный',
      isTeacher: json['IsTeacher'] ?? false,
      createDate: json['CreateDate'] != null ? DateTime.tryParse(json['CreateDate'].toString()) : null,
    );
  }

  String get formattedDate {
    if (createDate == null) return '';
    return '${createDate!.day.toString().padLeft(2, '0')}.${createDate!.month.toString().padLeft(2, '0')}.${createDate!.year} '
        '${createDate!.hour.toString().padLeft(2, '0')}:${createDate!.minute.toString().padLeft(2, '0')}';
  }
}