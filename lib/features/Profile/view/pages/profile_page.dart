import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Profile/view/widgets/edit_profile_sheet.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Horizontal Profile Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Material(
                clipBehavior: .antiAlias,
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _option(
                      icon: LucideIcons.userPen,
                      title: "Edit Profile",
                      onTap: () {
                        showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) {
                            return EditProfileSheet(
                              initialName: user.displayName ?? "",
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white, thickness: 2),
                    _option(
                      icon: LucideIcons.settings,
                      title: "Settings",
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Material(
                clipBehavior: .antiAlias,
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _option(
                      isDestructive: true,
                      icon: LucideIcons.logOut,
                      title: "Log Out",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              elevation: 1,
                              backgroundColor: Colors.white,
                              title: const Text(
                                "Log out",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              content: const Text(
                                "Are you sure you want to log out of your account?",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              actionsPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black54,
                                    textStyle: const TextStyle(
                                      fontFamily: "manrope",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .signOut();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    "Logout",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _option({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  const destructiveColor = Color(0xFFDC2626);

  return ListTile(
    onTap: onTap,
    contentPadding: const .symmetric(horizontal: 24, vertical: 0),
    leading: Icon(
      icon,
      size: 22,
      color: isDestructive ? destructiveColor : Colors.black,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: isDestructive ? destructiveColor : Colors.black,
        fontWeight: .w600,
        letterSpacing: 0
      ),
    ),
  );
}
