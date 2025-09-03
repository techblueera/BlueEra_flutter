import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlockPostModalSheet extends StatefulWidget {
  const BlockPostModalSheet({
    super.key,
    required this.reportType,
    required this.otherUserId,
    required this.contentId,
    required this.userBlockVoidCallback,
    required this.reportCallback
  });

  final String reportType;
  final String otherUserId;
  final String contentId;
  final VoidCallback userBlockVoidCallback;
  final Function(Map<String, dynamic>) reportCallback;

  @override
  State<BlockPostModalSheet> createState() => _BlockPostModalSheetState();
}

class _BlockPostModalSheetState extends State<BlockPostModalSheet> {
  final LayerLink _layerLink = LayerLink(); // To link the target and follower
  final LayerLink _layerLink2 = LayerLink(); // To link the target and follower

  OverlayEntry? _overlayEntry;
  OverlayEntry? _overlayEntry2; // To store the overlay entry

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    AppLocalizations.of(context)!.blockUser,
                    fontSize: SizeConfig.extraLarge22,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Get.back();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      backgroundColor: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Material(
                          color: AppColors.white,
                          child: ReportDialog(
                              reportType: widget.reportType,
                              reportReasons: {
                                AppLocalizations.of(context)!.inappropriateContent: false,
                                AppLocalizations.of(context)!.promotesHatredViolence: false,
                                AppLocalizations.of(context)!.fraudOrScam: false,
                                AppLocalizations.of(context)!.contentIsSpam: false,
                              },
                              contentId: widget.contentId,
                              otherUserId: widget.otherUserId,
                              reportCallback: (params)=> widget.reportCallback(params),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      'Report',
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CompositedTransformTarget(
                    link: _layerLink, // Linking the position of the info icon
                    child: IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: AppColors.black28
                      ),
                      onPressed: () {
                        if (_overlayEntry == null) {
                          _showPartialBlockOverlay(context);
                          _removeFullyBlockOverlay();
                        } else {
                          _removePartialBlockOverlay();
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.userBlockVoidCallback();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      'User Block',
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  CompositedTransformTarget(
                    link:
                    _layerLink2, // Linking the position of the info icon
                    child: IconButton(
                      icon: const Icon(Icons.info_outline,
                          color: AppColors.black28
                      ),
                      onPressed: () {
                        if (_overlayEntry2 == null) {
                          _showFullyBlockOverlay(context);
                          _removePartialBlockOverlay();
                        } else {
                          _removeFullyBlockOverlay();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  // Function to display the overlay
  void _showPartialBlockOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: SizeConfig.screenWidth * 0.8,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(-SizeConfig.screenWidth * 0.72, -110), // Adjust position of the overlay
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.7), // Black background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reported posts are reviewed by BlueEra. Repeated violations may lead to account restrictions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16), // White text
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Function to remove the overlay
  void _removePartialBlockOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Function to display the overlay
  void _showFullyBlockOverlay(BuildContext context) {
    _overlayEntry2 = OverlayEntry(
      builder: (context) => Positioned(
        width: SizeConfig.screenWidth * 0.8,
        child: CompositedTransformFollower(
          link: _layerLink2,
          offset: Offset(-SizeConfig.screenWidth * 0.72, -160), // Adjust position of the overlay
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.7), // Black background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reported posts are reviewed by BlueEra. When you block someone, you won’t see their posts, and their posts will be removed from feed.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16), // White text
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry2!);
  }

  // Function to remove the overlay
  void _removeFullyBlockOverlay() {
    _overlayEntry2?.remove();
    _overlayEntry2 = null;
  }
}
