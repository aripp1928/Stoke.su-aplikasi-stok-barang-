import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../state/auth_state.dart';
import '../../app/router/route_names.dart';
import '../../app/router/app_router.dart';

class SignOutSheet extends StatelessWidget {
  const SignOutSheet({super.key});

  static Future<void> show(BuildContext context) {
    final authState = context.read<AuthState>();
    final name = authState.userName.isNotEmpty ? authState.userName : 'Pengguna';
    final email = authState.userEmail.isNotEmpty ? authState.userEmail : '-';

    return BottomSheetWrapper.show(
      context: context,
      title: 'Keluar dari akun?',
      subtitle: '$name · $email',
      child: const SignOutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final storeName = authState.storeName.isNotEmpty ? authState.storeName : 'toko';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Data stok $storeName dan seluruh riwayat yang sudah tersimpan tetap tersedia saat masuk kembali.',
          style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF5D4E48)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pastikan pencatatan selesai',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8A5812)),
              ),
              SizedBox(height: 2),
              Text(
                'Perubahan form yang belum disimpan tidak ikut tersimpan setelah keluar.',
                style: TextStyle(fontSize: 10, color: Color(0xFFA67128)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Batal',
                isOutlined: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                text: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await authState.signOut();
                  AppRouter.router.goNamed(RouteNames.login);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
