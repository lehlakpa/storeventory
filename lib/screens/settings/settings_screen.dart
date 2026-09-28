import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../widgets/custom_loading.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      final profile = state.profile;
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: state.busy
            ? const CustomLoading(message: 'Signing out?')
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name
                          : 'No profile name',
                    ),
                    subtitle: Text(profile?.email ?? ''),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Storeventory'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Storeventory',
                      applicationVersion: '1.0.0',
                      children: [
                        const Text('Manage inventory, stock and sales.'),
                      ],
                    ),
                  ),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () =>
                        context.read<AuthBloc>().add(LogoutRequested()),
                  ),
                ],
              ),
      );
    },
  );
}
