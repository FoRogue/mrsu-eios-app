class SubjectDetail {
  final String title;
  final List<SubjectSection> sections;

  SubjectDetail({required this.title, required this.sections});

  factory SubjectDetail.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'] as List? ?? [];
    return SubjectDetail(
      title: json['title'] ?? 'Без названия',
      sections: sectionsList.map((s) => SubjectSection.fromJson(s)).toList(),
    );
  }
}

class SubjectSection {
  final String title;
  final List<ControlDot> controlDots;

  SubjectSection({required this.title, required this.controlDots});

  factory SubjectSection.fromJson(Map<String, dynamic> json) {
    final dotsList = json['ControlDots'] as List? ?? [];
    return SubjectSection(
      title: (json['Title'] ?? 'Без названия').toString().trim(),
      controlDots: dotsList.map((d) => ControlDot.fromJson(d)).toList(),
    );
  }
}

class ControlDot {
  final String originalTitle;
  final String dateStr;
  final String maxBall;
  final String currentBall;
  final bool isReport;
  final int? testProfileId;
  final String? testTitle;

  ControlDot({
    required this.originalTitle,
    required this.dateStr,
    required this.maxBall,
    required this.currentBall,
    required this.isReport,
    this.testProfileId,
    this.testTitle,
  });

  factory ControlDot.fromJson(Map<String, dynamic> json) {
    final testProfiles = json['TestProfiles'] as List? ?? [];
    final isTest = testProfiles.isNotEmpty;

    return ControlDot(
      originalTitle: json['Title']?.toString().trim() ?? '',
      dateStr: json['Date']?.toString() ?? '',
      maxBall:
          json['MaxBall']?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '?',
      currentBall:
          json['Mark']?['Ball']?.toString().replaceAll(RegExp(r'\.0$'), '') ??
          '-',
      isReport: json['IsReport'] == true,
      testProfileId: isTest ? testProfiles[0]['Id'] : null,
      testTitle: isTest ? testProfiles[0]['TestTitle'] : null,
    );
  }

  // Умные геттеры для UI
  bool get isTest => testProfileId != null;

  String get scoreDisplay => '$currentBall / $maxBall';

  String get displayTitle {
    String title = originalTitle;
    if (title.isEmpty) {
      title = isTest ? (testTitle ?? 'Тест') : 'Контрольное мероприятие';
    }
    return title.trim();
  }

  String get formattedShortDate {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String get titleWithDate {
    final date = formattedShortDate;
    return date.isNotEmpty ? '$date  $displayTitle' : displayTitle;
  }
}
