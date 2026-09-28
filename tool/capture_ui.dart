import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/core/theme/app_theme.dart';
import 'package:storeventory/core/constants/app_assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:storeventory/blocs/inventory_cubit.dart';
import 'package:storeventory/data/inventory_repository.dart';

import '../test/support/test_auth_repository.dart';

import 'package:storeventory/screens/sales/record_sale_screen.dart';
import 'package:storeventory/screens/auth/login_screen.dart';
import 'package:storeventory/widgets/custom_loading.dart';
import 'package:storeventory/screens/sales/sales_screen.dart';
import 'package:storeventory/screens/main/main_screen.dart';
import 'package:storeventory/screens/stocks/product_details_screen.dart';
import 'package:storeventory/screens/stocks/add_product_screen.dart';

void main() {
  testWidgets('render mobile UI previews', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fontRoot =
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'Ahem': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final font = File('$fontRoot/${entry.value}');
      if (font.existsSync()) {
        final loader = FontLoader(entry.key)
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
    }
    final boundary = GlobalKey();
    final authRepo = TestAuthRepository();
    final authBloc = AuthBloc(authRepo);
    final inventory = InventoryCubit(
      FirestoreInventoryRepository(FakeFirebaseFirestore(), 'preview'),
    );

    Widget wrap(Widget child) => RepaintBoundary(
      key: boundary,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => authBloc),
          BlocProvider(create: (_) => inventory),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: child,
        ),
      ),
    );
    Future<void> capture(String name) async {
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(AppAssets.onboardingGrowth),
          boundary.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/ui-preview').create(recursive: true);
        await File('build/ui-preview/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(wrap(const MainScreen()));
    await capture('home');
    await tester.tap(find.text('View Inventory'));
    await capture('stocks');
    await tester.tap(find.text('Category'));
    await capture('categories');
    await tester.pumpWidget(
      wrap(const ProductDetailsScreen(productId: 'missing')),
    );
    await capture('product-details');
    await tester.pumpWidget(wrap(const AddProductScreen()));
    await capture('add-product');
    await tester.pumpWidget(wrap(const RecordSaleScreen()));
    await capture('sale-form');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -420),
    );
    await capture('sale-form-bottom');
    await tester.pumpWidget(wrap(const LoginScreen()));
    await capture('login');
    await tester.pumpWidget(wrap(const Scaffold(body: CustomLoading())));
    await tester.pump(const Duration(milliseconds: 100));
    final loadingRender =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await loadingRender.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/ui-preview/loading.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(wrap(const SalesScreen()));
    await capture('sales');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
