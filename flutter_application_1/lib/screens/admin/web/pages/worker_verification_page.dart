import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/api_service.dart';
import '../widgets/web_card.dart';

class WorkerVerificationPage extends StatefulWidget {
  const WorkerVerificationPage({super.key});

  @override
  State<WorkerVerificationPage> createState() => _WorkerVerificationPageState();
}

class _WorkerVerificationPageState extends State<WorkerVerificationPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<dynamic> _workers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.client.get('/support/workers/pending');
      if (mounted) {
        setState(() {
          _workers = res.data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await _api.client.post('/support/workers/$id/approve');
      _snack('Đã duyệt hồ sơ thợ.', const Color(0xFF059669));
      _load();
    } catch (e) {
      _snack('Không thể duyệt hồ sơ: $e', const Color(0xFFDC2626));
    }
  }

  Future<void> _reject(int id) async {
    try {
      await _api.client.post('/support/workers/$id/reject');
      _snack('Đã từ chối hồ sơ thợ.', const Color(0xFFF59E0B));
      _load();
    } catch (e) {
      _snack('Không thể từ chối hồ sơ: $e', const Color(0xFFDC2626));
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: WebCard(
        title: 'Hồ sơ thợ chờ duyệt',
        badge: '${_workers.length}',
        badgeColor: const Color(0xFFF59E0B),
        action: IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _load,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _workers.isEmpty
            ? _emptyState()
            : Column(
                children: _workers
                    .map(
                      (worker) => _WorkerCard(
                        worker: worker,
                        onApprove: _approve,
                        onReject: _reject,
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(52),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            'Không có hồ sơ nào đang chờ duyệt',
            style: GoogleFonts.outfit(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatefulWidget {
  final Map<String, dynamic> worker;
  final Future<void> Function(int id) onApprove;
  final Future<void> Function(int id) onReject;

  const _WorkerCard({
    required this.worker,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
    final workerId = worker['id'] as int;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      _initial(worker['full_name']),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: _InfoBlock(
                      title: '${worker['full_name'] ?? 'Chưa cập nhật'}',
                      subtitle: '${worker['job_title'] ?? 'Thợ dịch vụ'}',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _InfoBlock(
                      title: '${worker['phone'] ?? 'Chưa có SĐT'}',
                      subtitle: '${worker['email'] ?? 'Chưa có email'}',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _InfoBlock(
                      title:
                          '${worker['district'] ?? '-'}, ${worker['city'] ?? '-'}',
                      subtitle:
                          '${worker['experience_years'] ?? 0} năm kinh nghiệm',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _InfoBlock(
                      title:
                          '${worker['bank_name'] ?? 'Chưa liên kết ngân hàng'}',
                      subtitle: '${worker['bank_account_number'] ?? ''}',
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => widget.onReject(workerId),
                        icon: const Icon(Icons.close_rounded, size: 17),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => widget.onApprove(workerId),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Thông tin xác minh'),
                        _DetailLine(
                          'CCCD/CMND',
                          '${worker['identity_number'] ?? 'Chưa cung cấp'}',
                        ),
                        _DetailLine(
                          'Chủ tài khoản',
                          '${worker['bank_account_holder'] ?? 'Chưa liên kết'}',
                        ),
                        _DetailLine(
                          'Kỹ năng',
                          '${worker['skills'] ?? 'Chưa cập nhật'}',
                        ),
                        _DetailLine(
                          'Mô tả',
                          '${worker['description'] ?? 'Chưa cập nhật'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 310,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Ảnh giấy tờ'),
                        Row(
                          children: [
                            _DocumentBox(
                              label: 'Mặt trước',
                              url: worker['identity_front_image'],
                            ),
                            const SizedBox(width: 12),
                            _DocumentBox(
                              label: 'Mặt sau',
                              url: worker['identity_back_image'],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _initial(dynamic value) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null'
        ? 'T'
        : text.substring(0, 1).toUpperCase();
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoBlock({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF344054),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF667085),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentBox extends StatelessWidget {
  final String label;
  final dynamic url;

  const _DocumentBox({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = '$url';
    final hasImage = imageUrl.startsWith('http');

    return Container(
      width: 145,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: hasImage
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF667085),
                ),
              ),
            ),
    );
  }
}
