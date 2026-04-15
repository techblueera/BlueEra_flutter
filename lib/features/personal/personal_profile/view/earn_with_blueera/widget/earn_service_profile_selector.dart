import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class EarnServiceProfileSelector extends StatelessWidget {
  final List<String> profileImages;
  final int selectedIndex;
  final ValueChanged<int> onProfileSelected;
  final VoidCallback onAddTap;
  final List<String>? profileNames;

  const EarnServiceProfileSelector({
    super.key,
    required this.profileImages,
    required this.selectedIndex,
    required this.onProfileSelected,
    required this.onAddTap,
    this.profileNames,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProfilePicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverlappingAvatars(),
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

  Widget _buildOverlappingAvatars() {
    final count = profileImages.length.clamp(0, 3);
    if (count == 0) return SizedBox.shrink();

    const double size = 32;
    const double overlap = 12;
    final double totalWidth = size + (count - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: _circleAvatar(profileImages[i], size),
          );
        }),
      ),
    );
  }

  Widget _circleAvatar(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: Border.all(color: AppColors.mainTextColor, width: 1.5),
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
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            ...List.generate(profileImages.length, (i) {
              final isSelected = i == selectedIndex;
              final name = (profileNames != null && i < profileNames!.length)
                  ? profileNames![i]
                  : 'Profile ${i + 1}';
              return ListTile(
                leading: _circleAvatar(profileImages[i], 40),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.mainTextColor,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle,
                        color: AppColors.primaryColor, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onProfileSelected(i);
                },
              );
            }),
            SizedBox(height: SizeConfig.size16),
          ],
        ),
      ),
    );
  }
}
