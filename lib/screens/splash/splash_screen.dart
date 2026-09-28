import 'package:flutter/material.dart';

import '../../widgets/custom_loading.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: CustomLoading());
}
