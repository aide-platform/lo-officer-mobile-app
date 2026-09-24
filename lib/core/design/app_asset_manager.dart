import 'package:flutter/material.dart';

class AppAssetManager {
  AppAssetManager._();

  static const String logo = 'assets/images/icon.png';
  static const String aeroIndiaLogo = 'assets/images/aero-india-logo.png';
  static const String modLogoWhite = 'assets/images/mod-logo-white.png';
  static const String defaultVipAvatar = 'assets/images/aero-ind1.png';
  static const String splash = 'assets/images/mainBackground_3.png';
  static const String landingHero = 'assets/images/mainBackground_3.png';
  static const String mainBg3 = 'assets/images/mainBackground_3.png';
  static const String aeroIndiaHero = 'assets/images/aero-india-hero.png';
}

class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? fallback;

  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return fallback ??
            SizedBox(
              width: width,
              height: height,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(context).disabledColor,
                  size: (width != null && width! < 30) ? 14 : 24,
                ),
              ),
            );
      },
    );
  }
}
