import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_app/core/services/drive_sync_service.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';
import 'package:image_app/features/auth/viewmodel/google_drive_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSyncEnabled = false;
  bool _isVerticalMode = true;
  final GlobalKey<PopupMenuButtonState<bool>> _readingModeMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPrefsServiceProvider);
    _isSyncEnabled = prefs.isSyncEnabled;
    _isVerticalMode = prefs.isVerticalReadingMode;
  }

  void _toggleSync(bool value) {
    setState(() => _isSyncEnabled = value);
    ref.read(sharedPrefsServiceProvider).setSyncEnabled(value);
    if (value) {
      _doBackupNow();
    }
  }

  Future<void> _doBackupNow() async {
    final syncState = ref.read(syncProgressProvider);
    if (syncState.isSyncing) return;
    await ref.read(driveSyncServiceProvider).backupNow();
  }

  Future<void> _doLoadFromDrive() async {
    final syncState = ref.read(syncProgressProvider);
    if (syncState.isSyncing) return;
    await ref.read(driveSyncServiceProvider).loadFromDrive();
  }

  @override
  Widget build(BuildContext context) {
    final drive = ref.watch(googleDriveProvider);
    final notifier = ref.read(googleDriveProvider.notifier);
    final isConnected = drive.value != null;
    final isSyncing = ref.watch(syncProgressProvider).isSyncing;

    // Auto-disable sync if Drive is disconnected
    if (!isConnected && _isSyncEnabled) {
      _isSyncEnabled = false;
      ref.read(sharedPrefsServiceProvider).setSyncEnabled(false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Storage",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  drive.when(
                    data: (email) {
                      final hasEmail = email != null;
                      return ListTile(
                        onTap: hasEmail ? notifier.disconnect : notifier.connect,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 5,
                        ),
                        leading: SvgPicture.asset(
                          'assets/images/drive.svg',
                          height: 22,
                          width: 22,
                        ),
                        title: Text(
                          hasEmail ? "Connected to" : "Connect Google Drive",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                        subtitle: hasEmail ? Text(email) : null,
                      );
                    },
                    error: (_, _) {
                      return ListTile(
                        onTap: notifier.connect,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 5,
                        ),
                        leading: SvgPicture.asset(
                          'assets/images/drive.svg',
                          height: 22,
                          width: 22,
                        ),
                        title: const Text(
                          "Could not Connect - Tap to retry",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      );
                    },
                    loading: () {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 5,
                        ),
                        leading: SvgPicture.asset(
                          'assets/images/drive.svg',
                          height: 22,
                          width: 22,
                        ),
                        trailing: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: const Text(
                          "Connect Google Drive",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white, thickness: 2),
                  ListTile(
                    onTap: () {
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please connect to Google Drive first."),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _toggleSync(!_isSyncEnabled);
                    },
                    trailing: Switch(
                      value: _isSyncEnabled,
                      onChanged: (value) {
                        if (!isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please connect to Google Drive first."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        _toggleSync(value);
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 5,
                    ),
                    leading: const Icon(Icons.cloud_outlined, size: 22, color: Colors.black),
                    subtitle: const Text("Sync all your books and progress to Google Drive automatically"),
                    title: const Text(
                      "Enable Google Drive Sync",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white, thickness: 2),
                  ListTile(
                    onTap: (!isConnected || isSyncing)
                        ? null
                        : _doBackupNow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 5,
                    ),
                    leading: Icon(LucideIcons.uploadCloud,
                        size: 22,
                        color: (!isConnected || isSyncing)
                            ? Colors.grey
                            : Colors.black),
                    title: Text(
                      "Backup Now",
                      style: TextStyle(
                        fontSize: 16,
                        color: (!isConnected || isSyncing)
                            ? Colors.grey
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: const Text("Manually push changes to Drive"),
                  ),
                  const Divider(height: 1, color: Colors.white, thickness: 2),
                  ListTile(
                    onTap: (!isConnected || isSyncing) ? null : _doLoadFromDrive,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 5,
                    ),
                    leading: Icon(LucideIcons.downloadCloud,
                        size: 22,
                        color: (!isConnected || isSyncing)
                            ? Colors.grey
                            : Colors.black),
                    title: Text(
                      "Load Books from Drive",
                      style: TextStyle(
                        fontSize: 16,
                        color: (!isConnected || isSyncing)
                            ? Colors.grey
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: const Text("Downloads missing books (Wi-Fi recommended)"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Reader",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => _readingModeMenuKey.currentState?.showButtonMenu(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 5,
                    ),
                    leading: const Icon(
                      LucideIcons.bookOpen,
                      size: 22,
                      color: Colors.black,
                    ),
                    title: const Text(
                      "Reading Mode",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: Text(_isVerticalMode ? "Vertical" : "Horizontal"),
                    trailing: PopupMenuButton<bool>(
                      constraints: const BoxConstraints(
                        minWidth: 130
                      ),
                      menuPadding: const .all(0),
                      color: Colors.white,
                      key: _readingModeMenuKey,
                      clipBehavior: Clip.antiAlias, // Clips the ripple effect to the rounded borders
                      onSelected: (bool isVertical) {
                        setState(() => _isVerticalMode = isVertical);
                        ref.read(sharedPrefsServiceProvider).setVerticalReadingMode(isVertical);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(0, 40),
                      child: const Icon(LucideIcons.chevronDown, size: 20, color: Colors.black54),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          height: 40,
                          padding: const .only(left: 20, right: 20, top: 14, bottom: 14),
                          value: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Vertical", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                              const SizedBox(width: 48), // Fixed spacing instead of spaceBetween
                              if (_isVerticalMode)
                                const Icon(LucideIcons.check, size: 18)
                              else
                                const SizedBox(width: 18),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          height: 40,
                          padding: const .only(left: 20, right: 20, bottom: 14, top: 10),
                          value: false,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Horizontal", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                              const SizedBox(width: 32), // Fixed spacing adjusted for text length difference
                              if (!_isVerticalMode)
                                const Icon(LucideIcons.check, size: 18)
                              else
                                const SizedBox(width: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
