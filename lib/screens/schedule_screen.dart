import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'subject_detail_screen.dart';
import '../controllers/schedule_controller.dart';
import '../models/schedule_item.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleController _controller = ScheduleController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _buildCalendarHeader(),
            _buildAnimatedCalendar(),
            const Divider(height: 1),
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.dailyItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Пар нет. Отдыхаем! 😴',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _controller.dailyItems.length,
                      itemBuilder: (context, index) {
                        final item = _controller.dailyItems[index];
                        if (item is LessonItem) {
                          return _buildLessonCard(item);
                        } else if (item is WindowItem) {
                          return _buildWindowCard(item);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_controller.selectedDate.day}.${_controller.selectedDate.month.toString().padLeft(2, '0')}.${_controller.selectedDate.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          TextButton.icon(
            onPressed: _controller.toggleCalendarView,
            icon: Icon(
              _controller.isMonthView
                  ? Icons.expand_less
                  : Icons.calendar_month,
            ),
            label: Text(_controller.isMonthView ? 'Свернуть' : 'Календарь'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCalendar() {
    return AnimatedCrossFade(
      firstChild: _buildWeekStrip(),
      secondChild: Container(
        color: Colors.white,
        child: CalendarDatePicker(
          initialDate: _controller.selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: _controller.selectDate,
        ),
      ),
      crossFadeState: _controller.isMonthView
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 31,
        controller: ScrollController(
          initialScrollOffset:
              15 * 60.0 - (MediaQuery.of(context).size.width / 2) + 30,
        ),
        itemBuilder: (context, index) {
          final date = now
              .subtract(const Duration(days: 15))
              .add(Duration(days: index));
          final isSelected =
              date.year == _controller.selectedDate.year &&
              date.month == _controller.selectedDate.month &&
              date.day == _controller.selectedDate.day;

          return GestureDetector(
            onTap: () => _controller.selectDate(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayShort(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = {
      1: 'Пн',
      2: 'Вт',
      3: 'Ср',
      4: 'Чт',
      5: 'Пт',
      6: 'Сб',
      7: 'Вс',
    };
    return days[weekday] ?? '';
  }

  // КАРТОЧКА ОБЫЧНОЙ ПАРЫ
  Widget _buildLessonCard(LessonItem lesson) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (lesson.id != 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectDetailScreen(subjectId: lesson.id),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Детали для этого предмета недоступны'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Левая колонка (Цифра и время)
              SizedBox(
                width: 85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${lesson.number}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.time,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Разделитель
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Правая колонка с информацией
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '👤 ${lesson.teacher}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🚪 ${lesson.room}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // КАРТОЧКА ПУСТОЙ ПАРЫ (ОКНА ИЛИ УТРА)
  Widget _buildWindowCard(WindowItem window) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          // Левая колонка (такой же ширины, как у обычной пары, чтобы всё было в линию)
          SizedBox(
            width: 85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${window.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  window.time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 2, height: 30, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          // Правая колонка
          Expanded(
            child: Row(
              children: [
                Icon(Icons.coffee, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Занятия нет',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
