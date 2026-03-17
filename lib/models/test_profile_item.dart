class TestProfileItem {
  final int profileId;
  final String title;
  final String discipline;
  final int duration;
  final int questionsCount;
  final int attemptsCount;
  final int attemptsUsed;
  final double result;
  final bool canStart;

  TestProfileItem({
    required this.profileId,
    required this.title,
    required this.discipline,
    required this.duration,
    required this.questionsCount,
    required this.attemptsCount,
    required this.attemptsUsed,
    required this.result,
    required this.canStart,
  });

  factory TestProfileItem.fromJson(Map<String, dynamic> json) {
    final testProfile = json['TestProfile'] ?? {};
    final controlDot = json['ControlDot'] ?? {};

    return TestProfileItem(
      profileId: testProfile['Id'] ?? 0,
      title: testProfile['TestTitle'] ?? 'Тест без названия',
      discipline:
          controlDot['RatingPlanDisciplineTitle'] ?? 'Дисциплина не указана',
      duration: json['DurationInMinutes'] ?? 0,
      questionsCount: json['QuestionsCount'] ?? 0,
      attemptsCount: json['AttemptsCount'] ?? 0,
      attemptsUsed: json['AttemptsUsedCount'] ?? 0,
      result: (json['Result'] ?? 0.0).toDouble(),
      canStart: json['CanStartSession'] ?? false,
    );
  }

  int get attemptsLeft => attemptsCount > 0
      ? attemptsCount - attemptsUsed
      : 999; // 999 если безлимит
}

class TestResultItem {
  final int sessionId;
  final double score;
  final DateTime? finishDate;

  TestResultItem({
    required this.sessionId,
    required this.score,
    this.finishDate,
  });

  factory TestResultItem.fromJson(Map<String, dynamic> json) {
    return TestResultItem(
      sessionId: json['SessionId'] ?? 0,
      score: (json['Result'] ?? 0.0).toDouble(),
      finishDate: json['SessionFinishDateTime'] != null
          ? DateTime.tryParse(json['SessionFinishDateTime'])
          : null,
    );
  }

  String get formattedDate {
    if (finishDate == null) return 'Дата неизвестна';
    return '${finishDate!.day.toString().padLeft(2, '0')}.${finishDate!.month.toString().padLeft(2, '0')}.${finishDate!.year} '
        '${finishDate!.hour.toString().padLeft(2, '0')}:${finishDate!.minute.toString().padLeft(2, '0')}';
  }
}
