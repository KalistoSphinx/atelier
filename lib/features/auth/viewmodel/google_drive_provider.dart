import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';

class GoogleDriveNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    return ref.watch(sharedPrefsServiceProvider).driveEmail;
  }

  Future<void> connect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final email = await ref.read(authRepositoryProvider).connectGoogleDrive();
      if (email != null) {
        await ref.read(sharedPrefsServiceProvider).saveDriveEmail(email);
      }
      return email;
    });
  }

  Future<void> disconnect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).disconnectGoogleDrive();
      await ref.read(sharedPrefsServiceProvider).clearDriveEmail();
      return null;
    });
  }
}

final googleDriveProvider = AsyncNotifierProvider<GoogleDriveNotifier, String?>(
  GoogleDriveNotifier.new,
);
