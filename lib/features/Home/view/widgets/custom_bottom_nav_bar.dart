import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {

  double? dragOffset;
  bool isDragging = false;

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

                double currentLeft = isDragging ? dragOffset! : (itemWidth * widget.currentIndex);

                return GestureDetector(
                  onHorizontalDragDown: (details) {
                    int touchedIndex = (details.localPosition.dx / itemWidth).floor().clamp(0, 1);
                    
                    if (touchedIndex != widget.currentIndex) {
                      widget.onTap(touchedIndex);
                    }
                  },
                  onHorizontalDragStart: (details) {
                    setState((){
                      isDragging = true;
                      dragOffset = currentLeft;
                    });
                  },
                  onHorizontalDragUpdate: (details){
                    setState(() {
                      isDragging = true;
                      dragOffset = (dragOffset! + details.delta.dx).clamp(0, itemWidth);
                    });
                  },
                  onHorizontalDragEnd: (details){
                    setState((){
                      isDragging = false;
                      int nearestIndex = (dragOffset! / itemWidth).round();
                      nearestIndex = nearestIndex.clamp(0, 1);

                      dragOffset = null;
                      
                      if (nearestIndex != widget.currentIndex) {
                        widget.onTap(nearestIndex);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        top: 0,
                        bottom: 0,
                        left: currentLeft,
                        duration: isDragging ? const Duration(milliseconds: 100) : const Duration(milliseconds: 250),
                        curve: isDragging ? Curves.easeOutQuad : Curves.easeInOut,
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
                              
                              onTap: () => widget.onTap(0),
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
                              
                              onTap: () => widget.onTap(1),
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
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
