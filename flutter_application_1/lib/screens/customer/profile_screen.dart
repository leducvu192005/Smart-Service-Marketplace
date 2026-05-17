import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                user['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(fontSize: 36, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(user['full_name'] ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Chỉnh sửa thông tin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt ứng dụng'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Trợ giúp & Hỗ trợ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Đăng xuất',
              onPressed: () async {
                await auth.logout();
                // The main.dart Consumer will automatically show the LoginScreen.
              },
            ),
          ],
        ),
      ),
    );
  }
}
