import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:storeventory/widgets/reauthenticate_dialog.dart';

import 'support/test_auth_repository.dart';

void main() {
  late TestAuthRepository repository;
  late AuthBloc bloc;
  setUp(() async {
    repository = TestAuthRepository()..currentUid = 'test-user';
    bloc = AuthBloc(repository);
    await bloc.stream.firstWhere((state) => !state.initializing);
  });
  tearDown(() async {
    await bloc.close();
    await repository.changes.close();
  });
  for (final outcome in ['success', 'cancel', 'failure']) {
    testWidgets('sensitive action password confirmation: $outcome', (
      tester,
    ) async {
      repository.failReauthentication = outcome == 'failure';
      var mutations = 0;
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () async {
                      if (await confirmSensitiveAction(context)) mutations++;
                    },
                    child: const Text('Sensitive action'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sensitive action'));
      await tester.pumpAndSettle();
      if (outcome == 'cancel') {
        await tester.tap(find.text('Cancel'));
      } else {
        await tester.enterText(find.byType(TextField), 'test-password');
        await tester.tap(find.text('Verify'));
      }
      await tester.pumpAndSettle();
      expect(mutations, outcome == 'success' ? 1 : 0);
      expect(repository.reauthenticationCalls, outcome == 'cancel' ? 0 : 1);
      if (outcome == 'failure') {
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
