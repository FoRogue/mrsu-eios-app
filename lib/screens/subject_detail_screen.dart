import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../controllers/subject_detail_controller.dart';
import './test_passing_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final int subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final SubjectDetailController _controller = SubjectDetailController();

  @override
  void initState() {
    super.initState();
    _controller.loadDetails(widget.subjectId);
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
        if (_controller.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Успеваемость'), backgroundColor: AppColors.primary),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_controller.subjectData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ошибка'), backgroundColor: AppColors.primary),
            body: const Center(child: Text('Не удалось загрузить данные')),
          );
        }

        final data = _controller.subjectData!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Детали предмета', style: TextStyle(color: Colors.white, fontSize: 16)),
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...data.sections.map((section) => _buildSectionCard(section)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...section.controlDots.map((dot) => _buildControlDot(dot)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDot(dot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(dot.titleWithDate, style: const TextStyle(fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  dot.scoreDisplay,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (dot.isTest) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showStartTestDialog(dot.testProfileId!),
              icon: const Icon(Icons.assignment, size: 18),
              label: const Text('Пройти тест'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
          if (dot.isReport) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Требуется прикрепить отчет (через сайт)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showStartTestDialog(int testProfileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начать тестирование?'),
        content: const Text('Вы уверены? Будет использована одна попытка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TestPassingScreen(profileId: testProfileId)),
              );
            },
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}