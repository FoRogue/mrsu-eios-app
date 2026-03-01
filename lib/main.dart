import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ЭИОС',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // Переменная для показа крутилки загрузки

  Future<void> _login() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите логин и пароль')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Показываем загрузку
    });

    try {
      // Подготавливаем URL
      final url = Uri.parse('https://p.mrsu.ru/OAuth/Token');

      // Отправляем POST запрос
      final response = await http.post(
        url,
        // Для oAuth запросов обычно используется такой формат тела:
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': '8',
          'client_secret': 'qweasd',
          'username': login,
          'password': password,
        },
      );

      // Проверяем успешность запроса (код 200)
      if (response.statusCode == 200) {
        // Парсим JSON ответ
        final Map<String, dynamic> data = json.decode(response.body);
        final String accessToken = data['access_token'];

        // Сохраняем токен в память телефона
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);

        print('Успешный вход! Токен: $accessToken');

        // Показываем сообщение об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Успешный вход! Токен сохранен.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
        }
      } else {
        // Если логин/пароль неверные (обычно код 400 или 401)
        print('Ошибка авторизации: ${response.statusCode} - ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверный логин или пароль'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // Если нет интернета или другая системная ошибка
      print('Ошибка сети: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Прячем загрузку
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход в ЭИОС'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(
                labelText: 'Логин',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              // Если идет загрузка, показываем крутилку, иначе кнопку
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Войти', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}