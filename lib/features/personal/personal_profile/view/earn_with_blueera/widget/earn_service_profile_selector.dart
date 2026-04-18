import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class EarnServiceProfileSelector extends StatelessWidget {
  final List<String> profileImages;
  final int selectedIndex;
  final ValueChanged<int> onProfileSelected;
  final List<String>? profileNames;

  /// When true, renders a frosted glass pill suitable for placement on top
  /// of a cover image — overlapping avatars + the current profile name +
  /// a chevron, all in white. Use the default style elsewhere.
  final bool onCoverOverlay;

  const EarnServiceProfileSelector({
    super.key,
    required this.profileImages,
    required this.selectedIndex,
    required this.onProfileSelected,
    this.profileNames,
    this.onCoverOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onCoverOverlay) return _buildOverlayPill(context);
    return _buildDefault(context);
  }

  // ── Default (compact avatars + chevron) ─────────────────
  Widget _buildDefault(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProfilePicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverlappingAvatars(
            size: 32,
            overlap: 12,
            borderColor: AppColors.mainTextColor,
          ),
          SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.mainTextColor,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ── Cover Overlay (frosted pill) ────────────────────────
  Widget _buildOverlayPill(BuildContext context) {
    final currentName = (profileNames != null &&
            selectedIndex >= 0 &&
            selectedIndex < profileNames!.length)
        ? profileNames![selectedIndex]
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProfilePicker(context),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(4, 4, 10, 4),
              constraints: const BoxConstraints(maxWidth: 180),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlappingAvatars(
                    size: 26,
                    overlap: 10,
                    borderColor: Colors.white,
                  ),
                  if (currentName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        currentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatars({
    required double size,
    required double overlap,
    required Color borderColor,
  }) {
    final count = profileImages.length.clamp(0, 3);
    if (count == 0) return const SizedBox.shrink();

    final double totalWidth = size + (count - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: _circleAvatar(profileImages[i], size, borderColor),
          );
        }),
      ),
    );
  }

  Widget _circleAvatar(String? url, double size, Color borderColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.person, size: size / 2),
              )
            : Icon(Icons.person, size: size / 2),
      ),
    );
  }

  void _showProfilePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyE5,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Switch Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which profile you want to view.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 18),
                ...List.generate(profileImages.length, (i) {
                  final isSelected = i == selectedIndex;
                  final name =
                      (profileNames != null && i < profileNames!.length)
                          ? profileNames![i]
                          : 'Profile ${i + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProfileOption(
                      context: sheetCtx,
                      index: i,
                      name: name,
                      isSelected: isSelected,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required int index,
    required String name,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) onProfileSelected(index);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSelected ? AppColors.primaryColor : AppColors.greyE5,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _circleAvatar(profileImages[index], 46, AppColors.greyE5),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected ? 'Current profile' : 'Tap to switch',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.greyE5,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
