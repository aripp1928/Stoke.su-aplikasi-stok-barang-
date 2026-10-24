import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../state/item_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemState = context.watch<ItemState>();
    final allItems = itemState.allItems;

    final lowStockNotifs = allItems.where((i) => i.isLowStock || i.isEmpty).map((i) {
      return {
        'title': i.name,
        'subtitle': 'Tersisa ${Formatters.number(i.currentStock)} ${i.unit} · minimum ${Formatters.number(i.minStock)} ${i.unit}',
        'status': i.stockStatusLabel,
        'isDanger': i.isEmpty,
        'isWarning': i.isLowStock,
        'icon': Icons.inventory_2_outlined,
      };
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(
        title: 'Notifikasi',
        subtitle: 'Peringatan stok',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBE6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF2E1E19),
                unselectedLabelColor: const Color(0xFF8D7B75),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'Semua (${lowStockNotifs.length})'),
                  Tab(text: 'Stok Menipis (${lowStockNotifs.length})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(lowStockNotifs),
                _buildList(lowStockNotifs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.notifications_none_outlined,
          title: 'Tidak ada notifikasi',
          message: 'Semua stok bahan dalam kondisi aman dan tidak ada peringatan aktif.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final notif = list[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E3DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F2EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(notif['icon'] as IconData, size: 16, color: const Color(0xFF8D7B75)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E1E19),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif['subtitle'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                    ),
                  ],
                ),
              ),
              StatusBadge.custom(
                notif['status'] as String,
                isDanger: notif['isDanger'] as bool? ?? false,
                isWarning: notif['isWarning'] as bool? ?? false,
              ),
            ],
          ),
        );
      },
    );
  }
}
