import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class SupportAccountsPage extends StatefulWidget {
  const SupportAccountsPage({super.key});

  @override
  State<SupportAccountsPage> createState() => _SupportAccountsPageState();
}

class _SupportAccountsPageState extends State<SupportAccountsPage> {
  final ApiService _api = ApiService();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  List<dynamic> _accounts = [];
  bool _loading = false;
  bool _creating = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/admin/support-accounts');
      if (mounted)
        setState(() {
          _accounts = res.data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _nameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      _snack('Vui lòng điền đầy đủ thông tin!', Colors.orange);
      return;
    }
    setState(() => _creating = true);
    try {
      await _api.client.post(
        '/admin/support-accounts',
        data: {
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'role': 'support',
        },
      );
      _snack(
        '✅ Tạo tài khoản support "${_nameCtrl.text.trim()}" thành công!',
        Colors.green,
      );
      _usernameCtrl.clear();
      _emailCtrl.clear();
      _nameCtrl.clear();
      _passwordCtrl.clear();
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deactivate(int id) async {
    try {
      await _api.client.put('/admin/users/$id/toggle-active');
      _snack('Đã thay đổi trạng thái tài khoản.', Colors.orange);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create form
          SizedBox(
            width: 360,
            child: WebCard(
              title: 'Tạo Tài Khoản Support Mới',
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _field(
                      'Tên đăng nhập',
                      _usernameCtrl,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Địa chỉ Email',
                      _emailCtrl,
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _field('Họ và Tên', _nameCtrl, Icons.badge_outlined),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Role indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quyền: Nhân Viên Hỗ Trợ (Support)',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF4F46E5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1, size: 18),
                        label: Text(
                          _creating ? 'Đang tạo...' : 'Tạo Tài Khoản',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _creating ? null : _create,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Accounts list
          Expanded(
            child: WebCard(
              title: 'Danh Sách Nhân Viên Support',
              badge: '${_accounts.length}',
              badgeColor: const Color(0xFF4F46E5),
              action: IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _load,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _accounts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Chưa có tài khoản support nào',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: _accounts
                          .map(
                            (acc) => _AccountRow(
                              account: acc,
                              onToggle: () => _deactivate(acc['id']),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onToggle;

  const _AccountRow({required this.account, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isActive = account['is_active'] ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
            child: Text(
              (account['full_name'] ?? 'S')
                  .toString()
                  .substring(0, 1)
                  .toUpperCase(),
              style: GoogleFonts.outfit(
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['full_name'] ?? 'Support',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  account['email'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '@${account['username'] ?? ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'SUPPORT',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: isActive,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Hoạt Động' : 'Đã Vô Hiệu',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isActive ? const Color(0xFF10B981) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
