import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

class SupportContactScreen extends StatefulWidget {
  final String endpoint;
  final String audienceLabel;
  final int? bookingId;

  const SupportContactScreen({
    super.key,
    required this.endpoint,
    required this.audienceLabel,
    this.bookingId,
  });

  @override
  State<SupportContactScreen> createState() => _SupportContactScreenState();
}

class _SupportContactScreenState extends State<SupportContactScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bookingController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingController.text = '${widget.bookingId}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bookingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final bookingIdText = _bookingController.text.trim();
    final bookingId = bookingIdText.isEmpty ? null : int.tryParse(bookingIdText);

    try {
      await _api.client.post(
        widget.endpoint,
        data: {
          'booking_id': bookingId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu đến Support. Nhân viên hỗ trợ sẽ xử lý trong màn Tickets.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi yêu cầu: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Liên hệ Support'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.support_agent_rounded, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gửi phản ánh đến Support',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tất cả thắc mắc, khiếu nại và yêu cầu hỗ trợ của ${widget.audienceLabel} sẽ tạo ticket cho nhân viên Support.',
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF667085)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _FieldLabel('Mã đơn hàng liên quan'),
                TextFormField(
                  controller: _bookingController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    hint: 'Có thể bỏ trống nếu không liên quan đơn hàng',
                    icon: Icons.confirmation_number_outlined,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isNotEmpty && int.tryParse(text) == null) {
                      return 'Mã đơn hàng phải là số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _FieldLabel('Tiêu đề'),
                TextFormField(
                  controller: _titleController,
                  decoration: _decoration(hint: 'Ví dụ: Cần hỗ trợ thanh toán', icon: Icons.subject_rounded),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _FieldLabel('Nội dung phản ánh'),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: _decoration(
                    hint: 'Mô tả chi tiết vấn đề, số điện thoại liên hệ hoặc thông tin cần Support kiểm tra.',
                    icon: Icons.edit_note_rounded,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 10) return 'Vui lòng mô tả ít nhất 10 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? 'Đang gửi...' : 'Gửi đến Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  InputDecoration _decoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD0D5DD))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD0D5DD))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF344054),
        ),
      ),
    );
  }
}
