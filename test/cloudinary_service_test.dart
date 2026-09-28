import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storeventory/data/app_error.dart';
import 'package:storeventory/data/cloudinary_service.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/models/product_ui_model.dart';

void main() {
  XFile image() => XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    name: 'photo.png',
    path: 'photo.png',
  );

  test(
    'multipart upload metadata survives Firestore save, read and edit',
    () async {
      final service = CloudinaryService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://api.cloudinary.com/v1_1/dglxnraim/image/upload',
          );
          final body = utf8.decode(request.bodyBytes);
          expect(body, contains('name="upload_preset"'));
          expect(body, contains('flutter_coffee_test'));
          expect(body, contains('filename="photo.png"'));
          return http.Response(
            jsonEncode({
              'secure_url':
                  'https://res.cloudinary.com/dglxnraim/image/upload/photo.png',
              'public_id': 'photo',
            }),
            200,
          );
        }),
      );
      final uploaded = await service.uploadImage(image());
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      await repo.save(
        ProductUiModel(
          id: 'p',
          name: 'Product',
          imageUrl: uploaded.url,
          imagePublicId: uploaded.publicId,
          imageFileName: uploaded.fileName,
          imageSizeBytes: uploaded.sizeBytes,
          price: 10,
          quantity: 2,
          category: 'Test',
        ),
      );
      final product = (await repo.watchProducts().first).single;
      await repo.save(product.withQuantity(3), previous: product);
      final saved = (await db.collection('products').doc('p').get()).data()!;
      for (final entry in uploaded.toMap().entries) {
        expect(saved[entry.key], entry.value);
      }
    },
  );

  test('empty or oversized files are rejected before network upload', () async {
    final service = CloudinaryService(
      client: MockClient((_) async {
        fail('Invalid file must not reach the network');
      }),
    );
    for (final size in [0, CloudinaryService.maxImageBytes + 1]) {
      await expectLater(
        service.uploadImage(XFile.fromData(Uint8List(size))),
        throwsA(isA<AppException>()),
      );
    }
  });

  test(
    'configuration, HTTP errors, malformed and insecure responses fail',
    () async {
      await expectLater(
        CloudinaryService(cloudName: '').uploadImage(image()),
        throwsA(isA<AppException>()),
      );
      for (final response in [
        http.Response('Denied', 400),
        http.Response('not json', 200),
        http.Response('{}', 200),
        http.Response(
          '{"secure_url":"http://example.com/photo","public_id":"photo"}',
          200,
        ),
        http.Response(
          '{"secure_url":"https://example.com/photo","public_id":""}',
          200,
        ),
      ]) {
        final service = CloudinaryService(
          client: MockClient((_) async => response),
        );
        await expectLater(
          service.uploadImage(image()),
          throwsA(isA<AppException>()),
        );
      }
    },
  );

  test('network failure has a retryable message', () async {
    final service = CloudinaryService(
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    await expectLater(
      service.uploadImage(image()),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('connection'),
        ),
      ),
    );
  });
}
