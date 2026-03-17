import 'package:flutter/material.dart';
import '../models/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  DateTime selectedDate = DateTime.now();
  List<ScheduleItem> dailyItems = [];
  bool isLoading = false;
  bool isMonthView = false;

  void init() {
    loadSchedule();
  }

  void toggleCalendarView() {
    isMonthView = !isMonthView;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    if (selectedDate.year == date.year &&
        selectedDate.month == date.month &&
        selectedDate.day == date.day)
      return;

    selectedDate = date;
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    isLoading = true;
    notifyListeners();

    try {
      final lessons = await _repository.getLessons(selectedDate);
      dailyItems = _injectWindows(lessons);
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      dailyItems = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Магия вычисления отсутствующих пар (включая те, что ПЕРЕД первой)
  List<ScheduleItem> _injectWindows(List<LessonItem> lessons) {
    if (lessons.isEmpty) return [];

    List<ScheduleItem> itemsWithWindows = [];

    // 1. Проверяем, есть ли пустые пары с утра (перед первой в списке)
    int firstLessonNumber = lessons.first.number;
    if (firstLessonNumber > 1) {
      for (int gap = 1; gap < firstLessonNumber; gap++) {
        itemsWithWindows.add(
          WindowItem(number: gap, time: _repository.getLessonTime(gap)),
        );
      }
    }

    // 2. Вставляем сами пары и проверяем дыры между ними
    for (int i = 0; i < lessons.length; i++) {
      itemsWithWindows.add(lessons[i]);

      if (i < lessons.length - 1) {
        int currentNumber = lessons[i].number;
        int nextNumber = lessons[i + 1].number;

        if (nextNumber - currentNumber > 1) {
          for (int gap = currentNumber + 1; gap < nextNumber; gap++) {
            itemsWithWindows.add(
              WindowItem(number: gap, time: _repository.getLessonTime(gap)),
            );
          }
        }
      }
    }
    return itemsWithWindows;
  }
}
