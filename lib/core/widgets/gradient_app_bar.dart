import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_colors.dart';

class GradientAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color accent;
  final Color? endColor;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final double elevation;
  final bool animate;

  const GradientAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.bottom,
    this.accent = AppColors.roleLO,
    this.endColor,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.animate = true,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  State<GradientAppBar> createState() => _GradientAppBarState();
}

class _GradientAppBarState extends State<GradientAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.animate) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GradientAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    } else if (!widget.animate && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  LinearGradient _gradient(double t) {
    final base = widget.endColor != null
        ? AppColors.roleHeaderGradient(widget.accent, endColor: widget.endColor)
        : AppColors.headerGradientFor(widget.accent);

    final begin = Alignment(-1.0 + t * 0.35, -1.0);
    final end = Alignment(1.0 - t * 0.25, 1.0);
    return LinearGradient(
      colors: base.colors,
      stops: base.stops,
      begin: begin,
      end: end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleWidget = widget.title ??
        (widget.titleText != null
            ? Text(widget.titleText!)
            : const SizedBox.shrink());

    final appBar = AppBar(
      title: titleWidget,
      actions: widget.actions,
      leading: widget.leading,
      bottom: widget.bottom,
      centerTitle: widget.centerTitle,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );

    Widget bar = appBar;
    if (widget.bottom is TabBar) {
      bar = Theme(
        data: Theme.of(context).copyWith(
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          ),
        ),
        child: appBar,
      );
    }

    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final t = widget.animate ? _drift.value : 0.0;
        return Material(
          elevation: widget.elevation,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(gradient: _gradient(t)),
            child: child,
          ),
        );
      },
      child: bar,
    );
  }
}

class RoleScaffoldBackground extends StatelessWidget {
  final Color accent;
  final Widget child;

  const RoleScaffoldBackground({
    super.key,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.roleScaffoldWash(accent, isDark: isDark),
      ),
      child: child,
    );
  }
}

class HeaderEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const HeaderEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 480),
    this.delay = Duration.zero,
  });

  @override
  State<HeaderEntrance> createState() => _HeaderEntranceState();
}

class _HeaderEntranceState extends State<HeaderEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
