import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../core/constants.dart';

class SubjectDetailScreen extends StatefulWidget {
  final int subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _subjectData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final data = await _apiService.getSubjectDetails(widget.subjectId);
    if (mounted) {
      setState(() {
        _subjectData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Загрузка...'), backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_subjectData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка'), backgroundColor: AppColors.primary),
        body: const Center(child: Text('Не удалось загрузить данные')),
      );
    }

    final title = _subjectData!['title'];
    final sections = _subjectData!['sections'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Успеваемость', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sections.map((section) {
              final sectionTitle = section['Title'] ?? 'Без названия';
              final controlDots = section['ControlDots'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sectionTitle, style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...controlDots.map((dot) {
                        final dotTitle = dot['Title'] ?? 'Без названия';
                        final mark = dot['Mark']?['Ball'] ?? 'Нет оценки';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(dotTitle)),
                              Text(mark.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}