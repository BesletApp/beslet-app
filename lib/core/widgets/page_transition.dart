import 'package:flutter/material.dart';

class FadeTransitionPage extends Page<void> {
  final Widget child;
  final Duration duration;

  FadeTransitionPage({required this.child, required this.duration, LocalKey? key})
      : super(key: key ?? ValueKey(child));

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        const beginScale = 0.98;
        final scale = Tween<double>(begin: beginScale, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
    );
  }
}
