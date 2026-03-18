import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.userProfile == null) {
            return const Center(child: Text('Не удалось загрузить профиль'));
          }

          final user = _controller.userProfile!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Аватарка
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: NetworkImage(user.photoUrl),
                  onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 60, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                // ФИО
                Text(
                  user.fio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Роли (Студент, Староста и т.д.)
                if (user.roles.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: user.roles.map((role) => Chip(
                      label: Text(role, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: AppColors.secondary,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                const SizedBox(height: 32),

                // Информационные карточки
                _buildInfoCard(Icons.email, 'Email', user.email),
                if (user.studentCode != null && user.studentCode!.isNotEmpty)
                  _buildInfoCard(Icons.badge, 'Код студента (1С)', user.studentCode!),

                const SizedBox(height: 40),
                // Кнопка выхода
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.logout(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
      ),
    );
  }
}