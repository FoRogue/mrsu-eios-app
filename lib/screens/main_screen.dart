import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../api/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Функция выхода из профиля
  void _logout() async {
    // Вызываем очистку токена из сервиса
    await AuthService().logout();

    // Перекидываем пользователя обратно на экран логина
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Вставляем кнопку выхода на 4-й экран
    final List<Widget> pages = [
      const Center(child: Text('Экран: Расписание', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Экран: Успеваемость', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Экран: Общение', style: TextStyle(fontSize: 24))),
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
                backgroundColor: Colors.redAccent, // Красная кнопка выхода
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Расписание'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Успеваемость'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Общение'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Прочее'),
        ],
      ),
    );
  }
}