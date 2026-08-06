import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:image_app/core/services/notification_service.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';
import 'package:image_app/core/services/sync_manifest.dart';
import 'package:image_app/features/Home/viewmodel/library_service.dart';


class DriveSyncService {
  final Ref _ref;
  SyncManifest? _manifest;
  bool _isSyncing = false;
  bool _isDirty = false;

  static const _appFolderName = 'PageTurn';
  static const _scopes = [drive.DriveApi.driveFileScope];

  DriveSyncService(this._ref);

  bool get _isSyncEnabled =>
      _ref.read(sharedPrefsServiceProvider).isSyncEnabled;
  bool get isSyncing => _isSyncing;
  bool get isDirty => _isDirty;

  // ── Private helpers ───────────────────────────────────────────

  Future<SyncManifest> _getManifest() async {
    _manifest ??= await SyncManifest.load();
    return _manifest!;
  }

  drive.DriveApi? _cachedDriveApi;

  /// Obtain an authenticated DriveApi. Cached per session but
  /// invalidated on auth errors so the next call gets a fresh token.
  ///
  /// Uses a two-tier strategy:
  /// 1. Try the instance-level authorizationClient first — on Android this
  ///    calls AuthorizationClient.authorize() which can silently issue
  ///    tokens without any sign-in UI (authorizationRequiresUserInteraction
  ///    returns false on Android).
  /// 2. If that returns null (e.g. scopes not yet granted), fall back to
  ///    attemptLightweightAuthentication() + the account-level client.
  Future<drive.DriveApi?> _getDriveApi({bool forceRefresh = false}) async {
    if (_cachedDriveApi != null && !forceRefresh) return _cachedDriveApi;
    _cachedDriveApi = null; // Clear stale cache

    try {
      // Tier 1: Try instance-level authorization (no sign-in UI needed).
      // On Android, the authorization layer is independent of the sign-in
      // layer and can issue tokens silently for any Google account on the
      // device that has previously authorized this app's scopes.
      GoogleSignInClientAuthorization? authorization;
      try {
        authorization = await GoogleSignIn.instance.authorizationClient
            .authorizationForScopes(_scopes);
      } catch (e) {
        debugPrint('DriveSyncService: Instance-level auth failed: $e');
      }

      // Tier 2: If instance-level auth didn't work, try restoring the
      // session and using the account-level client.
      if (authorization == null) {
        final account =
            await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (account != null) {
          try {
            authorization = await account.authorizationClient
                .authorizationForScopes(_scopes);
          } catch (e) {
            debugPrint('DriveSyncService: Account-level auth failed: $e');
          }
        }
      }

      if (authorization == null) {
        debugPrint('DriveSyncService: Could not obtain Drive authorization.');
        return null;
      }

      final client = authorization.authClient(scopes: _scopes);
      _cachedDriveApi = drive.DriveApi(client);
      return _cachedDriveApi;
    } catch (e) {
      debugPrint('DriveSyncService: Failed to get DriveApi: $e');
      return null;
    }
  }

  /// Invalidate the cached DriveApi so the next call fetches a fresh token.
  void _invalidateAuth() {
    _cachedDriveApi = null;
  }

  /// Ensure the PageTurn / books / covers folder structure exists on Drive.
  Future<bool> _ensureFolders(drive.DriveApi api) async {
    final manifest = await _getManifest();

    manifest.rootFolderId ??= await _findOrCreateFolder(
      api,
      _appFolderName,
      null,
    );
    if (manifest.rootFolderId == null) return false;

    manifest.booksFolderId ??= await _findOrCreateFolder(
      api,
      'books',
      manifest.rootFolderId!,
    );
    manifest.coversFolderId ??= await _findOrCreateFolder(
      api,
      'covers',
      manifest.rootFolderId!,
    );

    await manifest.save();
    return manifest.booksFolderId != null && manifest.coversFolderId != null;
  }

