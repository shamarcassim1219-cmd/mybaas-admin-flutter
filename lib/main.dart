import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_shell.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOBAAS Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _StartupGate(),
    );
  }
}

/// Checks for an existing admin session and picks LoginScreen or
/// HomeShell accordingly.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _loggedIn ? const HomeShell() : const LoginScreen();
  }
}
