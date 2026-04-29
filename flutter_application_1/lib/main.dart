import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/main_screen.dart';

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
            if (auth.role == 'worker') return const WorkerHomePlaceholder();
            if (auth.role == 'admin' || auth.role == 'support') return const AdminHomePlaceholder();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class WorkerHomePlaceholder extends StatelessWidget {
  const WorkerHomePlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Home')),
      body: const Center(child: Text('Worker Home')),
    );
  }
}

class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin/Support Home')),
      body: const Center(child: Text('Admin Home')),
    );
  }
}
