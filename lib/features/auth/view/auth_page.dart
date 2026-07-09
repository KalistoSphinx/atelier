import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_app/features/auth/viewmodel/auth_providers.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const green = Color(0xFF2F8F82);

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Image.asset('assets/images/hero.png', height: size.height * 0.43, width: .infinity, ),
        
             SizedBox(height: size.height * 0.03),
        
            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 36),
                child: SizedBox(
                  width: .infinity,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        crossAxisAlignment: .center,
                        spacing: 10,
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            height: 35,
                            width: 35,
                          ),
                          const Text(
                            "Atelier",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: .w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Every photo deserves ',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.8,
                              ),
                            ),
                            TextSpan(
                              text: 'perfection.',
                              style: TextStyle(
                                color: green,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Opacity(
                        opacity: 0.8,
                        child: Text(
                          'Capture your memories and transform them into timeless masterpieces.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.36,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: .circular(14),
                            ),
                            side: BorderSide(
                              color: Colors.blueGrey.shade100,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: .center,
                            spacing: 18,
                            children: [
                              SvgPicture.asset(
                                'assets/images/google.svg',
                                height: 20,
                                width: 20,
                              ),
                              const Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  fontWeight: .bold,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 18),
                      
                      const Align(
                        alignment: .center,
                        child: Text(
                          "By continuing, you agree to our Terms of Use\nand Privacy Policy",
                          textAlign: .center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: .w500,
                            height: 1.45,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20,)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
