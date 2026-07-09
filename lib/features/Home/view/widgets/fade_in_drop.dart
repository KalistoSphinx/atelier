import 'package:flutter/material.dart';

class FadeInDrop extends StatefulWidget {
  final Widget child;
  final int delayInMilliseconds;

  const FadeInDrop({
    super.key,
    required this.child,
    this.delayInMilliseconds = 0,
  });

  @override
  State<FadeInDrop> createState() => _FadeInDropState();
}

class _FadeInDropState extends State<FadeInDrop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delayInMilliseconds == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
