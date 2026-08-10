import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image that walks an ordered list of candidate [urls] — the first
/// non-empty one is tried, and on load-error it falls through to the next, then
/// to a local placeholder.
///
/// Product cards use it so a missing or broken variant image falls back to the
/// product image (and, if that's broken too, a sibling variant's) instead of
/// dropping straight to a placeholder.
///
/// Module-neutral on purpose: it started life inside the grocery card, which
/// meant a pharmacy screen had to import a `Grocery*` widget to show a picture.
/// `GroceryFallbackImage` still exists as a thin alias so grocery's call sites
/// are untouched.
class FallbackNetworkImage extends StatelessWidget {
  final List<String?> urls;
  final BoxFit fit;

  const FallbackNetworkImage({
    super.key,
    required this.urls,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Keep non-empty, de-duped urls in order.
    final seen = <String>{};
    final candidates = <String>[];
    for (final u in urls) {
      final t = (u ?? '').trim();
      if (t.isNotEmpty && seen.add(t)) candidates.add(t);
    }
    return _build(candidates, 0);
  }

  Widget _build(List<String> candidates, int index) {
    if (index >= candidates.length) return _placeholder();
    return CachedNetworkImage(
      imageUrl: candidates[index],
      fit: fit,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => _build(candidates, index + 1),
    );
  }

  // Placeholder fills the box (cover) regardless of [fit], so the fallback
  // image doesn't get letterboxed with left/right padding.
  Widget _placeholder() => LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
      );
}