  /// Find an existing folder by name+parent, or create it.
  Future<String?> _findOrCreateFolder(
    drive.DriveApi api,
    String name,
    String? parentId,
  ) async {
    try {
      var query =
          "name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      if (parentId != null) query += " and '$parentId' in parents";

      final result = await api.files.list(q: query, spaces: 'drive');
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      final folderMeta = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder';
      if (parentId != null) folderMeta.parents = [parentId];

      final folder = await api.files.create(folderMeta);
      return folder.id;
    } catch (e) {
      debugPrint('DriveSyncService: Failed to find/create folder "$name": $e');
      return null;
    }
  }

  /// Upload a new file or update an existing one on Drive.
  Future<void> _upsertFile(
    drive.DriveApi api,
    String relativePath,
    File localFile,
    String parentFolderId,
  ) async {
    try {
      final manifest = await _getManifest();
      var existingId = manifest.files[relativePath];
      final fileName = localFile.uri.pathSegments.last;

      if (existingId == null) {
        // Query Drive to see if it already exists in the parent folder (e.g. if we lost the manifest)
        final query =
            "name = '$fileName' and '$parentFolderId' in parents and trashed = false";
        final result = await api.files.list(q: query, spaces: 'drive');
        if (result.files != null && result.files!.isNotEmpty) {
          existingId = result.files!.first.id;
          manifest.files[relativePath] = existingId!;
          await manifest.save();
        }
      }

      final media = drive.Media(localFile.openRead(), await localFile.length());

      if (existingId != null) {
        try {
          await api.files.update(drive.File(), existingId, uploadMedia: media);
        } on drive.DetailedApiRequestError catch (e) {
          if (e.status == 404) {
            // File was likely deleted from Drive. Clear ID and create it instead.
            existingId = null;
          } else {
            rethrow;
          }
        }
      }

      if (existingId == null) {
        final fileMeta = drive.File()
          ..name = fileName
          ..parents = [parentFolderId];

        final result = await api.files.create(fileMeta, uploadMedia: media);

        if (result.id != null) {
          manifest.files[relativePath] = result.id!;
          await manifest.save();
        }
      }
    } catch (e) {
      debugPrint('DriveSyncService: Failed to upsert "$relativePath": $e');
    }
  }

