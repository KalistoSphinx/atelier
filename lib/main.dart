import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/view/pages/home_page.dart';
import 'package:image_app/features/auth/view/auth_page.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';
import 'package:image_app/firebase_options.dart';

import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      // builder: (context, child) {
      //   return MediaQuery(
      //     data: MediaQuery.of(
      //       context,
      //     ).copyWith(textScaler: TextScaler.noScaling),
      //     child: child!,
      //   );
      // },
      theme: ThemeData(fontFamily: "Manrope"),
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) => user == null ? const AuthPage() : const HomePage(),
        error: (e, st) => Scaffold(body: Center(child: Text("Error: $e"))),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
