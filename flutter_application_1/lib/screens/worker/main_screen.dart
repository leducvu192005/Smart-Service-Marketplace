import 'package:flutter/material.dart';
import 'home.dart';
import 'jobs_screen.dart';
import 'worker_my_jobs_screen.dart';
import 'profile_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const WorkerHomeScreen(),
    const WorkerJobsScreen(),
    const WorkerMyJobsScreen(),
    const WorkerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type:
            BottomNavigationBarType.fixed, // Ensure it looks good with 4 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.manage_search),
            label: 'Tìm việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Việc của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
