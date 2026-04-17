import 'package:flutter/material.dart';

/// 🎬 Professional Animation Utilities for LegalSync
class AnimationUtils {
  // ──────────────────────────────────────────────────────────────────
  // PAGE TRANSITIONS
  // ──────────────────────────────────────────────────────────────────

  /// Smooth fade transition between pages
  static PageRouteBuilder fadeTransition(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide from right transition
  static PageRouteBuilder slideFromRightTransition(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  /// Scale transition (grow effect)
  static PageRouteBuilder scaleTransition(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleTween = Tween(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutBack));
        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // WIDGET ANIMATIONS (Staggered Effects)
  // ──────────────────────────────────────────────────────────────────

  /// Fade-in animation for widgets
  /// [duration] defaults to 600ms if not provided
  static Widget fadeInAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Slide up + fade animation for widgets
  /// [duration] defaults to 600ms if not provided
  static Widget slideUpAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    double offset = 50.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Scale animation for widgets
  static Widget scaleAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    double begin = 0.8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: 1.0),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LIST ANIMATIONS (Stagger Effect)
  // ──────────────────────────────────────────────────────────────────

  /// Staggered animation for list items
  /// Accepts both [staggerDelay] (int ms) and [delayBetweenItems] (Duration)
  static Widget listItemAnimation({
    required Widget child,
    required int index,
    Duration baseDuration = const Duration(milliseconds: 500),
    Duration delayBetweenItems = const Duration(milliseconds: 80),
    int staggerDelay = 80, // alias in ms – whichever is provided wins
  }) {
    final delay = Duration(milliseconds: staggerDelay * index);
    return _DelayedAnimation(
      delay: delay,
      duration: baseDuration,
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // SHIMMER / LOADING ANIMATIONS
  // ──────────────────────────────────────────────────────────────────

  /// Shimmer loading animation
  static Widget shimmerAnimation({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
              stops: [value - 0.3, value, value + 0.3],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // BOUNCE ANIMATIONS
  // ──────────────────────────────────────────────────────────────────

  /// Bounce animation for attention-grabbing elements
  static Widget bounceAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // PULSE ANIMATIONS (Subtle breathing effect)
  // ──────────────────────────────────────────────────────────────────

  /// Subtle pulse/breathing animation
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// DELAYED ANIMATION (for true staggered list items)
// ──────────────────────────────────────────────────────────────────

class _DelayedAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _DelayedAnimation({
    required this.child,
    required this.delay,
    required this.duration,
  });

  @override
  State<_DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<_DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// ANIMATED TAP — micro scale press effect for buttons/cards
// ──────────────────────────────────────────────────────────────────

class AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const AnimatedTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<AnimatedTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// ANIMATED PAGE WRAPPER — wraps entire screen with entrance animation
// ──────────────────────────────────────────────────────────────────

/// 🎯 Animated Page Wrapper - For wrapping entire screens
class AnimatedPageWrapper extends StatelessWidget {
  final Widget child;
  final AnimationType animationType;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.animationType = AnimationType.fadeSlide,
  });

  @override
  Widget build(BuildContext context) {
    switch (animationType) {
      case AnimationType.fadeSlide:
        return FadeSlideTransition(child: child);
      case AnimationType.scaleRotate:
        return ScaleRotateTransition(child: child);
      case AnimationType.slideUp:
        return SlideUpTransition(child: child);
    }
  }
}

enum AnimationType { fadeSlide, scaleRotate, slideUp }

// ──────────────────────────────────────────────────────────────────
// FADE + SLIDE transition (up from slight offset)
// ──────────────────────────────────────────────────────────────────

class FadeSlideTransition extends StatefulWidget {
  final Widget child;

  const FadeSlideTransition({super.key, required this.child});

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// SCALE + ROTATE transition (used for modals/dialogs)
// ──────────────────────────────────────────────────────────────────

class ScaleRotateTransition extends StatefulWidget {
  final Widget child;

  const ScaleRotateTransition({super.key, required this.child});

  @override
  State<ScaleRotateTransition> createState() => _ScaleRotateTransitionState();
}

class _ScaleRotateTransitionState extends State<ScaleRotateTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _rotateAnimation = Tween<double>(
      begin: 0.05,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(turns: _rotateAnimation, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// SLIDE UP transition (bottom sheet style entrance)
// ──────────────────────────────────────────────────────────────────

class SlideUpTransition extends StatefulWidget {
  final Widget child;

  const SlideUpTransition({super.key, required this.child});

  @override
  State<SlideUpTransition> createState() => _SlideUpTransitionState();
}

class _SlideUpTransitionState extends State<SlideUpTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// ANIMATED CARD — entrance animation for dashboard/list cards
// ──────────────────────────────────────────────────────────────────

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.baseDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 80 * widget.index);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// ANIMATED HEADER — stagger fade+slide for page headers
// ──────────────────────────────────────────────────────────────────

class AnimatedHeader extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedHeader({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<AnimatedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// CONTINUOUS PULSE — loops forever (for loading indicators, badges)
// ──────────────────────────────────────────────────────────────────

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulsingWidget({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
