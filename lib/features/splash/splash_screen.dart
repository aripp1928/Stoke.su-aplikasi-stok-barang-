import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/router/route_names.dart';
import '../../state/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStart();
  }

  Future<void> _handleStart() async {
    try {
      final authState = context.read<AuthState>();
      await authState.initialize();
    } catch (e) {
      debugPrint('[Splash] Init fallback: $e');
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    try {
      final authState = context.read<AuthState>();
      if (authState.isAuthenticated) {
        context.goNamed(RouteNames.dashboard);
      } else {
        context.goNamed(RouteNames.login);
      }
    } catch (_) {
      context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD8C7B8), width: 1.2),
                ),
                child: const Icon(
                  Icons.local_cafe_outlined,
                  size: 32,
                  color: Color(0xFF6E5649),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SETOKE.SU',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.0,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stok tertata,\nKopi tetap istimewa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7D6B63),
              ),
            ),
            const Spacer(flex: 4),
            const Text(
              'SISTEM STOK WARUNG KOPI',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                color: Color(0xFFAFA49D),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
