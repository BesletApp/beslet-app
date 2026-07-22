import 'package:flutter/material.dart';

class FocusSurface extends StatelessWidget {
  final Widget child;
  final double emphasis;
  final Duration fadeDuration;

  const FocusSurface({
    super.key,
    required this.child,
    this.emphasis = 1.0,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: emphasis,
      duration: fadeDuration,
      child: AnimatedScale(
        scale: 0.95 + (emphasis * 0.05),
        duration: fadeDuration,
        child: child,
      ),
    );
  }
}
