import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PropertyListingCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isOwner;
  final VoidCallback? onDeleted;

  const PropertyListingCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isOwner = false,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final images = property.propertyImages;
    final location = property.displayLocation;
    final highlights = _buildHighlights();
    final radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    images.isNotEmpty
                        ? Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    if (isOwner)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => _showMenu(context),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.mainTextColor
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_vert,
                                size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.mainTextColor
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            '+${images.length - 1}',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    property.propertyName,
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightYellowShade,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.yellowCB,
                            width: 0.5
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppColors.rating),
                            const SizedBox(width: 3),
                            CustomText(
                              property.rating.toStringAsFixed(1),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.geryFC,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.greyE0,
                          ),
                        ),
                        child: CustomText(
                          property.typeLabel,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _DashedLine(),
                  const SizedBox(height: 10),
                  CustomText(
                    property.formattedPrice,
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _highlightChip(
                                highlights[0].$1, highlights[0].$2)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: highlights.length > 1
                                ? _highlightChip(
                                    highlights[1].$1, highlights[1].$2)
                                : const SizedBox()),
                      ],
                    ),
                    if (highlights.length > 2) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: _highlightChip(
                                  highlights[2].$1, highlights[2].$2)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: highlights.length > 3
                                  ? _highlightChip(
                                      highlights[3].$1, highlights[3].$2)
                                  : const SizedBox()),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.geryFC,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.secondaryTextColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        location,
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _highlightChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.greyE5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.secondaryTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.holiday_village_outlined,
            size: 40,
            color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE2EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.redB4),
              title: CustomText(
                'Delete Property',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.redB4,
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          'Delete Property',
          fontSize: SizeConfig.large18,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          'Are you sure you want to delete "${property.propertyName}"? This action cannot be undone.',
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(
              'Cancel',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteProperty();
            },
            child: CustomText(
              'Delete',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.redB4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty() async {
    if (property.id == null) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final repo = PropertyRepo();
      final response = await repo.deleteProperty(property.id!);
      Get.back();

      if (response.isSuccess) {
        commonSnackBar(message: 'Property deleted successfully');
        onDeleted?.call();
      } else {
        commonSnackBar(
            message: response.message ?? 'Failed to delete property');
      }
    } catch (_) {
      Get.back();
      commonSnackBar(message: 'Something went wrong');
    }
  }

  List<(IconData, String)> _buildHighlights() {
    final result = <(IconData, String)>[];
    final ha = property.houseAndApartment;
    final lp = property.landAndPlots;
    final so = property.shopAndOffices;
    final np = property.newProjectsAndProperties;
    final pg = property.pgAndGuestHouse;

    if (ha != null) {
      if (ha.bhk != null) result.add((Icons.bed_outlined, '${ha.bhk} BHK'));
      if (ha.areaDetails != null && ha.areaDetails!.isNotEmpty) {
        result.add((Icons.square_foot, ha.areaDetails!));
      }
      if (ha.totalFloors != null) {
        result.add((Icons.layers_outlined, '${ha.totalFloors} Floors'));
      }
      if (ha.bathrooms != null) {
        result.add((Icons.bathtub_outlined, '${ha.bathrooms} Bathrooms'));
      }
    } else if (lp != null) {
      final plot = lp.plotAreaDetails;
      if (plot?.totalArea != null) {
        result.add((Icons.square_foot, plot!.totalArea!));
      }
      if (plot?.length != null) {
        result.add((Icons.straighten, 'L: ${plot!.length}'));
      }
      if (plot?.breadth != null) {
        result.add((Icons.straighten, 'B: ${plot!.breadth}'));
      }
      if (lp.facing != null) {
        result.add((Icons.explore_outlined, lp.facing!));
      }
    } else if (so != null) {
      if (so.superBuiltupArea != null) {
        result.add((Icons.square_foot, so.superBuiltupArea!));
      }
      if (so.furnishing != null) {
        result.add((Icons.chair_outlined, so.furnishing!));
      }
      if (so.washrooms != null) {
        result.add((Icons.bathtub_outlined, '${so.washrooms} Washrooms'));
      }
      if (so.carParkings != null) {
        result.add((Icons.local_parking, '${so.carParkings} Parking'));
      }
    } else if (np != null) {
      if (np.typeOfProperty != null) {
        result.add((Icons.apartment_outlined, np.typeOfProperty!));
      }
      if (np.area != null) result.add((Icons.square_foot, np.area!));
      if (np.noOfTowers != null) {
        result.add((Icons.apartment_outlined, '${np.noOfTowers} Towers'));
      }
      if (np.noOfFloors != null) {
        result.add((Icons.layers_outlined, '${np.noOfFloors} Floors'));
      }
    } else if (pg != null) {
      if (pg.subType != null) {
        result.add((Icons.home_outlined, pg.subType!));
      }
      if (pg.roomType != null) {
        result.add((Icons.meeting_room_outlined, pg.roomType!));
      }
      if (pg.furnishing != null) {
        result.add((Icons.chair_outlined, pg.furnishing!));
      }
      if (pg.mealsIncluded != null) {
        result.add((Icons.restaurant_outlined, pg.mealsIncluded!));
      }
    }
    return result;
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dw = 4.0;
        const ds = 3.0;
        final count = (constraints.maxWidth / (dw + ds)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dw,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.greyE5,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
