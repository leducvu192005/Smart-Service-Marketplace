import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

class WorkerJobsScreen extends StatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _pendingJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.client.get('/worker/jobs/pending');
      setState(() {
        _pendingJobs = (response.data as List).map((i) => Booking.fromJson(i)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptJob(int bookingId) async {
    try {
      await _apiService.client.post('/worker/jobs/$bookingId/accept');
      _fetchJobs(); // Refresh
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nhận việc thành công!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Công việc quanh đây')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchJobs,
            child: _pendingJobs.isEmpty
              ? ListView(children: const [SizedBox(height: 100), Center(child: Text('Hiện chưa có yêu cầu mới. Hãy chắc chắn bạn đang BẬT nhận việc.'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingJobs.length,
                  itemBuilder: (context, index) {
                    final job = _pendingJobs[index];
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
                                Text('Service Task #${job.serviceId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Chip(label: Text(job.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.amber),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [const Icon(Icons.access_time, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(job.scheduledTime.replaceFirst('T', ' ').substring(0, 16), style: const TextStyle(fontSize: 15))]),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.location_on, size: 20, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(job.address, style: const TextStyle(fontSize: 15)))]),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _acceptJob(job.id),
                                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Nhận Viêc Này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
