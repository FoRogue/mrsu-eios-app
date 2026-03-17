import 'package:flutter/material.dart';
import '../models/test_profile_item.dart';
import '../repositories/test_repository.dart';

class TestsListController extends ChangeNotifier {
  final TestRepository _repository = TestRepository();

  List<TestProfileItem> activeTests = [];
  List<TestProfileItem> archiveTests = [];

  bool isInitialLoading = true;

  // --- Состояния пагинации ---
  final int _limit = 20;

  int _activeOffset = 0;
  bool hasMoreActive = true;
  bool isFetchingMoreActive = false;

  int _archiveOffset = 0;
  bool hasMoreArchive = true;
  bool isFetchingMoreArchive = false;

  void init() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isInitialLoading = true;
    _activeOffset = 0;
    _archiveOffset = 0;
    hasMoreActive = true;
    hasMoreArchive = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTests(
          isArchive: false,
          count: _limit,
          offset: _activeOffset,
        ),
        _repository.getTests(
          isArchive: true,
          count: _limit,
          offset: _archiveOffset,
        ),
      ]);

      activeTests = results[0];
      archiveTests = results[1];

      // Если пришло меньше 20 тестов, значит это конец списка
      hasMoreActive = activeTests.length == _limit;
      hasMoreArchive = archiveTests.length == _limit;
    } catch (e) {
      debugPrint('Ошибка загрузки списков тестов: $e');
    } finally {
      isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActive() async {
    if (isFetchingMoreActive || !hasMoreActive) return;

    isFetchingMoreActive = true;
    notifyListeners();

    try {
      _activeOffset += _limit;
      final newItems = await _repository.getTests(
        isArchive: false,
        count: _limit,
        offset: _activeOffset,
      );
      activeTests.addAll(newItems);

      if (newItems.length < _limit) hasMoreActive = false;
    } catch (e) {
      hasMoreActive = false; // В случае ошибки прекращаем попытки
    } finally {
      isFetchingMoreActive = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreArchive() async {
    if (isFetchingMoreArchive || !hasMoreArchive) return;

    isFetchingMoreArchive = true;
    notifyListeners();

    try {
      _archiveOffset += _limit;
      final newItems = await _repository.getTests(
        isArchive: true,
        count: _limit,
        offset: _archiveOffset,
      );
      archiveTests.addAll(newItems);

      if (newItems.length < _limit) hasMoreArchive = false;
    } catch (e) {
      hasMoreArchive = false;
    } finally {
      isFetchingMoreArchive = false;
      notifyListeners();
    }
  }
}
