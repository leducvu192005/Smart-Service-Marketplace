import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final ApiService _apiService = ApiService();

  final _voucherFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();

  final _notifyFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _recipientRole = 'all';

  Future<void> _createVoucher() async {
    if (!_voucherFormKey.currentState!.validate()) return;
    
    try {
      await _apiService.client.post(
        '/admin/vouchers',
        data: {
          'code': _codeController.text.trim().toUpperCase(),
          'discount_amount': double.tryParse(_discountController.text) ?? 0.0,
          'expiry_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo mã giảm giá thành công!')),
      );
      _codeController.clear();
      _discountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo mã giảm giá: $e')),
      );
    }
  }

  Future<void> _broadcastNotification() async {
    if (!_notifyFormKey.currentState!.validate()) return;
    
    try {
      await _apiService.client.post(
        '/admin/notifications',
        data: {
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'recipient_role': _recipientRole,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã phát thông báo đẩy thành công!')),
      );
      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phát thông báo: $e')),
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
          title: Text('Marketing & Khuyến Mãi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.confirmation_num_outlined), text: 'Mã Giảm Giá'),
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Phát Thông Báo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVouchersTab(),
            _buildNotificationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _voucherFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tạo Mã Khuyến Mãi (Voucher)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Mã giảm giá sẽ có hiệu lực 30 ngày tính từ thời điểm tạo.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Mã giảm giá (Ví dụ: SALE50)',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Nhập mã giảm giá' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền giảm (USD)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (val) => val == null || double.tryParse(val) == null ? 'Vui lòng nhập số tiền hợp lệ' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createVoucher,
              child: const Text('Tạo Mã Khuyến Mãi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _notifyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Phát Thông Báo Hệ Thống', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Thông báo sẽ được gửi tới nhóm người dùng được lựa chọn trên ứng dụng.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề thông báo',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nội dung chi tiết thông báo',
                prefixIcon: Icon(Icons.message),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recipientRole,
              decoration: const InputDecoration(
                labelText: 'Đối tượng nhận tin',
                prefixIcon: Icon(Icons.people_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả người dùng')),
                DropdownMenuItem(value: 'customer', child: Text('Khách hàng')),
                DropdownMenuItem(value: 'worker', child: Text('Nhân viên Thợ')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _recipientRole = val);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _broadcastNotification,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Phát Thông Báo Ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
