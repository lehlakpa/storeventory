# Storeventory

Flutter inventory app using flutter_bloc (AuthBloc and InventoryCubit), Firebase Authentication, and Cloud Firestore. Runtime data is never seeded or replaced with demo data. Empty collections show empty states and zero totals; read failures show an error with Retry.

## Firebase setup

The app uses Firebase project `storeventory-f69d5` through the generated `lib/firebase_options.dart` settings.

1. To refresh the registered app settings, run: `flutterfire configure --project=storeventory-f69d5`.
2. Enable Authentication > Email/Password and create a Firestore database in that project.
3. Run: `flutter run`.
4. Deploy the supplied rules when ready: `firebase deploy --only firestore:rules --project storeventory-f69d5`.

For an explicit configuration override, copy `firebase.config.example.json` to `firebase.config.json`, populate it with the target platform's Firebase app settings, and run `flutter run --dart-define-from-file=firebase.config.json`.

Rules are saved in firestore.rules and match the supplied policy. Inventory collections are shared by all authenticated users; only admins/{uid} profiles are private to their owner. This is a shared-store model.

## Stored data

Product photos are selected from the photo library/file picker and uploaded to Cloudinary before saving the product. The default cloud is `dglxnraim` with unsigned preset `flutter_coffee_test`. Override these with `--dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...`. The preset must allow unsigned image uploads. Images must be non-empty and at most 10 MB. Firestore stores `imageUrl`, `imagePublicId`, `imageFileName`, and `imageSizeBytes`; image bytes stay in Cloudinary. Failed product saves retain the uploaded image for retry. Cancelling after upload or replacing/deleting a product does not delete Cloudinary assets.

- admins/{authUid}: name, email, createdAt (server timestamp).
- products/{autoId}: name, imageUrl (optional HTTPS URL or empty), price, purchasePrice, quantity, minimumStock, category (category name), unit.
- categories/{encodedLowercaseName}: name, createdAt. Existing categories with other document IDs are also read.
- sales/{autoId}: customerName, address, phone, date (Firestore Timestamp), productId, productName, imageUrl, unit, quantity, unitPrice, adminId, createdAt. The document ID is the receipt number.
- stock_history/{autoId}: productId, previousQuantity, quantity, change, reason, adminId, createdAt. Every stock mutation appends history; history is never updated or deleted.

Sales, stock decrements, and history are committed in a single transaction. Restocking reads the current server quantity. Editing a product rejects stale stock quantities. Failed writes keep the form open. Transactions require a network connection.

The supplied rules also cover customers, orders, notifications, and settings; the current UI does not invent records for these collections. Customer details are captured on each sale receipt. The settings screen displays the authenticated admin profile.

## Verification

flutter analyze
flutter test
flutter test tool/capture_ui.dart

Tests use an isolated fake Firestore and test-only authentication implementation. They do not create records in a live project. UI previews are written to build/ui-preview. Production Firebase connectivity and deployed rules must be verified against the configured project.
