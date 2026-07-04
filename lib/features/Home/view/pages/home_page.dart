import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: authState.when(
        data: (user) => Center(child: Text("${user?.displayName}")),
        error: (e, st) => Center(child: Text("$e")),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
