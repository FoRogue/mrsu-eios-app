import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../core/constants.dart';
import 'communication_chat_screen.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  late int _selectedYear;
  late int _selectedSemester;
  late List<int> _availableYears;

  @override
  void initState() {
    super.initState();
    _initCurrentAcademicDates();
    _loadSubjects(useFilters: false);
  }

  void _initCurrentAcademicDates() {
    final now = DateTime.now();
    int currentAcademicYearStart;

    if (now.month >= 9) {
      currentAcademicYearStart = now.year;
      _selectedSemester = 1;
    } else {
      currentAcademicYearStart = now.year - 1;
      if (now.month == 1) {
        _selectedSemester = 1;
      } else {
        _selectedSemester = 2;
      }
    }

    _selectedYear = currentAcademicYearStart;

    _availableYears = [
      currentAcademicYearStart,
      currentAcademicYearStart - 1,
      currentAcademicYearStart - 2,
      currentAcademicYearStart - 3,
    ];
  }

  Future<void> _loadSubjects({bool useFilters = true}) async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _apiService.getSubjects(
        year: useFilters ? _selectedYear : null,
        semester: useFilters ? _selectedSemester : null,
        isMessages: true, // ВАЖНО: Подставляет t=m в запрос
      );
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedYear,
                  items: _availableYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year-${year + 1} год'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadSubjects(useFilters: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedSemester,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Осенний')),
                    DropdownMenuItem(value: 2, child: Text('Весенний')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSemester = val);
                      _loadSubjects(useFilters: true);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _subjects.isEmpty
              ? const Center(child: Text('Нет предметов для общения'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
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
                          subject['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                                subjectId: subject['id'],
                                subjectTitle: subject['title'],
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
  }
}
