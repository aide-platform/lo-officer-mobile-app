import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';

/// The Aero India mark from [AppAssetManager.aeroIndiaLogo].
/// Scales in, then floats a few pixels.
class AeroIndiaLogo extends StatefulWidget {
  const AeroIndiaLogo({super.key, this.size = 112});

  final double size;

  @override
  State<AeroIndiaLogo> createState() => _AeroIndiaLogoState();
}

class _AeroIndiaLogoState extends State<AeroIndiaLogo>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _enter.forward().whenComplete(() {
      if (mounted) _float.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _float]),
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        final dy = -6 * Curves.easeInOut.transform(_float.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12 + dy),
            child: Transform.scale(scale: 0.82 + 0.18 * t, child: child),
          ),
        );
      },
      child: SafeAssetImage(
        assetPath: AppAssetManager.aeroIndiaLogo,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
