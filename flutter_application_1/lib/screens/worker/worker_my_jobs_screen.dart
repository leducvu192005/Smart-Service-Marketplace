import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

class WorkerMyJobsScreen extends StatefulWidget {
  const WorkerMyJobsScreen({super.key});

  @override
  State<WorkerMyJobsScreen> createState() => _WorkerMyJobsScreenState();
}

class _WorkerMyJobsScreenState extends State<WorkerMyJobsScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _myJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  Future<void> _fetchMyJobs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.client.get('/worker/jobs/my');
      setState(() {
        _myJobs = (response.data as List).map((i) => Booking.fromJson(i)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    try {
      await _apiService.client.put(
        '/worker/jobs/$bookingId/status',
        queryParameters: {'status_update': newStatus},
      );
      _fetchMyJobs(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công!'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Công việc của tôi')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchMyJobs,
            child: _myJobs.isEmpty
              ? ListView(children: const [SizedBox(height: 100), Center(child: Text('Bạn chưa nhận công việc nào.'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myJobs.length,
                  itemBuilder: (context, index) {
                    final job = _myJobs[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Booking #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Chip(label: Text(job.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: job.status == 'accepted' ? Colors.blue : Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [const Icon(Icons.access_time, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(job.scheduledTime.replaceFirst('T', ' ').substring(0, 16), style: const TextStyle(fontSize: 15))]),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.location_on, size: 20, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(job.address, style: const TextStyle(fontSize: 15)))]),
                            const SizedBox(height: 24),
                            if (job.status == 'accepted')
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(job.id, 'in_progress'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: const Text('Bắt đầu làm (In Progress)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                ),
                              )
                            else if (job.status == 'in_progress')
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(job.id, 'done'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: const Text('Hoàn thành (Done)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                ),
                              )
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
