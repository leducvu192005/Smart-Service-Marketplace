import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = switch (status) {
      'pending' => _BadgeStyle('Chờ xử lý', const Color(0xFFF59E0B)),
      'accepted' => _BadgeStyle('Đã nhận', const Color(0xFF2563EB)),
      'in_progress' => _BadgeStyle('Đang làm', const Color(0xFF7C3AED)),
      'done' => _BadgeStyle('Hoàn thành', const Color(0xFF059669)),
      'cancelled' => _BadgeStyle('Đã hủy', const Color(0xFFDC2626)),
      'approved' => _BadgeStyle('Đã duyệt', const Color(0xFF059669)),
      'rejected' => _BadgeStyle('Từ chối', const Color(0xFFDC2626)),
      'in_progress_ticket' => _BadgeStyle(
        'Đang xử lý',
        const Color(0xFF2563EB),
      ),
      'closed' => _BadgeStyle('Đã đóng', const Color(0xFF059669)),
      _ => _BadgeStyle(status, const Color(0xFF667085)),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: style.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.color.withOpacity(0.16)),
        ),
        child: Text(
          style.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: style.color,
          ),
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final String label;
  final Color color;

  const _BadgeStyle(this.label, this.color);
}
