import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/main_screen.dart';
import 'screens/worker/main_screen.dart';
import 'screens/admin/admin_main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
      ],
      child: const SmartServiceApp(),
    ),
  );
}

class SmartServiceApp extends StatelessWidget {
  const SmartServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Service',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            // Routing based on role
            if (auth.role == 'customer') return const CustomerMainScreen();
            if (auth.role == 'worker') return const WorkerMainScreen();
            if (auth.role == 'admin' || auth.role == 'support') return const AdminMainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
