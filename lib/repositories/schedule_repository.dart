import '../api/api_service.dart';
import '../models/schedule_item.dart';

class ScheduleRepository {
  final ApiService _apiService = ApiService();

  final Map<int, String> _lessonTimes = {
    1: "08:00 - 09:30",
    2: "09:45 - 11:15",
    3: "11:35 - 13:05",
    4: "13:20 - 14:50",
    5: "15:00 - 16:30",
    6: "16:40 - 18:10",
    7: "18:15 - 19:45",
    8: "19:45 - 21:20",
  };

  String getLessonTime(int number) => _lessonTimes[number] ?? "Время не указано";

  Future<List<LessonItem>> getLessons(DateTime date) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final rawData = await _apiService.getSchedule(dateStr);

    List<LessonItem> lessons = [];

    if (rawData.isNotEmpty) {
      for (var dayData in rawData) {
        final timeTable = dayData['TimeTable'] ?? dayData;
        final rawLessons = timeTable['Lessons'] as List? ?? [];

        for (var lesson in rawLessons) {
          int number = int.tryParse(lesson['Number']?.toString() ?? '0') ?? 0;
          final disciplines = lesson['Disciplines'] as List? ?? [];

          for (var discipline in disciplines) {
            final teacherObj = discipline['Teacher'];
            final roomObj = discipline['Auditorium'];

            lessons.add(LessonItem(
              id: int.tryParse(discipline['Id']?.toString() ?? '0') ?? 0,
              number: number,
              time: getLessonTime(number),
              title: discipline['Title'] ?? 'Без названия',
              teacher: teacherObj != null ? teacherObj['FIO'] : 'Не указан',
              room: roomObj != null ? roomObj['Number'] : 'Не указана',
            ));
          }
        }
      }
    }

    // Обязательно сортируем по номеру пары
    lessons.sort((a, b) => a.number.compareTo(b.number));
    return lessons;
  }
}