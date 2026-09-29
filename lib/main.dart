import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/secure_storage_service.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    await Firebase.initializeApp(
      options: apiKey.isEmpty
          ? DefaultFirebaseOptions.currentPlatform
          : const FirebaseOptions(
              apiKey: apiKey,
              appId: String.fromEnvironment('FIREBASE_APP_ID'),
              messagingSenderId: String.fromEnvironment(
                'FIREBASE_MESSAGING_SENDER_ID',
              ),
              projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
              authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
              storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
            ),
    );
    await const SecureStorageService().migrateLegacyPreferences();
    final seen = await SecureStorageService.storage.read(
      key: 'has_seen_onboarding',
    );
    runApp(App(hasSeenOnboarding: seen == 'true'));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Storeventory')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to initialize Firebase. Check the app configuration and restart.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
