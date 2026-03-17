import 'package:flutter/material.dart';
import '../models/subject_detail.dart';
import '../repositories/subject_repository.dart';

class SubjectDetailController extends ChangeNotifier {
  final SubjectRepository _repository = SubjectRepository();

  SubjectDetail? subjectData;
  bool isLoading = true;

  Future<void> loadDetails(int subjectId) async {
    isLoading = true;
    notifyListeners();

    try {
      final rawData = await _repository.getSubjectDetailsRaw(subjectId);
      if (rawData != null) {
        subjectData = SubjectDetail.fromJson(rawData);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки деталей предмета: $e');
      subjectData = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}