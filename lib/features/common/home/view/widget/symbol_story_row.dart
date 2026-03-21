import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_fullscreen_viewer.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SymbolStoryRow extends StatelessWidget {
  const SymbolStoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SymbolFeedController>()
        ? Get.find<SymbolFeedController>()
        : Get.put(SymbolFeedController());

    return Obx(() {
      if (controller.isLoading.value && controller.symbols.isEmpty) {
        return const SizedBox.shrink();
      }
      if (controller.symbols.isEmpty) return const SizedBox.shrink();

      /// Collect embeddedUrl stories for link preview
      final linkStories = controller.symbols
          .where((s) =>
              s.type == 'embeddedUrl' &&
              s.content != null &&
              s.content!.isNotEmpty)
          .toList();

      return Column(
        children: [
          /// Story circles row
          Container(
            margin: EdgeInsets.only(top: 10, right: 10, left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.symbols.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _SymbolStoryItem(
                  symbol: controller.symbols[index],
                  onTap: () =>
                      _openFullscreen(context, controller.symbols, index),
                );
              },
            ),
          ),

          // /// Link preview cards for embeddedUrl stories
          // if (linkStories.isNotEmpty)
          //   Container(
          //     margin: EdgeInsets.only(top: 8, right: 10, left: 10),
          //     child: Column(
          //       children: linkStories
          //           .take(3)
          //           .map((story) => _SymbolLinkPreviewCard(symbol: story))
          //           .toList(),
          //     ),
          //   ),
        ],
      );
    });
  }

  void _openFullscreen(
      BuildContext context, List<SymbolFeedItem> symbols, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SymbolFullscreenViewer(
          symbols: symbols,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// Link preview card shown outside the story row
class _SymbolLinkPreviewCard extends StatelessWidget {
  final SymbolFeedItem symbol;

  const _SymbolLinkPreviewCard({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final link = symbol.content!;
    final userName = symbol.user?.name ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// User info header
          if (userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          userName,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (symbol.caption != null &&
                            symbol.caption!.isNotEmpty)
                          CustomText(
                            symbol.caption!,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          /// Link preview
          ClipRRect(
            borderRadius: userName.isNotEmpty
                ? const BorderRadius.vertical(bottom: Radius.circular(14))
                : BorderRadius.circular(14),
            child: AnyLinkPreview.builder(
              link: link,
              cache: const Duration(days: 7),
              placeholderWidget: _buildPlaceholder(link),
              errorWidget: _buildErrorPreview(link),
              itemBuilder: (context, metadata, imageProvider, svgImage) {
                return GestureDetector(
                  onTap: () => _launchLink(link),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageProvider != null)
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child:
                              Image(image: imageProvider, fit: BoxFit.cover),
                        )
                      else if (svgImage != null)
                        SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: svgImage),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (metadata.title != null &&
                                metadata.title!.isNotEmpty)
                              CustomText(
                                metadata.title!,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mainTextColor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (metadata.desc != null &&
                                metadata.desc!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              CustomText(
                                metadata.desc!,
                                fontSize: SizeConfig.extraSmall,
                                color: AppColors.secondaryTextColor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.link,
                                    size: 14,
                                    color: AppColors.secondaryTextColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: CustomText(
                                    Uri.tryParse(link)?.host ?? link,
                                    fontSize: SizeConfig.extraSmall,
                                    color: AppColors.primaryColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final profileImage = symbol.user?.profileImage;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: ClipOval(
        child: (profileImage != null && profileImage.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: profileImage,
                fit: BoxFit.cover,
                placeholder: (_, __) => _defaultAvatar(),
                errorWidget: (_, __, ___) => _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, color: Colors.grey[400], size: 18),
    );
  }

  Widget _buildPlaceholder(String link) {
    return GestureDetector(
      onTap: () => _launchLink(link),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                Uri.tryParse(link)?.host ?? link,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPreview(String link) {
    return GestureDetector(
      onTap: () => _launchLink(link),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_rounded,
                  color: AppColors.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'Open Link',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    Uri.tryParse(link)?.host ?? link,
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new,
                size: 18, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Future<void> _launchLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SymbolStoryItem extends StatelessWidget {
  final SymbolFeedItem symbol;
  final VoidCallback onTap;

  const _SymbolStoryItem({required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasSeen = symbol.hasSeen ?? false;
    final String? profileImage = symbol.user?.profileImage;
    final String name = symbol.user?.name ?? 'User';
    final String displayName =
        name.length > 10 ? '${name.substring(0, 10)}.' : name;
    final bool isLink = symbol.type == 'embeddedUrl';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasSeen
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFF00C853),
                              Color(0xFF0085FE),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: hasSeen
                        ? Border.all(color: AppColors.greyE5, width: 2)
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child:
                          (profileImage != null && profileImage.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: profileImage,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person,
                                        color: Colors.grey[400], size: 28),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person,
                                        color: Colors.grey[400], size: 28),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.person,
                                      color: Colors.grey[400], size: 28),
                                ),
                    ),
                  ),
                ),

                /// Link badge on story circle
                if (isLink)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.link,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            CustomText(
              displayName,
              fontSize: SizeConfig.extraSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
