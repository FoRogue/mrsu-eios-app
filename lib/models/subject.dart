class Subject {
  final int id;
  final String title;

  Subject({
    required this.id,
    required this.title,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Без названия',
    );
  }
}