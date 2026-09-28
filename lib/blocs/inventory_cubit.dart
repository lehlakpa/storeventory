import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/inventory_repository.dart';
import '../models/product_ui_model.dart';
import '../models/sale_ui_model.dart';

class InventoryState {
  const InventoryState({
    this.products = const [],
    this.categories = const [],
    this.sales = const [],
    this.loading = true,
    this.error,
  });
  final List<ProductUiModel> products;
  final List<String> categories;
  final List<SaleUiModel> sales;
  final bool loading;
  final String? error;
}

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(this.repository) : super(const InventoryState()) {
    reload();
  }
  final InventoryRepository repository;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _generation = 0;

  Future<void> reload() async {
    final generation = ++_generation;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    if (isClosed || generation != _generation) return;
    emit(const InventoryState());
    var products = <ProductUiModel>[];
    var categories = <String>[];
    var sales = <SaleUiModel>[];
    final ready = <String>{};
    final errors = <String, String>{};
    void publish() {
      if (isClosed || generation != _generation) return;
      emit(
        InventoryState(
          products: List.unmodifiable(products),
          categories: List.unmodifiable(categories),
          sales: List.unmodifiable(sales),
          loading: ready.length < 3 && errors.isEmpty,
          error: errors.isEmpty ? null : errors.values.first,
        ),
      );
    }

    void listen<T>(String key, Stream<T> stream, void Function(T) update) {
      _subscriptions.add(
        stream.listen(
          (value) {
            update(value);
            ready.add(key);
            errors.remove(key);
            publish();
          },
          onError: (Object e) {
            errors[key] =
                'Unable to load $key. Check your connection and permissions.';
            publish();
          },
        ),
      );
    }

    listen('products', repository.watchProducts(), (v) => products = v);
    listen('categories', repository.watchCategories(), (v) => categories = v);
    listen('sales', repository.watchSales(), (v) => sales = v);
  }

  List<ProductUiModel> get products => state.products;
  List<String> get categories => state.categories;
  List<SaleUiModel> get sales => state.sales;
  int get totalStock => products.fold(0, (s, p) => s + p.quantity);
  double get totalValue => products.fold(0, (s, p) => s + p.price * p.quantity);
  int get lowStockCount =>
      products.where((p) => p.quantity <= p.minimumStock).length;
  ProductUiModel? product(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> save(ProductUiModel p, {ProductUiModel? previous}) =>
      repository.save(p, previous: previous);
  Future<void> remove(String id) => repository.remove(id);
  Future<void> changeStock(
    String id,
    int value, {
    bool increment = false,
    String? note,
  }) => repository.changeStock(id, value, increment: increment, note: note);
  Future<bool> addCategory(String name) async {
    if (categories.any((c) => c.toLowerCase() == name.trim().toLowerCase())) {
      return false;
    }
    return repository.addCategory(name);
  }

  Future<SaleUiModel> updateSale(SaleUiModel sale) =>
      repository.updateSale(sale);
  Future<void> deleteSale(String id) => repository.deleteSale(id);

  Future<SaleUiModel> recordSale(
    String id,
    int quantity, {
    required String customerName,
    required String address,
    required String phone,
    required DateTime date,
  }) => repository.recordSale(
    id,
    quantity,
    customerName: customerName,
    address: address,
    phone: phone,
    date: date,
  );
  @override
  Future<void> close() async {
    ++_generation;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
