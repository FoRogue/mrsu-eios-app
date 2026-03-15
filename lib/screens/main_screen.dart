import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../api/auth_service.dart';
import 'login_screen.dart';
import 'performance_screen.dart';
import 'schedule_screen.dart';
import 'communications_screen.dart'; // Наш новый экран!

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const ScheduleScreen(),
      const PerformanceScreen(),
      const CommunicationsScreen(), // Подключили новый раздел "Общение"
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Экран: Прочее', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из профиля'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ЭИОС МГУ', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Успеваемость',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Общение',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Прочее',
          ),
        ],
      ),
    );
  }
}