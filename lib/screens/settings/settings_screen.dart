import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/theme_cubit.dart';
import 'profile_screen.dart';
import 'about_screen.dart';
import '../auth/register_screen.dart';
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
            ? const CustomLoading(message: 'Signing out...')
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, mode) =>
                              SegmentedButton<ThemeMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    icon: Icon(Icons.light_mode_outlined),
                                    label: Text('Light mode'),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    icon: Icon(Icons.dark_mode_outlined),
                                    label: Text('Dark mode'),
                                  ),
                                ],
                                selected: {mode},
                                onSelectionChanged: (selection) async {
                                  try {
                                    await context.read<ThemeCubit>().setMode(
                                      selection.single,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Unable to save appearance. Please try again.',
                                              ),
                                            ),
                                          );
                                    }
                                  }
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Storeventory'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
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
                    leading: const Icon(Icons.person_add_outlined),
                    title: const Text('Register'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
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
