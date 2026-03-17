import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/test/test_card.dart';
import '../controllers/tests_list_controller.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final TestsListController _controller = TestsListController();

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Тесты', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.secondary,
            tabs: [
              Tab(text: 'Активные'),
              Tab(text: 'Архив'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildList(
                  tests: _controller.activeTests,
                  isArchive: false,
                  isFetchingMore: _controller.isFetchingMoreActive,
                ),
                _buildList(
                  tests: _controller.archiveTests,
                  isArchive: true,
                  isFetchingMore: _controller.isFetchingMoreArchive,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList({
    required List tests,
    required bool isArchive,
    required bool isFetchingMore,
  }) {
    return RefreshIndicator(
      onRefresh: _controller.loadInitialData,
      child: tests.isEmpty
          ? Center(child: Text(isArchive ? 'Архив пуст' : 'Нет доступных тестов'))
      // NotificationListener перехватывает системные события скролла (работает железобетонно)
          : NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Если докрутили почти до конца списка
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            if (isArchive) {
              _controller.loadMoreArchive();
            } else {
              _controller.loadMoreActive();
            }
          }
          return false;
        },
        child: ListView.builder(
          // PageStorageKey заставляет Flutter запоминать позицию скролла на каждой вкладке!
          key: PageStorageKey(isArchive ? 'archive_list_key' : 'active_list_key'),
          physics: const AlwaysScrollableScrollPhysics(), // Чтобы RefreshIndicator работал даже если тестов мало
          padding: const EdgeInsets.all(16),
          itemCount: tests.length + (isFetchingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Отрисовка лоадера в самом низу списка при подгрузке
            if (index == tests.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return TestCard(testItem: tests[index], isArchive: isArchive);
          },
        ),
      ),
    );
  }
}