abstract class ScheduleItem {
  final int number;
  final String time;

  ScheduleItem({required this.number, required this.time});
}

class LessonItem extends ScheduleItem {
  final int id;
  final String title;
  final String teacher;
  final String room;

  LessonItem({
    required super.number,
    required super.time,
    required this.id,
    required this.title,
    required this.teacher,
    required this.room,
  });
}

class WindowItem extends ScheduleItem {
  WindowItem({required super.number, required super.time});
}
