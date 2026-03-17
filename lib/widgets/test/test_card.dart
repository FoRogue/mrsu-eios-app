import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/test_profile_item.dart';
import '../../screens/test_passing_screen.dart';
import '../../screens/test_results_screen.dart'; // Этот экран создадим ниже

class TestCard extends StatelessWidget {
  final TestProfileItem testItem;
  final bool isArchive;

  const TestCard({super.key, required this.testItem, required this.isArchive});

  @override
  Widget build(BuildContext context) {
    final bool canStart =
        testItem.canStart && testItem.attemptsLeft > 0 && !isArchive;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.assignment, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testItem.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        testItem.discipline,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱ Время: ${testItem.duration > 0 ? '${testItem.duration} мин' : 'Без лимита'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '📝 Вопросов: ${testItem.questionsCount}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (!isArchive)
                      Text(
                        '🔄 Осталось попыток: ${testItem.attemptsLeft > 100 ? '∞' : testItem.attemptsLeft}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (isArchive)
                      Text(
                        '🏆 Лучший балл: ${testItem.result}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canStart
                        ? AppColors.primary
                        : Colors.grey.shade200,
                    foregroundColor: canStart ? Colors.white : Colors.black87,
                    elevation: canStart ? 2 : 0,
                  ),
                  onPressed: () {
                    if (canStart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TestPassingScreen(profileId: testItem.profileId),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestResultsScreen(
                            profileId: testItem.profileId,
                            title: testItem.title,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(canStart ? 'Начать' : 'Результаты'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
