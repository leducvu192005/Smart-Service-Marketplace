import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class WorkerVerificationScreen extends StatefulWidget {
  const WorkerVerificationScreen({super.key});

  @override
  State<WorkerVerificationScreen> createState() => _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _pendingWorkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingWorkers();
  }

  Future<void> _fetchPendingWorkers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/support/workers/pending');
      setState(() {
        _pendingWorkers = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách thợ: $e')),
      );
    }
  }

  Future<void> _approveWorker(int workerId) async {
    try {
      await _apiService.client.post('/support/workers/$workerId/approve');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã phê duyệt tài khoản thợ thành công!')),
      );
      _fetchPendingWorkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phê duyệt: $e')),
      );
    }
  }

  Future<void> _rejectWorker(int workerId) async {
    try {
      await _apiService.client.post('/support/workers/$workerId/reject');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối tài khoản thợ.')),
      );
      _fetchPendingWorkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi từ chối: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Duyệt Hồ Sơ Thợ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingWorkers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Không có hồ sơ nào chờ duyệt',
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = _pendingWorkers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(worker['avatar_url'] ?? 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=150'),
                        ),
                        title: Text(
                          worker['full_name'] ?? 'Chưa cập nhật tên',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(
                          worker['job_title'] ?? 'Thợ tự do',
                          style: GoogleFonts.outfit(color: theme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                _buildDetailRow('Email:', worker['email'] ?? 'Không có'),
                                _buildDetailRow('Số điện thoại:', worker['phone'] ?? 'Không có'),
                                _buildDetailRow('Địa chỉ:', '${worker['address'] ?? ''}, ${worker['district'] ?? ''}, ${worker['city'] ?? ''}'),
                                _buildDetailRow('Kinh nghiệm:', '${worker['experience_years'] ?? 0} năm'),
                                _buildDetailRow('Kỹ năng:', worker['skills'] ?? 'Chưa thiết lập'),
                                _buildDetailRow('Mô tả:', worker['description'] ?? 'Không có'),
                                _buildDetailRow('Số CCCD/CMND:', worker['identity_number'] ?? 'Không có'),
                                const SizedBox(height: 12),
                                Text(
                                  'Ảnh CCCD (Mặt trước / Mặt sau):',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildIdentityImage(worker['identity_front_image'], 'Mặt trước'),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildIdentityImage(worker['identity_back_image'], 'Mặt sau'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Thông tin ngân hàng:',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ngân hàng: ${worker['bank_name'] ?? "Chưa liên kết"} | STK: ${worker['bank_account_number'] ?? "Chưa liên kết"}\nChủ tài khoản: ${worker['bank_account_holder'] ?? "Chưa liên kết"}',
                                  style: GoogleFonts.outfit(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Từ Chối'),
                                        onPressed: () => _rejectWorker(worker['id']),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Phê Duyệt'),
                                        onPressed: () => _approveWorker(worker['id']),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityImage(String? url, String label) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: url != null && url.startsWith('http')
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ),
    );
  }
}
