import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _apiService.client.get('/worker/profile');
      if (mounted) setState(() => _isAvailable = res.data['is_available']);
    } catch(e) {}
  }

  Future<void> _toggleAvailability(bool val) async {
    setState(() => _isAvailable = val);
    try {
      await _apiService.client.put('/worker/profile', data: {'is_available': val});
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      setState(() => _isAvailable = !val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ Thợ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              user['full_name']?.toString().substring(0,1).toUpperCase() ?? 'W',
              style: TextStyle(fontSize: 36, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(user['full_name'] ?? 'Nhân viên Thợ', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Vai trò: Thợ dịch vụ', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          Container(
             decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20, offset: const Offset(0, 10),
                  )
                ]
            ),
            child: SwitchListTile(
              title: const Text('Sẵn sàng nhận việc', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Bật để nhận yêu cầu công việc ở gần bạn'),
              value: _isAvailable,
              activeColor: Theme.of(context).primaryColor,
              onChanged: _toggleAvailability,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Thu nhập & Lịch sử làm việc'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}
