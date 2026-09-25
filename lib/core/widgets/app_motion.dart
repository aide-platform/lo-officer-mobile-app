import 'package:flutter/material.dart';

/// Shared motion primitives for Aero India LO.
class AppMotion {
  AppMotion._();

  static const Duration page = Duration(milliseconds: 320);
  static const Duration tab = Duration(milliseconds: 280);
  static const Duration listItem = Duration(milliseconds: 280);
  static const int listStaggerMs = 40;
  static const int listStaggerCapMs = 240;
}

/// Fade page route used for auth → shell and shell push targets.
class AppPageFadeRoute<T> extends PageRouteBuilder<T> {
  AppPageFadeRoute({required Widget page, Duration? duration})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration ?? AppMotion.page,
          reverseTransitionDuration: duration ?? AppMotion.page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Cross-fades tab bodies while keeping offscreen children mounted.
class AppTabFade extends StatelessWidget {
  const AppTabFade({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(children.isNotEmpty);
    final safeIndex = index.clamp(0, children.length - 1);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != safeIndex,
            child: AnimatedOpacity(
              opacity: i == safeIndex ? 1 : 0,
              duration: AppMotion.tab,
              curve: Curves.easeOutCubic,
              child: TickerMode(
                enabled: i == safeIndex,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}

/// Subtle press scale for primary CTAs.
class AppPressScale extends StatefulWidget {
  const AppPressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
