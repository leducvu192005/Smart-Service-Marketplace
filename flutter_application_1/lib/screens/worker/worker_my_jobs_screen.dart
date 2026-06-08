import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import 'current_job_screen.dart';

class WorkerMyJobsScreen extends StatefulWidget {
  const WorkerMyJobsScreen({super.key});

  @override
  State<WorkerMyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends State<WorkerMyJobsScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _myJobs = [];
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  Future<void> _fetchMyJobs() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // 1. Fetch services
      final servicesResponse = await _apiService.client.get('/customer/services');
      final List<Service> loadedServices = (servicesResponse.data as List)
          .map((i) => Service.fromJson(i))
          .toList();

      // 2. Fetch my jobs
      final response = await _apiService.client.get('/worker/jobs/my');
      
      if (mounted) {
        setState(() {
          _services = loadedServices;
          _myJobs = (response.data as List).map((i) => Booking.fromJson(i)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeJobs = _myJobs.where((job) => 
        job.status == 'accepted' || 
        job.status == 'in_progress' ||
        job.status == 'on_the_way' ||
        job.status == 'arrived'
    ).toList();

    final historyJobs = _myJobs.where((job) => 
        job.status == 'done' || 
        job.status == 'cancelled' ||
        job.status == 'reviewed'
    ).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: Text(
            'Công việc của tôi',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B)),
          ),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
              onPressed: _fetchMyJobs,
            )
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF4F46E5),
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Đang làm'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _fetchMyJobs,
                    color: const Color(0xFF4F46E5),
                    child: activeJobs.isEmpty
                        ? _buildEmptyState('Chưa nhận công việc nào', 'Hãy vào trang Tổng quan để tìm việc mới nhé!')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: activeJobs.length,
                            itemBuilder: (context, index) => _buildJobCard(activeJobs[index]),
                          ),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchMyJobs,
                    color: const Color(0xFF4F46E5),
                    child: historyJobs.isEmpty
                        ? _buildEmptyState('Chưa có lịch sử công việc', 'Các công việc hoàn thành sẽ hiển thị tại đây.')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: historyJobs.length,
                            itemBuilder: (context, index) => _buildJobCard(historyJobs[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildJobCard(Booking job) {
    // Find matching service
    final service = _services.firstWhere(
      (s) => s.id == job.serviceId,
      orElse: () => Service(id: -1, name: "Dịch vụ tiện ích", price: 0.0),
    );

    Color statusColor;
    String statusText;

    switch (job.status) {
      case 'accepted':
        statusColor = const Color(0xFF3B82F6);
        statusText = 'Đã nhận';
        break;
      case 'on_the_way':
        statusColor = const Color(0xFF8B5CF6);
        statusText = 'Đang di chuyển';
        break;
      case 'arrived':
        statusColor = const Color(0xFF06B6D4);
        statusText = 'Đã đến';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Đang làm';
        break;
      case 'done':
        statusColor = const Color(0xFF10B981);
        statusText = 'Hoàn thành';
        break;
      case 'reviewed':
        statusColor = const Color(0xFF10B981);
        statusText = 'Đã đánh giá';
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusText = job.status.toUpperCase();
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(job, service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID and Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đơn hàng #${job.id}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Service Name
                Text(
                  service.name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Divider
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 16),

                // Info Rows
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(job.scheduledTime),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price & Detail Navigation Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành tiền',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '${service.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}đ',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateToDetail(job, service),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        'Xem chi tiết',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(Booking job, Service service) async {
    final jobMap = {
      "booking_id": job.id,
      "service_name": service.name,
      "address": job.address,
      "scheduled_time": job.scheduledTime,
      "price": service.price,
      "status": job.status,
      "note": job.note,
      "before_image": job.beforeImage,
      "after_image": job.afterImage,
    };

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrentJobScreen(initialJob: jobMap),
      ),
    );

    _fetchMyJobs();
  }
}
