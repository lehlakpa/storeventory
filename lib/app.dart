import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/auth_bloc.dart';
import 'blocs/inventory_cubit.dart';
import 'data/auth_repository.dart';
import 'data/inventory_repository.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/custom_loading.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    this.authRepository,
    this.inventoryRepository,
    this.hasSeenOnboarding = false,
  });
  final AuthRepository? authRepository;
  final InventoryRepository? inventoryRepository;
  final bool hasSeenOnboarding;
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _seen = widget.hasSeenOnboarding;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AuthBloc(
      widget.authRepository ??
          FirebaseAuthRepository(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          ),
    ),
    child: BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) =>
          a.profile?.uid != b.profile?.uid || a.initializing != b.initializing,
      builder: (context, state) {
        final uid = state.profile?.uid;
        final app = MaterialApp(
          key: ValueKey(uid ?? 'signed-out'),
          title: 'Storeventory',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: state.initializing
              ? const Scaffold(body: CustomLoading())
              : uid != null
              ? const MainScreen()
              : _Welcome(hasSeenOnboarding: _seen, onSeen: () => _seen = true),
        );
        if (uid == null) return app;
        return BlocProvider(
          key: ValueKey(uid),
          create: (_) => InventoryCubit(
            widget.inventoryRepository ??
                FirestoreInventoryRepository(FirebaseFirestore.instance, uid),
          ),
          child: app,
        );
      },
    ),
  );
}

class _Welcome extends StatefulWidget {
  const _Welcome({required this.hasSeenOnboarding, required this.onSeen});
  final VoidCallback onSeen;
  final bool hasSeenOnboarding;
  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  late bool _seen = widget.hasSeenOnboarding;
  @override
  Widget build(BuildContext context) => _seen
      ? const LoginScreen()
      : OnboardingScreen(
          onComplete: () async {
            setState(() => _seen = true);
            widget.onSeen();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_seen_onboarding', true);
          },
        );
}
