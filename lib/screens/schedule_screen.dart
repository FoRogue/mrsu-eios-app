import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../core/constants.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _dailyLessons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _getLessonTime(int number) {
    const times = {
      1: "08:00 - 09:30",
      2: "09:45 - 11:15",
      3: "11:35 - 13:05",
      4: "13:20 - 14:50",
      5: "15:00 - 16:30",
      6: "16:40 - 18:10",
      7: "18:15 - 19:45",
      8: "19:45 - 21:20",
    };
    return times[number] ?? "Время не указано";
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    try {
      final targetDateStr = _formatDate(_selectedDate);
      final data = await _apiService.getSchedule(targetDateStr);

      List<Map<String, dynamic>> filteredLessons = [];

      if (data.isNotEmpty) {
        for (var dayData in data) {
          final timeTable = dayData['TimeTable'] ?? dayData;
          final lessons = timeTable['Lessons'] as List? ?? [];

          for (var lesson in lessons) {
            int number = int.tryParse(lesson['Number']?.toString() ?? '0') ?? 0;
            final disciplines = lesson['Disciplines'] as List? ?? [];

            for (var discipline in disciplines) {
              // Подгруппы больше не проверяем, берем все дисциплины
              final teacherObj = discipline['Teacher'];
              final teacher = teacherObj != null ? teacherObj['FIO'] : 'Не указан';

              final roomObj = discipline['Auditorium'];
              final room = roomObj != null ? roomObj['Number'] : 'Не указана';

              filteredLessons.add({
                'time': _getLessonTime(number),
                'title': discipline['Title'] ?? 'Без названия',
                'teacher': teacher,
                'room': room,
                'number': number,
              });
            }
          }
        }
      }

      // Сортируем пары по времени (номеру)
      filteredLessons.sort((a, b) => a['number'].compareTo(b['number']));

      if (mounted) {
        setState(() {
          _dailyLessons = filteredLessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailyLessons = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (newDate) {
              setState(() => _selectedDate = newDate);
              _loadSchedule();
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _dailyLessons.isEmpty
              ? const Center(
            child: Text(
              'Пар нет. Отдыхаем! 😴',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: _dailyLessons.length,
            itemBuilder: (context, index) {
              final lesson = _dailyLessons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            lesson['time'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(width: 2, height: 50, color: AppColors.secondary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('👤 ${lesson['teacher']}', style: const TextStyle(color: Colors.black87)),
                            Text('🚪 Аудитория: ${lesson['room']}', style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}