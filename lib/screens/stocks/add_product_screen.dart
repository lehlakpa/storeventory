import '../../widgets/inventory_builder.dart';

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import 'package:image_picker/image_picker.dart';

import '../../data/cloudinary_service.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../categories/category_screen.dart';
import '../../widgets/run_mutation.dart';
import '../../models/product_ui_model.dart';
import '../../widgets/product_image.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.product});
  final ProductUiModel? product;
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _uploading = false;
  UploadedImage? _uploadedImage;
  late String _name, _category, _unit, _image, _note;
  late int _quantity, _minimum;
  late double _purchase, _price;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = p?.name ?? '';
    _category = p?.category ?? '';
    _unit = p?.unit ?? 'pieces';
    _image = p?.imageUrl ?? '';
    _note = p?.note ?? '';
    _quantity = p?.quantity ?? 0;
    _minimum = p?.minimumStock ?? 10;
    _purchase = p?.purchasePrice ?? 0;
    _price = p?.price ?? 0;
  }

  Future<void> _setImage() async {
    if (_saving || _uploading) return;
    setState(() => _uploading = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final uploaded = await CloudinaryService().uploadImage(image);
      if (!mounted) return;
      setState(() {
        _uploadedImage = uploaded;
        _image = uploaded.url;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload image: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _uploading || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    _form.currentState!.save();
    final saved = await runMutation(context, () async {
      await context.read<InventoryCubit>().save(
        ProductUiModel(
          id: widget.product?.id ?? '',
          name: _name.trim(),
          category: _category,
          unit: _unit.trim(),
          quantity: _quantity,
          minimumStock: _minimum,
          price: _price,
          purchasePrice: _purchase,
          imageUrl: _image,
          note: _note.trim(),
          imagePublicId:
              _uploadedImage?.publicId ?? widget.product?.imagePublicId ?? '',
          imageFileName:
              _uploadedImage?.fileName ?? widget.product?.imageFileName ?? '',
          imageSizeBytes:
              _uploadedImage?.sizeBytes ?? widget.product?.imageSizeBytes ?? 0,
        ),
        previous: widget.product,
      );
      return true;
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == true) Navigator.pop(context);
  }

  Widget _field(
    String label,
    IconData icon,
    String value,
    FormFieldSetter<String> save, {
    bool number = false,
    bool whole = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: TextFormField(
      initialValue: value,
      onSaved: save,
      keyboardType: number
          ? TextInputType.numberWithOptions(decimal: !whole)
          : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter $label';
        if (number) {
          final parsed = num.tryParse(value);
          if (parsed == null ||
              !parsed.isFinite ||
              parsed < 0 ||
              (whole && int.tryParse(value) == null)) {
            return whole
                ? 'Enter a whole number of 0 or more'
                : 'Enter a valid amount of 0 or more';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
    ),
    body: InventoryBuilder(
      builder: (context, state) => Form(
        key: _form,
        child: ListView(
          padding: AppSizes.screenPadding,
          children: [
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving || _uploading ? null : _setImage,
                child: SizedBox(
                  height: 155,
                  child: _uploading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppSizes.spacing12),
                            Text('Uploading image...'),
                          ],
                        )
                      : _image.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            SizedBox(height: AppSizes.spacing12),
                            Text(
                              'Add Product Image',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: AppSizes.cardPadding,
                          child: ProductImage(url: _image),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _field(
              'Product Name',
              Icons.person_outline,
              _name,
              (v) => _name = v!,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: DropdownButtonFormField<String>(
                initialValue: _category.isEmpty ? null : _category,
                validator: (v) => v == null || v.isEmpty
                    ? 'Add and select a category first'
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 19),
                ),
                items:
                    {
                          ...context.read<InventoryCubit>().categories,
                          if (_category.isNotEmpty) _category,
                        }
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => _category = v!,
              ),
            ),
            if (context.watch<InventoryCubit>().categories.isEmpty)
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryScreen()),
                  );
                  if (mounted) setState(() {});
                },
                child: const Text('No categories yet. Add a category'),
              ),
            _field(
              'Quantity',
              Icons.numbers,
              '$_quantity',
              (v) => _quantity = int.parse(v!),
              number: true,
              whole: true,
            ),
            _field(
              'Unit (e.g. piece, kg, bottle)',
              Icons.inventory_2_outlined,
              _unit,
              (v) => _unit = v!,
            ),
            _field(
              'Purchase Price (Ns)',
              Icons.shopping_bag_outlined,
              '$_purchase',
              (v) => _purchase = double.parse(v!),
              number: true,
            ),
            _field(
              'Selling Price (Ns)',
              Icons.sell_outlined,
              '$_price',
              (v) => _price = double.parse(v!),
              number: true,
            ),
            _field(
              'Minimum Stock',
              Icons.warning_amber_rounded,
              '$_minimum',
              (v) => _minimum = int.parse(v!),
              number: true,
              whole: true,
            ),
            TextFormField(
              initialValue: _note,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add product or stock details',
                alignLabelWithHint: true,
              ),
              onSaved: (value) => _note = value ?? '',
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: _saving || _uploading ? null : _save,
              child: Text(
                widget.product == null ? 'Save Product' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
