import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final String? badge;
  final Color? badgeColor;

  const WebCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? const Color(0xFF4F46E5))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor ?? const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (action != null) action!,
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          child,
        ],
      ),
    );
  }
}
