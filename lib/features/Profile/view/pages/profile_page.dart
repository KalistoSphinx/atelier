import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Profile/view/widgets/edit_profile_sheet.dart';
import 'package:image_app/features/Profile/view/widgets/profile_option_item.dart';
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
                    backgroundImage: NetworkImage(
                      user!.photoURL!
                    ),
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
              
              // Edit Profile Option
              ProfileOptionItem(
                icon: LucideIcons.userPen,
                title: "Edit Profile",
                onTap: () {
                 showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) {
                      return EditProfileSheet(initialName: user.displayName ?? "");
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Logout Option
              ProfileOptionItem(
                icon: LucideIcons.logOut,
                title: "Logout",
                isDestructive: true,
                onTap: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
