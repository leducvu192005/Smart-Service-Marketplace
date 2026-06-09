import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'about_screen.dart';
import 'favorite_services_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _fullProfile;

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    try {
      final res = await _apiService.client.get('/auth/me');
      if (mounted) setState(() => _fullProfile = res.data);
    } catch (_) {}
  }

  // ─────────────────────── Edit Profile Sheet ───────────────────────
  void _openEditProfile() {
    final user = _fullProfile ?? Provider.of<AuthProvider>(context, listen: false).user ?? {};
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Chỉnh sửa thông tin', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTextField(nameCtrl, 'Họ và tên', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'Không được để trống' : null),
                  const SizedBox(height: 14),
                  _buildTextField(emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? 'Email không hợp lệ' : null),
                  const SizedBox(height: 14),
                  _buildTextField(phoneCtrl, 'Số điện thoại', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7555CF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => saving = true);
                        try {
                          final res = await _apiService.client.put('/auth/me', data: {
                            'full_name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                          });
                          if (!mounted) return;
                          setState(() => _fullProfile = res.data);
                          await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _showSnack('Cập nhật thông tin thành công!', success: true);
                        } catch (e) {
                          setSheetState(() => saving = false);
                          _showSnack('Lỗi: Không thể cập nhật. Vui lòng thử lại.');
                        }
                      },
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Lưu thay đổi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Apply Worker Sheet ───────────────────────
  void _openApplyWorker() {
    final user = _fullProfile ?? Provider.of<AuthProvider>(context, listen: false).user ?? {};
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final skillsCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final idCardCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7555CF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.engineering_rounded, color: Color(0xFF7555CF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đăng ký trở thành Thợ',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Điền thông tin để Admin xét duyệt',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formSection('Thông tin cá nhân'),
                          _buildTextField(nameCtrl, 'Họ và tên *', Icons.person_outline,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 14),
                          _buildTextField(phoneCtrl, 'Số điện thoại *', Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 14),
                          _buildTextField(idCardCtrl, 'Số CCCD/CMND *', Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 14),
                          _buildTextField(addressCtrl, 'Địa chỉ thường trú *', Icons.home_outlined,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 20),
                          _formSection('Thông tin nghề nghiệp'),
                          _buildTextField(skillsCtrl, 'Kỹ năng (ví dụ: Điện, Nước, Dọn dẹp) *', Icons.build_outlined,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 14),
                          _buildTextField(expCtrl, 'Kinh nghiệm làm việc *', Icons.work_history_outlined,
                            maxLines: 3,
                            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null),
                          const SizedBox(height: 14),
                          _buildTextField(bioCtrl, 'Giới thiệu bản thân (tuỳ chọn)', Icons.notes_rounded, maxLines: 3),
                          const SizedBox(height: 16),
                          // Note box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Đơn đăng ký sẽ được Admin xem xét trong 1–3 ngày làm việc. '
                                    'Bạn sẽ nhận được thông báo khi có kết quả.',
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF92400E), height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7555CF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: submitting ? null : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => submitting = true);
                                try {
                                  await _apiService.client.post('/customer/apply-worker', data: {
                                    'full_name': nameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'id_card_number': idCardCtrl.text.trim(),
                                    'address': addressCtrl.text.trim(),
                                    'skills': skillsCtrl.text.trim(),
                                    'experience': expCtrl.text.trim(),
                                    'bio': bioCtrl.text.trim(),
                                  });
                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  _showSnack('Đơn đăng ký đã gửi! Admin sẽ xét duyệt sớm.', success: true);
                                } catch (e) {
                                  setSheetState(() => submitting = false);
                                  final msg = e.toString().contains('đã có đơn')
                                      ? 'Bạn đã có đơn đang chờ xét duyệt!'
                                      : 'Lỗi gửi đơn. Vui lòng thử lại.';
                                  _showSnack(msg);
                                }
                              },
                              child: submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Gửi đơn đăng ký', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Helpers ───────────────────────
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7555CF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF1F0EA))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF1F0EA))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7555CF), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      ),
      style: GoogleFonts.outfit(fontSize: 15),
    );
  }

  Widget _formSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7555CF))),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: success ? const Color(0xFF10B981) : Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────── Build ───────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = _fullProfile ?? auth.user ?? {};
    final name = user['full_name']?.toString() ?? 'Người dùng';
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: RefreshIndicator(
        onRefresh: _loadFullProfile,
        color: const Color(0xFF7555CF),
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7555CF), Color(0xFF4C35A3)],
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openEditProfile,
                          child: Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF7555CF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(email, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account section
                    _sectionTitle('Tài khoản'),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF7555CF),
                        title: 'Chỉnh sửa thông tin',
                        subtitle: 'Cập nhật tên, email, số điện thoại',
                        onTap: _openEditProfile,
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Đổi mật khẩu',
                        subtitle: 'Bảo mật tài khoản của bạn',
                        onTap: () => _showSnack('Tính năng sắp có!'),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Become worker section
                    _sectionTitle('Cơ hội kiếm thêm thu nhập'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openApplyWorker,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7555CF), Color(0xFF4C35A3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7555CF).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Trở thành Thợ',
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('Đăng ký để nhận việc & tăng thu nhập',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App section
                    _sectionTitle('Ứng dụng'),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Về chúng tôi',
                        subtitle: 'Tính năng & thông tin ứng dụng',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: 'Dịch vụ yêu thích',
                        subtitle: 'Xem các dịch vụ bạn đã lưu',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoriteServicesScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.star_outline_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Đánh giá ứng dụng',
                        subtitle: 'Giúp chúng tôi cải thiện hơn',
                        onTap: () => _showSnack('Cảm ơn bạn! 🙏'),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          foregroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Đăng xuất?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              content: Text('Bạn có chắc muốn đăng xuất không?', style: GoogleFonts.outfit()),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Đăng xuất', style: TextStyle(color: Colors.red[700])),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            await auth.logout();
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text('Đăng xuất', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5));
  }

  Widget _menuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F0EA)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: item.iconColor),
                ),
                title: Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(item.subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
                onTap: item.onTap,
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});
}
