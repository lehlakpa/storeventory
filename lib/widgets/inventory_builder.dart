import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/inventory_cubit.dart';
import 'custom_loading.dart';

class InventoryBuilder extends StatelessWidget {
  const InventoryBuilder({super.key, required this.builder});
  final Widget Function(BuildContext, InventoryState) builder;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          if (state.loading) return const CustomLoading();
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: context.read<InventoryCubit>().reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return builder(context, state);
        },
      );
}
