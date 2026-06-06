import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class SupportAccountsScreen extends StatefulWidget {
  const SupportAccountsScreen({super.key});

  @override
  State<SupportAccountsScreen> createState() => _SupportAccountsScreenState();
}

class _SupportAccountsScreenState extends State<SupportAccountsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/admin/support-logs');
      setState(() {
        _logs = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải nhật ký hoạt động: $e')),
      );
    }
  }

  Future<void> _createSupportAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await _apiService.client.post(
        '/admin/support-accounts',
        data: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'password': _passwordController.text,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo tài khoản Hỗ trợ thành công!')),
      );
      _usernameController.clear();
      _emailController.clear();
      _fullNameController.clear();
      _passwordController.clear();
      _fetchLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký tài khoản hỗ trợ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Nhân Sự & Nhật Ký', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.person_add_outlined), text: 'Thêm hỗ trợ'),
              Tab(icon: Icon(Icons.history_toggle_off_outlined), text: 'Nhật ký hoạt động'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateAccountTab(),
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tạo Tài Khoản Nhân Viên Hỗ Trợ',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhân viên hỗ trợ sẽ có quyền điều phối đơn hàng, duyệt hồ sơ thợ và xử lý khiếu nại.',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên nhân viên',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.account_circle),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (val) => val == null || !val.contains('@') ? 'Vui lòng nhập email hợp lệ' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (val) => val == null || val.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createSupportAccount,
              child: Text('Đăng ký Tài khoản', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    return RefreshIndicator(
      onRefresh: _fetchLogs,
      child: _logs.isEmpty
          ? Center(child: Text('Chưa có hoạt động nào được ghi nhận', style: GoogleFonts.outfit(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, idx) {
                final log = _logs[idx];
                final createdTimeStr = log['created_at'] ?? '';
                final DateTime createdTime = createdTimeStr.isNotEmpty
                    ? DateTime.parse(createdTimeStr)
                    : DateTime.now();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.history, color: Colors.indigo)),
                    title: Text(log['action'] ?? 'Hành động', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      '${log['details'] ?? ""}\nThời gian: ${createdTime.day}/${createdTime.month} ${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
