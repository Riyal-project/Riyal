import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Renders a subscription/bill/person-role "logo" tile: a real image asset
/// (SVG or raster) on a white backing, or — when there's no photo, as for
/// most utility providers and every person role — a colored circle with a
/// Material icon instead.
class LogoImage extends StatelessWidget {
  const LogoImage({
    super.key,
    this.assetPath,
    this.icon,
    this.iconColor,
    this.size = 44,
    this.radius,
  });

  /// Per-logo zoom (matched against the asset path) to correct artwork that
  /// under- or over-fills its tile: > 1 zooms in, < 1 pulls back.
  static const _logoScale = <String, double>{
    'apple-tv': 1.35,
    'disney': 1.25,
    'amazon-prime': 1.35,
    'twitch': 1.25,
    'noon': 1.3,
    'osn-logo': 1.3,
    'starzplay': 1.3,
    'playstation': 1.25,
    '/x.png': 1.25,
    'char ai': 1.25,
    'canva': 1.12,
    'grammarly': 0.78,
    'microsoft365': 0.78,
    'onedrive': 0.92,
    'slack': 0.92,
    'asana': 0.92,
    'ticktick': 0.9,
    'evernote': 0.9,
    'notion': 0.9,
    'github-copilot': 0.9,
    'github_logo': 0.92,
    'midjourney': 0.9,
    'gemini': 0.92,
  };

  final String? assetPath;
  final IconData? icon;
  final Color? iconColor;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * 0.28),
        child: Container(
          width: size,
          height: size,
          color: iconColor ?? AppColors.trackBackground,
          child: Icon(
            icon ?? Icons.apps_rounded,
            color: AppColors.textPrimary,
            size: size * 0.52,
          ),
        ),
      );
    }

    final lower = path.toLowerCase();
    final scale = _logoScale.entries
        .firstWhere(
          (e) => lower.contains(e.key),
          orElse: () => const MapEntry('', 1.0),
        )
        .value;
    final raw = lower.endsWith('.svg')
        ? SvgPicture.asset(
            path,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _fallbackIcon(),
          )
        : Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
          );
    final content = scale == 1.0 ? raw : Transform.scale(scale: scale, child: raw);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: content,
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Icon(Icons.apps_rounded, color: AppColors.trackBackground);
  }
}
