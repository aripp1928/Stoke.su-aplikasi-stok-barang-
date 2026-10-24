import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../state/auth_state.dart';
import '../../state/item_state.dart';
import '../constants/app_sizes.dart';

/// Header halaman. Di tab utama menampilkan nama kedai + lonceng + profil;
/// di halaman lanjutan (showBack) hanya tombol kembali + judul.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final bool showActions;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.showActions = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  void _goBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final alertCount = context.select<ItemState, int>(
      (s) => s.lowStockCount + s.emptyStockCount,
    );
    final storeName = authState.storeName.isNotEmpty ? authState.storeName : 'SETOKE.SU';
    final userName = authState.userName.isNotEmpty ? authState.userName : 'User';
    final initial = userName[0].toUpperCase();
    final withActions = showActions && !showBack;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH, 8, AppSizes.screenPaddingH, 8),
        child: Row(
          children: [
            if (showBack) ...[
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _goBack(context),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (subtitle ?? 'SETOKE.SU').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title ?? storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (withActions) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _RoundIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.pushNamed(RouteNames.notifications),
                  ),
                  if (alertCount > 0)
                    Positioned(
                      top: 7,
                      right: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.profile),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
