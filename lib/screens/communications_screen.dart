import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'communication_chat_screen.dart';
import '../controllers/communications_controller.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final CommunicationsController _controller = CommunicationsController();

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
                  ? const Center(child: Text('Нет предметов для общения'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _controller.subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _controller.subjects[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.forum,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              subject.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.primary,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunicationChatScreen(
                                    subjectId: subject.id,
                                    subjectTitle: subject.title,
                                  ),
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
    // Если даты еще не проинициализировались (первая миллисекунда)
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
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year-${year + 1} год'),
                );
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