  /// Delete a file from Drive using its manifest-tracked ID.
  Future<void> _deleteRemoteFile(
    drive.DriveApi api,
    String relativePath,
  ) async {
    try {
      final manifest = await _getManifest();
      final driveId = manifest.files[relativePath];
      if (driveId == null) return;

      await api.files.delete(driveId);
      manifest.files.remove(relativePath);
      await manifest.save();
    } catch (e) {
      debugPrint('DriveSyncService: Failed to delete "$relativePath": $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────



  /// Mark that local data has changed. Does NOT trigger any network call.
  void markDirty() {
    if (!_isSyncEnabled) return;
    _isDirty = true;
  }

  /// Called via Workmanager to sync if dirty.
  Future<void> flushIfDirty({bool silent = true}) async {
    if (!_isDirty || !_isSyncEnabled) return;
    await backupNow(silent: silent);
  }

  /// Run a full differential backup with optional progress callback.
  /// Returns true if successful. Retries once on auth/token expiry errors.
  Future<bool> backupNow({
    void Function(int done, int total)? onProgress,
    bool silent = false,
    bool isRetry = false,
  }) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    if (!silent) _ref.read(syncProgressProvider.notifier).start("Backing up to Drive...");

    try {
      final api = await _getDriveApi();
      if (api == null) {
        if (!silent) {
          _ref
              .read(syncProgressProvider.notifier)
              .error("Backup failed: Auth error");
        }
        return false;
      }
      if (!await _ensureFolders(api)) {
        if (!silent) {
          _ref
              .read(syncProgressProvider.notifier)
              .error("Backup failed: Folder error");
        }
        return false;
      }

      final manifest = await _getManifest();
      final lib = LibraryService.instance;
      final localFiles = <String>{};

      final filesToUpload = <MapEntry<String, _FileWork>>[];
      final filesToDelete = <String>[];

      if (await lib.coversDir.exists()) {
        await for (final entity in lib.coversDir.list()) {
          if (entity is File) {
            final fileName = entity.uri.pathSegments.last;
            final key = 'covers/$fileName';
            localFiles.add(key);
            if (!manifest.files.containsKey(key)) {
              filesToUpload.add(
                MapEntry(key, _FileWork(entity, manifest.coversFolderId!)),
              );
            }
          }
        }
      }

      if (await lib.booksDir.exists()) {
        await for (final entity in lib.booksDir.list()) {
          if (entity is File) {
            final fileName = entity.uri.pathSegments.last;
            final key = 'books/$fileName';
            localFiles.add(key);
            if (!manifest.files.containsKey(key)) {
              filesToUpload.add(
                MapEntry(key, _FileWork(entity, manifest.booksFolderId!)),
              );
            }
          }
        }
      }

      // Find remote-only files to delete
      for (final driveKey in manifest.files.keys) {
        if ((driveKey.startsWith('books/') || driveKey.startsWith('covers/')) &&
            !localFiles.contains(driveKey)) {
          filesToDelete.add(driveKey);
        }
      }

      // Total steps: uploads + deletes + 1 (library.json)
      final total = filesToUpload.length + filesToDelete.length + 1;
      var done = 0;

      onProgress?.call(done, total);
      if (!silent) _ref.read(syncProgressProvider.notifier).updateProgress(done, total);

      // 1. Always update library.json first so metadata is synced immediately
      if (await lib.libraryFile.exists()) {
        await _upsertFile(
          api,
          'library.json',
          lib.libraryFile,
          manifest.rootFolderId!,
        );
      }
      done++;
      onProgress?.call(done, total);
      if (!silent) _ref.read(syncProgressProvider.notifier).updateProgress(done, total);

      // 2. Upload new files (covers first, then books based on loop order)
      for (final entry in filesToUpload) {
        await _upsertFile(
          api,
          entry.key,
          entry.value.file,
          entry.value.parentId,
        );
        done++;
        onProgress?.call(done, total);
        if (!silent) _ref.read(syncProgressProvider.notifier).updateProgress(done, total);
      }

      // 3. Delete removed files
      for (final key in filesToDelete) {
        await _deleteRemoteFile(api, key);
        done++;
        onProgress?.call(done, total);
        if (!silent) _ref.read(syncProgressProvider.notifier).updateProgress(done, total);
      }

      _isDirty = false;
      if (!silent) _ref.read(syncProgressProvider.notifier).complete("Backup complete");
      return true;
    } on drive.DetailedApiRequestError catch (e) {
      // Token expired mid-sync — retry once with a fresh token
      if ((e.status == 401 || e.status == 403) && !isRetry) {
        debugPrint('DriveSyncService: Token expired during backup, retrying...');
        _invalidateAuth();
        _isSyncing = false;
        return backupNow(onProgress: onProgress, silent: silent, isRetry: true);
      }
      debugPrint('DriveSyncService: backup failed: $e');
      if (!silent) _ref.read(syncProgressProvider.notifier).error("Backup failed");
      return false;
    } catch (e) {
      debugPrint('DriveSyncService: backup failed: $e');
      if (!silent) _ref.read(syncProgressProvider.notifier).error("Backup failed");
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Download all books and covers from Drive to local storage.
  /// Skips files that already exist locally.
  /// Returns true if successful. Retries once on auth/token expiry errors.
  Future<bool> loadFromDrive({
    void Function(int done, int total)? onProgress,
    bool isRetry = false,
  }) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _ref
        .read(syncProgressProvider.notifier)
        .start("Loading books from Drive...");

    try {
      final api = await _getDriveApi();
      if (api == null) {
        _ref
            .read(syncProgressProvider.notifier)
            .error("Load failed: Auth error");
        return false;
      }
      if (!await _ensureFolders(api)) {
        _ref
            .read(syncProgressProvider.notifier)
            .error("Load failed: Folder error");
        return false;
      }

      final manifest = await _getManifest();
      final lib = LibraryService.instance;

      // Collect files to download from each folder
      final downloads = <_DownloadWork>[];

      // List books folder
      if (manifest.booksFolderId != null) {
        final bookFiles = await api.files.list(
          q: "'${manifest.booksFolderId}' in parents and trashed = false",
          spaces: 'drive',
          $fields: 'files(id, name)',
        );
        for (final f in bookFiles.files ?? []) {
          final localPath = lib.getBookPath(f.name!);
          if (!File(localPath).existsSync()) {
            downloads.add(
              _DownloadWork(
                driveId: f.id!,
                localPath: localPath,
                manifestKey: 'books/${f.name!}',
              ),
            );
          }
          // Always track in manifest
          manifest.files['books/${f.name!}'] = f.id!;
        }
      }

      // List covers folder
      if (manifest.coversFolderId != null) {
        final coverFiles = await api.files.list(
          q: "'${manifest.coversFolderId}' in parents and trashed = false",
          spaces: 'drive',
          $fields: 'files(id, name)',
        );
        for (final f in coverFiles.files ?? []) {
          final localPath = lib.getCoverPath(f.name!.replaceAll('.jpg', ''));
          if (!File(localPath).existsSync()) {
            downloads.add(
              _DownloadWork(
                driveId: f.id!,
                localPath: localPath,
                manifestKey: 'covers/${f.name!}',
              ),
            );
          }
          manifest.files['covers/${f.name!}'] = f.id!;
        }
      }

      // Download library.json from Drive
      _DownloadWork? libraryDownload;
      if (manifest.rootFolderId != null) {
        final libFiles = await api.files.list(
          q: "'${manifest.rootFolderId}' in parents and name = 'library.json' and trashed = false",
          spaces: 'drive',
          $fields: 'files(id, name)',
        );
        if (libFiles.files != null && libFiles.files!.isNotEmpty) {
          final libFileId = libFiles.files!.first.id!;
          manifest.files['library.json'] = libFileId;
          libraryDownload = _DownloadWork(
            driveId: libFileId,
            localPath: lib.libraryFile.path,
            manifestKey: 'library.json',
          );
        }
      }

      // Total = file downloads + library.json (if exists)
      final total = downloads.length + (libraryDownload != null ? 1 : 0);
      var done = 0;
      onProgress?.call(done, total);
      _ref.read(syncProgressProvider.notifier).updateProgress(done, total);

      // Download book/cover files
      for (final dl in downloads) {
        try {
          final media =
              await api.files.get(
                    dl.driveId,
                    downloadOptions: drive.DownloadOptions.fullMedia,
                  )
                  as drive.Media;

          final outFile = File(dl.localPath);
          await outFile.parent.create(recursive: true);
          final sink = outFile.openWrite();
          await for (final chunk in media.stream) {
            sink.add(chunk);
          }
          await sink.close();
        } catch (e) {
          debugPrint(
            'DriveSyncService: Failed to download ${dl.manifestKey}: $e',
          );
        }
        done++;
        onProgress?.call(done, total);
        _ref.read(syncProgressProvider.notifier).updateProgress(done, total);
      }

      // Download and merge library.json
      if (libraryDownload != null) {
        try {
          final media =
              await api.files.get(
                    libraryDownload.driveId,
                    downloadOptions: drive.DownloadOptions.fullMedia,
                  )
                  as drive.Media;

          final bytes = <int>[];
          await for (final chunk in media.stream) {
            bytes.addAll(chunk);
          }

          final tempFile = File('${lib.libraryFile.path}.drive_tmp');
          await tempFile.writeAsBytes(bytes, flush: true);
          // Replace local library.json with Drive version
          await tempFile.rename(lib.libraryFile.path);
        } catch (e) {
          debugPrint('DriveSyncService: Failed to download library.json: $e');
        }
        done++;
        onProgress?.call(done, total);
        _ref.read(syncProgressProvider.notifier).updateProgress(done, total);
      }

      await manifest.save();

      // Refresh library state if we downloaded library.json
      if (libraryDownload != null) {
        await lib.init(); // Reload from disk
      }

      _ref.read(syncProgressProvider.notifier).complete("Load complete ✓");
      return true;
    } on drive.DetailedApiRequestError catch (e) {
      // Token expired mid-load — retry once with a fresh token
      if ((e.status == 401 || e.status == 403) && !isRetry) {
        debugPrint('DriveSyncService: Token expired during load, retrying...');
        _invalidateAuth();
        _isSyncing = false;
        return loadFromDrive(onProgress: onProgress, isRetry: true);
      }
      debugPrint('DriveSyncService: loadFromDrive failed: $e');
      _ref.read(syncProgressProvider.notifier).error("Load failed");
      return false;
    } catch (e) {
      debugPrint('DriveSyncService: loadFromDrive failed: $e');
      _ref.read(syncProgressProvider.notifier).error("Load failed");
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Wipe all sync tracking data. Called on Drive disconnect.
  Future<void> clearSyncData() async {
    _cachedDriveApi = null;
    _isDirty = false;
    final manifest = await _getManifest();
    await manifest.clear();
    _manifest = null;
  }
}

/// Internal helper to pair a file with its parent folder ID.
class _FileWork {
  final File file;
  final String parentId;
  _FileWork(this.file, this.parentId);
}

/// Internal helper for download tasks.
class _DownloadWork {
  final String driveId;
  final String localPath;
  final String manifestKey;
  _DownloadWork({
    required this.driveId,
    required this.localPath,
    required this.manifestKey,
  });
}

/// State for the global sync progress indicator.
class SyncProgressState {
  final bool isSyncing;
  final String? status;
  final int done;
  final int total;
  final bool isComplete;
  final bool isError;

  SyncProgressState({
    this.isSyncing = false,
    this.status,
    this.done = 0,
    this.total = 0,
    this.isComplete = false,
    this.isError = false,
  });
}

class SyncProgressNotifier extends Notifier<SyncProgressState> {
  static const int _notificationId = 100;

  @override
  SyncProgressState build() => SyncProgressState();

  void start(String status) {
    state = SyncProgressState(isSyncing: true, status: status);
    NotificationService().showProgressNotification(
      id: _notificationId,
      title: 'Syncing',
      body: status,
      progress: 0,
      maxProgress: 100,
    );
  }

  void updateProgress(int done, int total) {
    state = SyncProgressState(
      isSyncing: true,
      status: state.status,
      done: done,
      total: total,
    );
    if (total > 0) {
      NotificationService().showProgressNotification(
        id: _notificationId,
        title: 'Syncing',
        body: state.status ?? 'Working...',
        progress: done,
        maxProgress: total,
      );
    }
  }

  void complete(String successMsg) {
    state = SyncProgressState(status: successMsg, isComplete: true);
    NotificationService().showSuccessNotification(
      id: _notificationId,
      title: 'Sync Complete',
      body: successMsg,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (state.isComplete) {
        state = SyncProgressState(); // Clear local state
      }
    });
  }

  void error(String errorMsg) {
    state = SyncProgressState(status: errorMsg, isError: true);
    NotificationService().showErrorNotification(
      id: _notificationId,
      title: 'Sync Error',
      body: errorMsg,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (state.isError) {
        state = SyncProgressState(); // Clear local state
      }
    });
  }
}

final syncProgressProvider =
    NotifierProvider<SyncProgressNotifier, SyncProgressState>(
      SyncProgressNotifier.new,
    );

/// Riverpod provider — singleton for the app lifetime.
final driveSyncServiceProvider = Provider<DriveSyncService>((ref) {
  return DriveSyncService(ref);
});
