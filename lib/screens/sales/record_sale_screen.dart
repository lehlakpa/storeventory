import '../../widgets/inventory_builder.dart';

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/run_mutation.dart';
import '../../widgets/reauthenticate_dialog.dart';
import 'sale_details_screen.dart';
import '../../models/sale_ui_model.dart';

class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key, this.initialProductId, this.sale});
  final SaleUiModel? sale;
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
    _date = widget.sale?.date ?? DateTime.now();
    final sale = widget.sale;
    if (sale != null) {
      _productId = sale.productId;
      _name = sale.customerName;
      _address = sale.address;
      _phone = sale.phone;
      _quantity = sale.quantity;
      return;
    }
    final product = context.read<InventoryCubit>().product(
      widget.initialProductId ?? '',
    );
    if (product != null && product.quantity > 0) _productId = product.id;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() => _saving = true);
    if (widget.sale != null) {
      final verified = await confirmSensitiveAction(context);
      if (!mounted) return;
      if (!verified) {
        setState(() => _saving = false);
        return;
      }
    }
    final sale = await runMutation(
      context,
      () => widget.sale != null
          ? context.read<InventoryCubit>().updateSale(
              SaleUiModel(
                id: widget.sale!.id,
                customerName: _name,
                address: _address,
                phone: _phone,
                date: _date,
                productId: widget.sale!.productId,
                productName: widget.sale!.productName,
                imageUrl: widget.sale!.imageUrl,
                unit: widget.sale!.unit,
                quantity: _quantity,
                unitPrice: widget.sale!.unitPrice,
              ),
            )
          : context.read<InventoryCubit>().recordSale(
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
    if (widget.sale != null) {
      Navigator.pop(context, sale);
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
    String? initialValue,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: TextFormField(
      initialValue: initialValue,
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
      appBar: AppBar(
        title: Text(widget.sale == null ? 'Record Sale' : 'Edit Receipt'),
      ),
      body: InventoryBuilder(
        builder: (context, state) => SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: AppSizes.cardPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sale == null
                                  ? 'New receipt'
                                  : 'Edit receipt #${widget.sale!.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              widget.sale == null
                                  ? 'Receipt number assigned automatically'
                                  : 'Receipt number and original price are preserved',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Customer details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.md),
                _customerField(
                  label: 'Customer name',
                  initialValue: _name,
                  icon: Icons.person_outline,
                  onSaved: (v) => _name = v!.trim(),
                ),
                _customerField(
                  label: 'Address',
                  initialValue: _address,
                  icon: Icons.location_on_outlined,
                  onSaved: (v) => _address = v!.trim(),
                  keyboardType: TextInputType.streetAddress,
                ),
                _customerField(
                  label: 'Phone number',
                  initialValue: _phone,
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
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Sale details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.md),
                if (widget.sale != null)
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Product'),
                    child: Text(widget.sale!.productName),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: products.any((p) => p.id == _productId)
                        ? _productId
                        : null,
                    key: ValueKey(
                      products.any((p) => p.id == _productId)
                          ? _productId
                          : null,
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
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  initialValue: _quantity.toString(),
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
                    if (selected != null &&
                        count >
                            selected.quantity + (widget.sale?.quantity ?? 0)) {
                      return 'Not enough stock available';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.lg),
                Container(
                  padding: AppSizes.cardPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: Ns ${((widget.sale?.unitPrice ?? selected?.price ?? 0) * (_quantity > 0 ? _quantity : 0)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed:
                      (products.isEmpty && widget.sale == null) || _saving
                      ? null
                      : _save,
                  child: Text(
                    widget.sale == null ? 'Save Sale' : 'Save Changes',
                  ),
                ),
                const SizedBox(height: AppSizes.spacing12),
                Text(
                  widget.sale != null
                      ? 'Saving updates the receipt and adjusts stock.'
                      : products.isEmpty
                      ? 'Add stock before recording a sale.'
                      : 'Saving updates stock and creates your receipt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
