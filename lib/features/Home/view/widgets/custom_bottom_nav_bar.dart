import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          elevation: 1,
          color: theme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.all(6),
            height: 80,
            width: 225,
            child: LayoutBuilder(
              builder: ((context, constraints) {
                final itemWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      top: 0,
                      bottom: 0,
                      left: itemWidth * currentIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: itemWidth,
                        decoration: BoxDecoration(
                          color: theme.secondaryContainer,
                          borderRadius: BorderRadius.circular(60),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(0),
                            behavior: HitTestBehavior.opaque,
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home, color: theme.onSurface),
                                Text(
                                  "Home",
                                  style: TextStyle(
                                      color: theme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onTap(1),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, color: theme.onSurface),
                                Text(
                                  "Profile",
                                  style: TextStyle(
                                      color: theme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
