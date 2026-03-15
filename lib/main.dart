import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Импорт языков
import 'core/constants.dart';
import 'core/globals.dart'; // <-- 1. ДОБАВИЛИ ИМПОРТ НАШЕГО КЛЮЧА
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

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
      navigatorKey: appNavigatorKey, // <-- 2. ПРИВЯЗАЛИ КЛЮЧ К ПРИЛОЖЕНИЮ
      title: 'ЭИОС МГУ',
      debugShowCheckedModeBanner: false,

      // --- НАСТРОЙКИ ЛОКАЛИЗАЦИИ ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Указываем поддержку русского
      ],
      locale: const Locale('ru', 'RU'), // Принудительно включаем русский
      // -----------------------------

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: initialRoute,
    );
  }
}