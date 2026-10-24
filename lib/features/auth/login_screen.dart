import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/router/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authState = context.read<AuthState>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty && password.isEmpty) {
      setState(() => _errorMessage = 'Email dan password wajib diisi');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Alamat email wajib diisi');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Format email tidak valid (cth: nama@email.com)');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password wajib diisi');
      return;
    }

    setState(() => _errorMessage = null);
    final success = await authState.signIn(email, password);
    if (!mounted) return;

    if (success) {
      context.goNamed(RouteNames.dashboard);
    } else {
      setState(() {
        _errorMessage = authState.error ?? 'Email atau password salah, atau akun belum terdaftar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Logo & Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD8C7B8), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.local_cafe_outlined,
                        size: 16,
                        color: Color(0xFF6E5649),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SETOKE.SU',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        fontFamily: 'serif',
                        color: Color(0xFF2E1E19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Headings
                const Text(
                  'Kembali ke kedai.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: Color(0xFF2E1E19),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kelola persediaan, satu cangkir lebih tenang.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7D6B63),
                  ),
                ),
                const SizedBox(height: 32),
                // Form Fields
                AppTextField(
                  label: 'Email',
                  hint: 'nama@kedai.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  suffix: const Icon(Icons.mail_outline, size: 18, color: Color(0xFFA89F99)),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Masukkan password Anda',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: const Color(0xFFA89F99),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (_errorMessage != null || authState.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage ?? authState.error ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Masuk',
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.pushNamed(RouteNames.register),
                    child: const Text(
                      'Belum punya akun? Daftar toko baru',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4E48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
