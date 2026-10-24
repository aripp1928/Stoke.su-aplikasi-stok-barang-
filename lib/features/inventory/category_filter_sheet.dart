import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../state/item_state.dart';

class CategoryFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelect;

  const CategoryFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentCategory,
    required ValueChanged<String> onSelect,
  }) {
    return BottomSheetWrapper.show(
      context: context,
      title: 'Filter kategori',
      subtitle: 'Pilih kategori bahan yang ingin ditampilkan.',
      child: CategoryFilterSheet(
        selectedCategory: currentCategory,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final itemState = context.watch<ItemState>();
    final allItems = itemState.allItems;

    final categoriesList = <Map<String, dynamic>>[
      {
        'name': 'Semua kategori',
        'count': '${allItems.length} barang',
      },
    ];

    final categorySet = allItems.map((i) => i.category).toSet().toList()..sort();
    for (final cat in categorySet) {
      final count = allItems.where((i) => i.category == cat).length;
      categoriesList.add({
        'name': cat,
        'count': '$count barang',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...categoriesList.map((cat) {
          final isSelected = _current == cat['name'];
          return InkWell(
            onTap: () => setState(() => _current = cat['name'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 20,
                    color: isSelected ? const Color(0xFF38241D) : const Color(0xFFD6CDC4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFF2E1E19),
                          ),
                        ),
                        Text(
                          cat['count'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Reset',
                isOutlined: true,
                onPressed: () {
                  widget.onSelect('Semua kategori');
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                text: 'Terapkan filter',
                onPressed: () {
                  widget.onSelect(_current);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
