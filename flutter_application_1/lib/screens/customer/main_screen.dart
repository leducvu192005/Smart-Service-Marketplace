import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const BookingsScreen(),
    const ChatListScreen(isWorker: false),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 28),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F0EA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_outlined),
            _buildNavItem(1, Icons.grid_view),
            _buildNavItem(2, Icons.message_outlined),
            _buildNavItem(3, Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7555CF) : const Color(0xFFEAEAEA),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7555CF).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF1E293B),
          size: 24,
        ),
      ),
    );
  }
}
