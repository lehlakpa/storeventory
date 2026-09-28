import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/inventory_cubit.dart';
import '../core/constants/app_sizes.dart';
import '../models/product_ui_model.dart';
import 'run_mutation.dart';

Future<void> showUpdateStockDialog(
  BuildContext context,
  ProductUiModel product, {
  bool increment = false,
}) async {
  final formKey = GlobalKey<FormState>();
  var quantity = increment ? 0 : product.quantity;
  var note = product.note;
  final result = await showDialog<(int, String?)>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(increment ? 'Restock ${product.name}' : 'Update Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.sm),
              Text('Current stock: ${product.quantity} ${product.unit}'),
              const SizedBox(height: AppSizes.lg),
              TextFormField(
                initialValue: increment ? '' : '${product.quantity}',
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: increment
                      ? 'Quantity to add'
                      : 'New stock quantity',
                  helperText: increment
                      ? 'Adds to the current quantity.'
                      : 'Replaces the current quantity.',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < (increment ? 1 : 0)) {
                    return increment
                        ? 'Enter a positive whole number'
                        : 'Enter a whole number of 0 or more';
                  }
                  return null;
                },
                onSaved: (value) => quantity = int.parse(value!.trim()),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                initialValue: product.note,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add product or stock details',
                  alignLabelWithHint: true,
                ),
                onSaved: (value) => note = (value ?? '').trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            formKey.currentState!.save();
            Navigator.pop(dialogContext, (
              quantity,
              note == product.note ? null : note,
            ));
          },
          child: Text(increment ? 'Restock' : 'Update Stock'),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;
  final saved = await runMutation(context, () async {
    await context.read<InventoryCubit>().changeStock(
      product.id,
      result.$1,
      increment: increment,
      note: result.$2,
    );
    return true;
  });
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} stock updated.')));
  }
}
