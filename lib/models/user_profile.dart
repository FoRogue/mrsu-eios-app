class UserProfile {
  final String id;
  final String fio;
  final String email;
  final String photoUrl;
  final String? studentCode;
  final List<String> roles;

  UserProfile({
    required this.id,
    required this.fio,
    required this.email,
    required this.photoUrl,
    this.studentCode,
    required this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Парсим роли, если они есть
    List<String> parsedRoles = [];
    if (json['Roles'] != null && json['Roles'] is List) {
      for (var role in json['Roles']) {
        if (role['Description'] != null) {
          parsedRoles.add(role['Description'].toString());
        }
      }
    }

    return UserProfile(
      id: json['Id']?.toString() ?? '',
      fio: json['FIO'] ?? 'Студент МГУ',
      email: json['Email'] ?? 'Нет email',
      // Берем среднюю аватарку по документации
      photoUrl: json['Photo']?['UrlMedium'] ?? 'https://p.mrsu.ru/Content/img/noavatar.png',
      studentCode: json['StudentCod'],
      roles: parsedRoles,
    );
  }
}