import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../repositories/subject_repository.dart';

class PerformanceController extends ChangeNotifier {
  final SubjectRepository _repository = SubjectRepository();

  List<Subject> subjects = [];
  bool isLoading = true;

  late int selectedYear;
  late int selectedSemester;
  late List<int> availableYears;

  void init() {
    _initCurrentAcademicDates();
    loadSubjects(useFilters: false);
  }

  void _initCurrentAcademicDates() {
    final now = DateTime.now();
    int currentAcademicYearStart;

    if (now.month >= 9) {
      currentAcademicYearStart = now.year;
      selectedSemester = 1;
    } else {
      currentAcademicYearStart = now.year - 1;
      selectedSemester = now.month == 1 ? 1 : 2;
    }

    selectedYear = currentAcademicYearStart;
    availableYears = [
      currentAcademicYearStart,
      currentAcademicYearStart - 1,
      currentAcademicYearStart - 2,
      currentAcademicYearStart - 3,
    ];
  }

  Future<void> loadSubjects({bool useFilters = true}) async {
    isLoading = true;
    notifyListeners();

    try {
      subjects = await _repository.getSubjects(
        year: useFilters ? selectedYear : null,
        semester: useFilters ? selectedSemester : null,
        isMessages: false, // ВАЖНО: Для успеваемости t=m не нужно
      );
    } catch (e) {
      subjects = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateYear(int year) {
    if (selectedYear == year) return;
    selectedYear = year;
    loadSubjects(useFilters: true);
  }

  void updateSemester(int semester) {
    if (selectedSemester == semester) return;
    selectedSemester = semester;
    loadSubjects(useFilters: true);
  }
}