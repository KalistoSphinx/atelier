import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tracks which local files have been synced to Google Drive and their
/// corresponding Drive file IDs. Avoids expensive Drive API lookups.
class SyncManifest {
  String? rootFolderId;
  String? booksFolderId;
  String? coversFolderId;
  Map<String, String> files; // relativePath → driveFileId

  SyncManifest({
    this.rootFolderId,
    this.booksFolderId,
    this.coversFolderId,
    Map<String, String>? files,
  }) : files = files ?? {};

  static File? _file;

  static Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, 'sync_manifest.json'));
    return _file!;
  }

  /// Load the manifest from disk. Returns empty manifest if none exists.
  static Future<SyncManifest> load() async {
    final file = await _getFile();
    if (!await file.exists()) return SyncManifest();

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return SyncManifest(
        rootFolderId: json['rootFolderId'] as String?,
        booksFolderId: json['booksFolderId'] as String?,
        coversFolderId: json['coversFolderId'] as String?,
        files: (json['files'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
      );
    } catch (e) {
      log('SyncManifest: Error loading: $e');
      return SyncManifest();
    }
  }

  /// Persist the manifest to disk using atomic write.
  Future<void> save() async {
    final file = await _getFile();
    final data = {
      if (rootFolderId != null) 'rootFolderId': rootFolderId,
      if (booksFolderId != null) 'booksFolderId': booksFolderId,
      if (coversFolderId != null) 'coversFolderId': coversFolderId,
      'files': files,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonString, flush: true);
    await tempFile.rename(file.path);
  }

  /// Delete the manifest file and reset all state.
  Future<void> clear() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
    rootFolderId = null;
    booksFolderId = null;
    coversFolderId = null;
    files.clear();
  }
}
