import '../api/api_service.dart';
import '../models/test_profile_item.dart';

class TestRepository {
  final ApiService _apiService = ApiService();

  Future<List<TestProfileItem>> getTests({
    required bool isArchive,
    int count = 20,
    int offset = 0,
  }) async {
    final rawData = await _apiService.getAvailableTests(
      isArchive: isArchive,
      count: count,
      offset: offset,
    );
    return rawData.map((json) => TestProfileItem.fromJson(json)).toList();
  }

  Future<List<TestResultItem>> getTestResults(int profileId) async {
    final rawData = await _apiService.getTestResults(profileId);
    return rawData.map((json) => TestResultItem.fromJson(json)).toList();
  }
}
