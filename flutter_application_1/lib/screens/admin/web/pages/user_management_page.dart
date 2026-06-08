import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/admin/users');
      if (mounted)
        setState(() {
          _users = res.data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(int id) async {
    try {
      await _api.client.put('/admin/users/$id/toggle-active');
      _snack('Đã cập nhật trạng thái tài khoản.', Colors.orange);
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    }
  }

  Future<void> _resetPassword(int id) async {
    try {
      final res = await _api.client.post('/admin/users/$id/reset-password');
      final newPwd = res.data['new_password'] ?? '123456';
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'Mật Khẩu Mới',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mật khẩu đã được đặt lại thành:',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    newPwd,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4F46E5),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy thông báo cho người dùng.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
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

  List<dynamic> get _filtered {
    var list = _filterRole == 'all'
        ? _users
        : _users.where((u) => u['role'] == _filterRole).toList();
    if (_search.isNotEmpty) {
      list = list
          .where(
            (u) =>
                (u['full_name'] ?? '').toString().toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                (u['email'] ?? '').toString().toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                (u['username'] ?? '').toString().toLowerCase().contains(
                  _search.toLowerCase(),
                ),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _users.where((u) => u['role'] == 'customer').length;
    final workers = _users.where((u) => u['role'] == 'worker').length;
    final support = _users.where((u) => u['role'] == 'support').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Summary stats
          Row(
            children: [
              _SummaryChip(
                'Tổng Người Dùng',
                '${_users.length}',
                const Color(0xFF4F46E5),
                Icons.group_rounded,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                'Khách Hàng',
                '$customers',
                const Color(0xFF3B82F6),
                Icons.person_rounded,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                'Thợ',
                '$workers',
                const Color(0xFF10B981),
                Icons.construction_rounded,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                'Hỗ Trợ',
                '$support',
                const Color(0xFFF59E0B),
                Icons.support_agent_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),

          WebCard(
            title: 'Danh Sách Tất Cả Người Dùng',
            badge: '${_filtered.length}',
            action: Row(
              children: [
                // Search
                SizedBox(
                  width: 240,
                  height: 36,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                    ),
                    style: GoogleFonts.outfit(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                ...[
                  ('all', 'Tất cả'),
                  ('customer', 'Khách hàng'),
                  ('worker', 'Thợ'),
                  ('support', 'Support'),
                ].map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(
                        e.$2,
                        style: GoogleFonts.outfit(fontSize: 11),
                      ),
                      selected: _filterRole == e.$1,
                      selectedColor: const Color(0xFF4F46E5),
                      labelStyle: TextStyle(
                        color: _filterRole == e.$1
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      onSelected: (_) => setState(() => _filterRole = e.$1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _load,
                ),
              ],
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Không tìm thấy người dùng nào',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  )
                : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        // Header
        Container(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          child: Row(
            children: [
              _th('Người Dùng', flex: 4),
              _th('Email', flex: 3),
              _th('Quyền', flex: 2),
              _th('Trạng Thái', flex: 2),
              _th('Thao Tác', flex: 3),
            ],
          ),
        ),
        ..._filtered.map((u) {
          final isActive = u['is_active'] ?? true;
          final role = u['role'] ?? 'customer';
          Color roleColor = const Color(0xFF3B82F6);
          String roleText = 'Khách Hàng';
          if (role == 'worker') {
            roleColor = const Color(0xFF10B981);
            roleText = 'Thợ';
          } else if (role == 'support') {
            roleColor = const Color(0xFFF59E0B);
            roleText = 'Support';
          } else if (role == 'admin') {
            roleColor = const Color(0xFF4F46E5);
            roleText = 'Admin';
          }

          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: roleColor.withOpacity(0.1),
                          child: Text(
                            (u['full_name'] ?? 'U')
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['full_name'] ?? 'User',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '@${u['username'] ?? ''}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      u['email'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        roleText,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Hoạt Động' : 'Bị Khóa',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        if (role != 'admin') ...[
                          Tooltip(
                            message: isActive
                                ? 'Khóa tài khoản'
                                : 'Mở khóa tài khoản',
                            child: InkWell(
                              onTap: () => _toggleActive(u['id']),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (isActive ? Colors.red : Colors.green)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isActive
                                      ? Icons.lock_outline
                                      : Icons.lock_open_outlined,
                                  size: 16,
                                  color: isActive ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Đặt lại mật khẩu',
                            child: InkWell(
                              onTap: () => _resetPassword(u['id']),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.key_outlined,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _th(String text, {int flex = 1}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;

  const _SummaryChip(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
