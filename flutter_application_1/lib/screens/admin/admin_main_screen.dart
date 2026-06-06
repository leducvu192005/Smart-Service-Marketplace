import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

import 'worker_verification_screen.dart';
import 'booking_dispatch_screen.dart';
import 'ticket_management_screen.dart';
import 'service_management_screen.dart';
import 'financial_screen.dart';
import 'support_accounts_screen.dart';
import 'marketing_screen.dart';
import 'user_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final res = await _apiService.client.get('/admin/dashboard');
      if (mounted) {
        setState(() {
          _stats = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.role ?? 'support';
    final bool isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Hệ Thống Quản Trị Admin' : 'Hệ Thống Hỗ Trợ Support',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Welcome Header
                  Text(
                    'Xin chào, ${auth.user?['full_name'] ?? (isAdmin ? "Quản trị viên" : "Nhân viên Hỗ trợ")}',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                  ),
                  Text(
                    'Hôm nay bạn muốn thực hiện tác vụ nào?',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Dashboard Cards (Visible to both but with different data scope if needed)
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Khách Hàng',
                        value: '${_stats['total_users'] ?? 0}',
                        color: Colors.blue,
                        icon: Icons.people,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Nhân Viên Thợ',
                        value: '${_stats['total_workers'] ?? 0}',
                        color: Colors.purple,
                        icon: Icons.construction,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Đơn Đặt Lịch',
                        value: '${_stats['total_bookings'] ?? 0}',
                        color: Colors.orange,
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Doanh Thu',
                        value: '\$${_stats['total_revenue'] ?? 0}',
                        color: Colors.green,
                        icon: Icons.payments,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Management Features Section
                  Text(
                    'Danh mục quản lý',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                  ),
                  const SizedBox(height: 16),

                  // Common management items (Both Admin & Support)
                  _buildMenuTile(
                    title: 'Duyệt Hồ Sơ Thợ',
                    subtitle: 'Duyệt thợ đăng ký mới, cập nhật trạng thái hoạt động',
                    icon: Icons.how_to_reg_outlined,
                    color: Colors.purple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const WorkerVerificationScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    title: 'Điều Phối Đơn Hàng',
                    subtitle: 'Xác nhận thu tiền, đổi lịch hẹn, đổi thợ, hủy đơn',
                    icon: Icons.alt_route_outlined,
                    color: Colors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const BookingDispatchScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    title: 'Hỗ Trợ & Khiếu Nại (Tickets)',
                    subtitle: 'Tiếp nhận ý kiến khách hàng & thợ, chat hỗ trợ',
                    icon: Icons.question_answer_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const TicketManagementScreen()),
                    ),
                  ),

                  // Admin-Only Items
                  if (isAdmin) ...[
                    _buildMenuTile(
                      title: 'Thiết Lập Dịch Vụ & Biểu Giá',
                      subtitle: 'Thêm/Sửa/Xóa danh mục, thiết lập giá trị dịch vụ',
                      icon: Icons.room_service_outlined,
                      color: Colors.teal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ServiceManagementScreen()),
                      ),
                    ),
                    _buildMenuTile(
                      title: 'Quản Lý Tài Chính & Rút Tiền',
                      subtitle: 'Phê duyệt rút tiền, hoàn tiền, báo cáo doanh thu ròng',
                      icon: Icons.account_balance_outlined,
                      color: Colors.green,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const FinancialScreen()),
                      ),
                    ),
                    _buildMenuTile(
                      title: 'Quản Lý Nhân Viên Hỗ Trợ',
                      subtitle: 'Tạo tài khoản support mới, xem nhật ký hành động',
                      icon: Icons.support_agent_outlined,
                      color: Colors.indigo,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SupportAccountsScreen()),
                      ),
                    ),
                    _buildMenuTile(
                      title: 'Marketing & Phát Thông Báo',
                      subtitle: 'Tạo mã voucher giảm giá, gửi thông báo đẩy hàng loạt',
                      icon: Icons.campaign_outlined,
                      color: Colors.pink,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const MarketingScreen()),
                      ),
                    ),
                    _buildMenuTile(
                      title: 'Quản Lý & Khóa Người Dùng',
                      subtitle: 'Quản lý tài khoản toàn hệ thống, đình chỉ tài khoản',
                      icon: Icons.no_accounts_outlined,
                      color: Colors.red,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.outfit(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
