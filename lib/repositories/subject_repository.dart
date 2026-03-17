import '../api/api_service.dart';
import '../models/subject.dart';

class SubjectRepository {
  final ApiService _apiService = ApiService();

  // Для списков предметов (Успеваемость и Общение)
  Future<List<Subject>> getSubjects({
    int? year,
    int? semester,
    bool isMessages = false,
  }) async {
    final rawData = await _apiService.getSubjects(
      year: year,
      semester: semester,
      isMessages: isMessages,
    );
    return rawData.map((json) => Subject.fromJson(json)).toList();
  }

  // Для деталей конкретного предмета
  Future<Map<String, dynamic>?> getSubjectDetailsRaw(int subjectId) async {
    return await _apiService.getSubjectDetails(subjectId);
  }
}
