import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_state.dart';
import '../../blocs/auth_event.dart';
import '../../widgets/custom_loading.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final profile = state.profile;
        if (state.busy) return const CustomLoading(message: 'Signing out...');
        return ListView(
          padding: AppSizes.screenPadding,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 42,
                child: Icon(Icons.person_outline, size: 44),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              profile?.name.isNotEmpty == true ? profile!.name : 'Your profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            const Text('Store administrator', textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Name'),
                    subtitle: Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name
                          : 'Not provided',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: SelectableText(profile?.email ?? 'Not provided'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    ),
  );
}
