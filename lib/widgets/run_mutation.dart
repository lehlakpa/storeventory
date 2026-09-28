import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'custom_loading.dart';

Future<T?> runMutation<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CustomLoading(message: 'Saving…'),
        ),
      ),
    ),
  );
  navigator.push(route);
  try {
    return await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is FirebaseException
                ? (e.message ?? 'Unable to save. Please try again.')
                : e.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
    return null;
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}
