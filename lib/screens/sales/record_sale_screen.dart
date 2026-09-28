import '../../widgets/inventory_builder.dart';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/run_mutation.dart';
import 'sale_details_screen.dart';

class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key, this.initialProductId});
  final String? initialProductId;
  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  final _form = GlobalKey<FormState>();
  late final DateTime _date;
  String? _productId;
  String _name = '', _address = '', _phone = '';
  int _quantity = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    final product = context.read<InventoryCubit>().product(
      widget.initialProductId ?? '',
    );
    if (product != null && product.quantity > 0) _productId = product.id;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() => _saving = true);
    final sale = await runMutation(
      context,
      () => context.read<InventoryCubit>().recordSale(
        _productId!,
        _quantity,
        customerName: _name,
        address: _address,
        phone: _phone,
        date: _date,
      ),
    );
    if (!mounted) return;
    if (sale == null) {
      setState(() => _saving = false);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale)),
    );
  }

  Widget _customerField({
    required String label,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.phone
          ? TextCapitalization.none
          : TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter $label';
        if (keyboardType == TextInputType.phone) {
          final digits = value.replaceAll(RegExp(r'\D'), '');
          if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(value.trim()) ||
              digits.length < 7 ||
              digits.length > 15) {
            return 'Enter a valid phone number';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryCubit>();
    final products = store.products.where((p) => p.quantity > 0).toList();
    final selected = _productId == null ? null : store.product(_productId!);
    final dateText =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale')),
      body: InventoryBuilder(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New receipt',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Receipt number assigned automatically',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Customer details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _customerField(
                  label: 'Customer name',
                  icon: Icons.person_outline,
                  onSaved: (v) => _name = v!.trim(),
                ),
                _customerField(
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  onSaved: (v) => _address = v!.trim(),
                  keyboardType: TextInputType.streetAddress,
                ),
                _customerField(
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  onSaved: (v) => _phone = v!.trim(),
                  keyboardType: TextInputType.phone,
                ),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sale date (automatic)',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                  child: Text(dateText),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sale details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: products.any((p) => p.id == _productId)
                      ? _productId
                      : null,
                  key: ValueKey(
                    products.any((p) => p.id == _productId) ? _productId : null,
                  ),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                  ),
                  items: products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.quantity} available)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(() => _productId = id),
                  validator: (id) => id == null ? 'Select a product' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers, size: 20),
                  ),
                  onChanged: (value) => setState(
                    () => _quantity = int.tryParse(value.trim()) ?? 0,
                  ),
                  validator: (value) {
                    final count = int.tryParse(value?.trim() ?? '');
                    if (count == null || count <= 0) {
                      return 'Enter a positive whole number';
                    }
                    if (selected != null && count > selected.quantity) {
                      return 'Not enough stock available';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: Ns ${((selected?.price ?? 0) * (_quantity > 0 ? _quantity : 0)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: products.isEmpty || _saving ? null : _save,
                  child: const Text('Save Sale'),
                ),
                const SizedBox(height: 10),
                Text(
                  products.isEmpty
                      ? 'Add stock before recording a sale.'
                      : 'Saving updates stock and creates your receipt.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
