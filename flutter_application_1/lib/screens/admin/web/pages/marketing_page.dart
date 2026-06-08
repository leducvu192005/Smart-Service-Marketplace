import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class MarketingPage extends StatefulWidget {
  const MarketingPage({super.key});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  final ApiService _api = ApiService();
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController(text: '100');
  List<dynamic> _vouchers = [];
  DateTime? _expiryDate;
  bool _isPercent = true;
  bool _creating = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/admin/vouchers');
      if (mounted)
        setState(() {
          _vouchers = res.data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createVoucher() async {
    if (_codeCtrl.text.trim().isEmpty || _discountCtrl.text.trim().isEmpty) {
      _snack('Vui lòng điền đầy đủ thông tin!', Colors.orange);
      return;
    }
    setState(() => _creating = true);
    try {
      await _api.client.post(
        '/admin/vouchers',
        data: {
          'code': _codeCtrl.text.trim().toUpperCase(),
          'discount_value': double.tryParse(_discountCtrl.text) ?? 0.0,
          'discount_type': _isPercent ? 'percentage' : 'fixed',
          'max_uses': int.tryParse(_maxUsesCtrl.text) ?? 100,
          'expiry_date': _expiryDate?.toIso8601String(),
        },
      );
      _snack(
        '✅ Tạo voucher "${_codeCtrl.text.trim().toUpperCase()}" thành công!',
        Colors.green,
      );
      _codeCtrl.clear();
      _discountCtrl.clear();
      _expiryDate = null;
      _load();
    } catch (e) {
      _snack('Lỗi: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteVoucher(int id) async {
    try {
      await _api.client.delete('/admin/vouchers/$id');
      _snack('Đã xóa voucher.', Colors.orange);
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
          // Create Voucher Form
          SizedBox(
            width: 380,
            child: WebCard(
              title: 'Tạo Voucher Khuyến Mãi',
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code field
                    TextFormField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã Voucher (VD: SUMMER30)',
                        prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Discount type toggle
                    Text(
                      'Loại giảm giá',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPercent = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isPercent
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '% Phần Trăm',
                                  style: GoogleFonts.outfit(
                                    color: _isPercent
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: _isPercent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPercent = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isPercent
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '\$ Số Tiền Cố Định',
                                  style: GoogleFonts.outfit(
                                    color: !_isPercent
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: !_isPercent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Discount value
                    TextFormField(
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: _isPercent
                            ? 'Giá Trị Giảm (%)'
                            : 'Số Tiền Giảm (\$)',
                        prefixIcon: Icon(
                          _isPercent ? Icons.percent : Icons.attach_money,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max uses
                    TextFormField(
                      controller: _maxUsesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số Lần Sử Dụng Tối Đa',
                        prefixIcon: Icon(Icons.group_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Expiry date
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) setState(() => _expiryDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _expiryDate == null
                                  ? 'Ngày hết hạn (tuỳ chọn)'
                                  : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: _expiryDate == null
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            if (_expiryDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _expiryDate = null),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preview
                    if (_codeCtrl.text.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'XEM TRƯỚC VOUCHER',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _codeCtrl.text.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Giảm ${_discountCtrl.text.isEmpty ? "0" : _discountCtrl.text}${_isPercent ? "%" : "\$"}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                            : const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(
                          _creating ? 'Đang tạo...' : 'Tạo Voucher',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _creating ? null : _createVoucher,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Vouchers list
          Expanded(
            child: WebCard(
              title: 'Danh Sách Voucher',
              badge: '${_vouchers.length}',
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
                  : _vouchers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.discount_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có voucher nào',
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _vouchers
                            .map(
                              (v) => _VoucherCard(
                                v: v,
                                onDelete: () => _deleteVoucher(v['id']),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Map<String, dynamic> v;
  final VoidCallback onDelete;

  const _VoucherCard({required this.v, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPercent = v['discount_type'] == 'percentage';
    final expiryStr = v['expiry_date'] != null
        ? (() {
            try {
              final d = DateTime.parse(v['expiry_date']).toLocal();
              return '${d.day}/${d.month}/${d.year}';
            } catch (_) {
              return '';
            }
          })()
        : 'Không giới hạn';
    final isExpired =
        v['expiry_date'] != null &&
        DateTime.tryParse(v['expiry_date'])?.isBefore(DateTime.now()) == true;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpired
              ? Colors.grey.shade200
              : const Color(0xFF4F46E5).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Top gradient
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isExpired
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    v['code'] ?? 'CODE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPercent ? "-" : "-\$"}${v['discount_value']}${isPercent ? "%" : ""}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${v['used_count'] ?? 0}/${v['max_uses'] ?? "∞"}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hết hạn',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      expiryStr,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? Colors.red : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Xóa voucher',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
