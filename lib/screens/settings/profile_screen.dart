import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final profile = state.profile;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 42,
                child: Icon(Icons.person_outline, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              profile?.name.isNotEmpty == true ? profile!.name : 'Your profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Store administrator', textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Card(
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
          ],
        );
      },
    ),
  );
}
