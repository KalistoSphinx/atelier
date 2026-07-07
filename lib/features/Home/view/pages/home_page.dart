import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  const Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: .w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  CupertinoButton(
                    onPressed: () {},
                    color: CupertinoColors.systemGrey4,
                    padding: .zero,
                    borderRadius: .circular(100),
                    minimumSize: const Size(35, 35),
                    child: const Icon(Icons.add, size: 25, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const .only(bottom: 35),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Material(
              elevation: 1,
              color: Colors.white,
                borderRadius: .circular(100),
              child: Container(
                padding: const .all(6),
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
                              color: CupertinoColors.systemGrey5,
                              borderRadius: .circular(60),
                            ),
                          ),
                        ),
              
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentIndex = 0;
                                  });
                                },
                                behavior: .opaque,
                                child: const Column(
                                  mainAxisAlignment: .center,
                                  children: [
                                    Icon(
                                      Icons.home,
                                      color: Colors.black
                                    ),
                                    Text(
                                      "Home",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: .w500,
                                        letterSpacing: -0.1
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currentIndex = 1;
                                  });
                                },
                                behavior: .opaque,
                                child: const Column(
                                  mainAxisAlignment: .center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    ),
                                    Text(
                                      "Profile",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: .w500,
                                        letterSpacing: -0.1
                                      ),
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
        ),
      ),
    );
  }
}
