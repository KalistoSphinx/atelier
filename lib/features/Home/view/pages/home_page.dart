import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/features/Home/viewmodel/image_list_provider.dart';

import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/image_card.dart';
import '../widgets/fade_in_drop.dart';
import '../../../../features/Profile/view/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: .expand,
        children: [
          IndexedStack(
            index: currentIndex,
            children: const [_HomeContent(), ProfilePage()],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: CustomBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imageListProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .max,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      ref.read(imageListProvider.notifier).pickAndSaveImage();
                    },
                    padding: EdgeInsets.zero,
                    child: const Icon(Icons.add, size: 28, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    fontWeight: .w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.black54,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: .none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
                
              images.isEmpty
                  ? Padding(
                    padding: const .only(top: 175),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No images saved",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap + to add your first image",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 24,
                            childAspectRatio: 0.6,
                          ),
                      itemBuilder: (context, index) {
                        final File imageFile = images[index];
                        return FadeInDrop(
                          delayInMilliseconds: index * 100,
                          child: ImageCard(
                            image: imageFile,
                            imageName: "nooo",
                            date: '21 June 2026',
                          ),
                        );
                      },
                    ),
                
              const SizedBox(height: 120), // Spacer for floating bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}
