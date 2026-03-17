import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../controllers/performance_controller.dart';
import 'subject_detail_screen.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceController _controller = PerformanceController();

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
            _buildFilters(),
            const Divider(height: 1),
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.subjects.isEmpty
                  ? const Center(child: Text('Нет данных о предметах'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _controller.subjects.length,
                itemBuilder: (context, index) {
                  final subject = _controller.subjects[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        subject.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectDetailScreen(subjectId: subject.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    if (_controller.availableYears.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _controller.selectedYear,
              items: _controller.availableYears.map((year) {
                return DropdownMenuItem(value: year, child: Text('$year-${year + 1} год'));
              }).toList(),
              onChanged: (val) {
                if (val != null) _controller.updateYear(val);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _controller.selectedSemester,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Осенний')),
                DropdownMenuItem(value: 2, child: Text('Весенний')),
              ],
              onChanged: (val) {
                if (val != null) _controller.updateSemester(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}