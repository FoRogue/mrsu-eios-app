import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/test_profile_item.dart';
import '../repositories/test_repository.dart';

class TestResultsScreen extends StatefulWidget {
  final int profileId;
  final String title;

  const TestResultsScreen({
    super.key,
    required this.profileId,
    required this.title,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final TestRepository _repository = TestRepository();
  List<TestResultItem> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final results = await _repository.getTestResults(widget.profileId);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Результаты попыток',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(child: Text('Вы еще не проходили этот тест'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final res = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: res.score >= 50
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: res.score >= 50
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Результат: ${res.score}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Завершен: ${res.formattedDate}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
