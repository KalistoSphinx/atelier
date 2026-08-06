import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/view/pages/home_page.dart';
import 'package:image_app/features/auth/view/auth_page.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';
import 'package:image_app/firebase_options.dart';
import 'package:image_app/core/services/drive_sync_service.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';
import 'package:image_app/core/services/notification_service.dart';
import 'package:image_app/features/Home/viewmodel/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await GoogleSignIn.instance.initialize();
      await LibraryService.instance.init();
      final prefs = await SharedPreferences.getInstance();
      final prefsService = SharedPrefsService(prefs);

      final container = ProviderContainer(
        overrides: [
          sharedPrefsServiceProvider.overrideWithValue(prefsService),
        ],
      );

      final syncService = container.read(driveSyncServiceProvider);
      await syncService.backupNow(silent: true);
      return Future.value(true);
    } catch (err) {
      debugPrint('Workmanager sync error: $err');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  await NotificationService().requestPermissions();
  await GoogleSignIn.instance.initialize();
  await LibraryService.instance.init();
  
  Workmanager().initialize(
    callbackDispatcher,
  );

  final prefs = await SharedPreferences.getInstance();
  final prefsService = SharedPrefsService(prefs);
  runApp(ProviderScope(
    overrides: [
      sharedPrefsServiceProvider.overrideWithValue(prefsService),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      final syncService = ref.read(driveSyncServiceProvider);
      if (syncService.isDirty) {
        // Schedule reliable background sync
        Workmanager().registerOneOffTask(
          "driveSyncTask",
          "driveSyncTask",
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      themeMode: .dark,
      darkTheme: ThemeData(
        brightness: .dark,
        fontFamily: "Manrope",
      ),
      theme: ThemeData(
        fontFamily: "Manrope"
      ),
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
