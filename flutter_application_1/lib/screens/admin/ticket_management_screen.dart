import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class TicketManagementScreen extends StatefulWidget {
  const TicketManagementScreen({super.key});

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.client.get('/support/tickets');
      setState(() {
        _tickets = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải ticket: $e')));
    }
  }

  Future<void> _updateTicketStatus(int ticketId, String newStatus) async {
    try {
      await _apiService.client.put(
        '/support/tickets/$ticketId/status',
        data: {'status': newStatus},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chuyển trạng thái ticket sang: $newStatus')),
      );
      _fetchTickets();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    }
  }

  void _openChatDialog(Map<String, dynamic> ticket) {
    final TextEditingController msgController = TextEditingController();
    List<Map<String, String>> messages = [
      {'sender': 'user', 'text': ticket['description'] ?? ''},
      {
        'sender': 'support',
        'text':
            'Chào bạn, chúng tôi đã nhận được thông tin khiếu nại. Bạn vui lòng chờ trong giây lát để hệ thống kiểm tra nhé.',
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Giải Quyết Khiếu Nại - Đơn #${ticket['booking_id'] ?? ''}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.amber.shade50,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ticket['title'] ?? 'Khiếu nại',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg['sender'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.grey.shade200
                                    : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: msgController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập phản hồi...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.indigo),
                          onPressed: () {
                            if (msgController.text.trim().isNotEmpty) {
                              setDialogState(() {
                                messages.add({
                                  'sender': 'support',
                                  'text': msgController.text.trim(),
                                });
                                msgController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
                if (ticket['status'] != 'closed')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateTicketStatus(ticket['id'], 'closed');
                    },
                    child: const Text('Đóng Ticket'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hỗ Trợ & Khiếu Nại',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có phiếu hỗ trợ nào cần xử lý',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchTickets,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final tk = _tickets[index];
                  final ticketId = tk['id'];
                  final title = tk['title'] ?? 'Khiếu nại';
                  final description = tk['description'] ?? '';
                  final status = tk['status'] ?? 'pending';
                  final bookingId = tk['booking_id'];

                  Color statusColor = Colors.orange;
                  String statusText = 'Đang Chờ';
                  if (status == 'in_progress') {
                    statusColor = Colors.blue;
                    statusText = 'Đang Xử Lý';
                  } else if (status == 'closed') {
                    statusColor = Colors.green;
                    statusText = 'Đã Đóng';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ticket #$ticketId ${bookingId != null ? "(Đơn #$bookingId)" : ""}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'pending')
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Nhận Xử Lý'),
                                  onPressed: () => _updateTicketStatus(
                                    ticketId,
                                    'in_progress',
                                  ),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('Hỗ Trợ Ngay'),
                                onPressed: () => _openChatDialog(tk),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
