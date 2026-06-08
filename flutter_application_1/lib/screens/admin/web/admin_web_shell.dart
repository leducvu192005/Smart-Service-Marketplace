import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import 'pages/booking_dispatch_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/financial_page.dart';
import 'pages/marketing_page.dart';
import 'pages/service_management_page.dart';
import 'pages/support_accounts_page.dart';
import 'pages/ticket_management_page.dart';
import 'pages/user_management_page.dart';
import 'pages/worker_verification_page.dart';

class AdminWebShell extends StatefulWidget {
  const AdminWebShell({super.key});

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  List<_NavItem> _navItems(bool isAdmin) {
    final supportItems = [
      _NavItem(
        icon: Icons.space_dashboard_rounded,
        label: 'Tổng quan',
        description: 'Bảng điều hành trong ngày',
        page: DashboardPage(isAdmin: isAdmin),
      ),
      const _NavItem(
        icon: Icons.verified_user_rounded,
        label: 'Duyệt hồ sơ thợ',
        description: 'Kiểm tra và kích hoạt thợ mới',
        page: WorkerVerificationPage(),
      ),
      const _NavItem(
        icon: Icons.alt_route_rounded,
        label: 'Điều phối đơn',
        description: 'Đổi thợ, đổi giờ, xác nhận thanh toán',
        page: BookingDispatchPage(),
      ),
      const _NavItem(
        icon: Icons.support_agent_rounded,
        label: 'Tickets hỗ trợ',
        description: 'Tiếp nhận và xử lý khiếu nại',
        page: TicketManagementPage(),
      ),
    ];

    if (!isAdmin) return supportItems;

    return [
      ...supportItems,
      const _NavItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Tài chính',
        description: 'Rút tiền, hoàn tiền, doanh thu',
        page: FinancialPage(),
      ),
      const _NavItem(
        icon: Icons.room_service_rounded,
        label: 'Dịch vụ & biểu giá',
        description: 'Danh mục, dịch vụ và phí nền tảng',
        page: ServiceManagementPage(),
      ),
      const _NavItem(
        icon: Icons.badge_rounded,
        label: 'Nhân sự support',
        description: 'Tài khoản hỗ trợ và nhật ký',
        page: SupportAccountsPage(),
      ),
      const _NavItem(
        icon: Icons.campaign_rounded,
        label: 'Marketing',
        description: 'Voucher và thông báo đẩy',
        page: MarketingPage(),
      ),
      const _NavItem(
        icon: Icons.manage_accounts_rounded,
        label: 'Người dùng',
        description: 'Khóa tài khoản và blacklist',
        page: UserManagementPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.role == 'admin';
    final items = _navItems(isAdmin);
    final userName =
        (auth.user?['full_name'] ??
                (isAdmin ? 'Quản trị viên' : 'Nhân viên support'))
            .toString();

    if (_selectedIndex >= items.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: _sidebarCollapsed ? 78 : 286,
            child: _Sidebar(
              collapsed: _sidebarCollapsed,
              isAdmin: isAdmin,
              items: items,
              selectedIndex: _selectedIndex,
              userName: userName,
              onSelect: (index) => setState(() => _selectedIndex = index),
              onToggle: () =>
                  setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              onLogout: auth.logout,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  item: items[_selectedIndex],
                  isAdmin: isAdmin,
                  userName: userName,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: items.map((item) => item.page).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool collapsed;
  final bool isAdmin;
  final List<_NavItem> items;
  final int selectedIndex;
  final String userName;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.collapsed,
    required this.isAdmin,
    required this.items,
    required this.selectedIndex,
    required this.userName,
    required this.onSelect,
    required this.onToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101828),
      child: Column(
        children: [
          SizedBox(
            height: 78,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Service',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isAdmin ? 'Admin console' : 'Support desk',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF98A2B3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  IconButton(
                    tooltip: collapsed ? 'Mở menu' : 'Thu gọn menu',
                    onPressed: onToggle,
                    icon: Icon(
                      collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1D2939)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final showAdminDivider = isAdmin && index == 4 && !collapsed;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAdminDivider)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                        child: Text(
                          'QUẢN TRỊ HỆ THỐNG',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    _NavTile(
                      item: items[index],
                      selected: selectedIndex == index,
                      collapsed: collapsed,
                      onTap: () => onSelect(index),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1D2939)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isAdmin
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF14B8A6),
                  child: Text(
                    userName.isNotEmpty
                        ? userName.substring(0, 1).toUpperCase()
                        : 'S',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isAdmin ? 'Super Admin' : 'Support Operator',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF98A2B3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF98A2B3),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D2939) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: const Color(0xFF344054)) : null,
      ),
      child: ListTile(
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
        contentPadding: EdgeInsets.symmetric(
          horizontal: collapsed ? 14 : 12,
          vertical: 4,
        ),
        leading: Icon(
          item.icon,
          color: selected ? Colors.white : const Color(0xFF98A2B3),
          size: 21,
        ),
        title: collapsed
            ? null
            : Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: selected ? Colors.white : const Color(0xFFD0D5DD),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
        onTap: onTap,
        hoverColor: const Color(0xFF1D2939),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (!collapsed) return content;

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: content,
    );
  }
}

class _TopBar extends StatelessWidget {
  final _NavItem item;
  final bool isAdmin;
  final String userName;

  const _TopBar({
    required this.item,
    required this.isAdmin,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = isAdmin
        ? const Color(0xFF2563EB)
        : const Color(0xFF0F766E);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF101828),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF667085),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: roleColor.withOpacity(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.headset_mic_rounded,
                  size: 16,
                  color: roleColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isAdmin ? 'ADMIN' : 'SUPPORT',
                  style: GoogleFonts.outfit(
                    color: roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFF2F4F7),
            child: Text(
              userName.isNotEmpty
                  ? userName.substring(0, 1).toUpperCase()
                  : 'S',
              style: GoogleFonts.outfit(
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String description;
  final Widget page;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.page,
  });
}
