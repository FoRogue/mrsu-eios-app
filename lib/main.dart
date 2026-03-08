import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

// Теперь функция main асинхронная, чтобы дождаться ответа от памяти телефона
void main() async {
  // Эта строчка обязательна, если мы используем await до runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем, есть ли у нас уже сохраненный токен
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

  // Если токен есть, стартуем с главного меню, иначе - с экрана логина
  runApp(MyApp(
    initialRoute: token != null ? const MainScreen() : const LoginScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ЭИОС МГУ',
      debugShowCheckedModeBanner: false, // 1. Убираем красную ленточку DEBUG
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: initialRoute, // Запускаем нужный экран
    );
  }
}