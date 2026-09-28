import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/run_mutation.dart';
import '../stocks/stock_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';
  static const _colors = [
    Color(0xFF229CFF),
    Color(0xFFFF843C),
    Color(0xFFFFC336),
    Color(0xFF24AF77),
    Color(0xFFA45CFA),
    Color(0xFF35ADFF),
  ];
  static const _icons = [
    Icons.local_drink_outlined,
    Icons.fastfood_outlined,
    Icons.cookie_outlined,
    Icons.shopping_bag_outlined,
    Icons.sanitizer_outlined,
    Icons.home_outlined,
  ];

  Future<void> _addCategory() async {
    String name = '';
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => name = value,
            decoration: InputDecoration(
              labelText: 'Category name',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final added = await runMutation(
                  context,
                  () => context.read<InventoryCubit>().addCategory(name),
                );
                if (!context.mounted) return;
                if (added == true) {
                  Navigator.pop(context);
                } else {
                  update(() => error = 'Enter a new, unique category name');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = InventoryBuilder(
      builder: (context, _) {
        final store = context.read<InventoryCubit>();
        final categories = store.categories
            .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return ListView(
          padding: AppSizes.screenPadding,
          children: [
            if (widget.embedded)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add category',
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                  ),
                ],
              ),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search category...',
                prefixIcon: Icon(Icons.search, size: 21),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSizes.xl),
                child: Center(child: Text('No categories found')),
              ),
            ...categories.map((category) {
              final index = store.categories.indexOf(category) % _colors.length;
              final count = store.products
                  .where((p) => p.category == category)
                  .length;
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSizes.xs,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _colors[index].withValues(alpha: .72),
                          _colors[index],
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_icons[index], color: Colors.white, size: 25),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '$count products',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 19,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockScreen(category: category),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(
              title: const Text('Categories'),
              actions: [
                IconButton(
                  tooltip: 'Add category',
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                ),
              ],
            ),
            body: body,
          );
  }
}
