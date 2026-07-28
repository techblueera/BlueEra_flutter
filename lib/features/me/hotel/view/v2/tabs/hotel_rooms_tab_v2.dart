import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/room_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Rooms tab — surfaces the room-type chips and the horizontal room
/// list with the same Add/Edit affordances as the legacy screen.
class HotelRoomsTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelRoomsTabV2({super.key, required this.controller});

  String _formatTypeName(String type) {
    if (type.isEmpty) return '';
    final result =
        type.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          // Contribution / Bank / Refer deck. No catalog card here: this tab IS
          // the add surface and carries its own add masthead, so a card pointing
          // at the screen you are already on would be noise.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: OrderActionsCarousel(),
          ),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with Add/Edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.hotelChooseRoom.tr,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.medium,
                      ),
                      Row(
                        children: [

                          const SizedBox(width: 8),
                          _IconPill(
                            icon: Icons.add,
                            onTap: () => Get.to(RoomSelectionScreen())
                                ?.then((_) => controller.loadHotelData()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Type chips
                  Obx(() {
                    final types = controller.dynamicRoomTypes;
                    if (types.isEmpty) return const SizedBox.shrink();
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: types.map((type) {
                          final isSelected =
                              controller.selectedRoomType.value == type;
                          return GestureDetector(
                            onTap: () =>
                                controller.selectedRoomType.value = type,
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.secondaryTextColor,
                                ),
                              ),
                              child: CustomText(
                                _formatTypeName(type),
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Empty / per-type-empty / list
                  Obx(() {
                    final allRooms =
                        controller.hotelData.value?.rooms ?? <Rooms>[];
                    final filtered = controller.filteredRooms;
                    if (allRooms.isEmpty) {
                      return EmptySectionPlaceholder(
                        imageAsset: 'assets/images/other_gallery.png',
                        ctaLabel: AppStrings.hotelNoRoomsAdded.tr,
                        ctaIcon: Icons.hotel_outlined,
                        onTap: () => Get.to(RoomSelectionScreen())
                            ?.then((_) => controller.loadHotelData()),
                      );
                    }
                    if (filtered.isEmpty) {
                      return SizedBox(
                        height: 80,
                        child: Center(
                          child: CustomText(AppStrings.hotelNoRoomsForType.tr),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 310,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _RoomCard(room: filtered[i], controller: controller),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  Obx(() {
                    final hasRooms =
                        controller.hotelData.value?.rooms?.isNotEmpty ?? false;
                    if (!hasRooms) return const SizedBox.shrink();
                    return InkWell(
                      onTap: () => Get.to(RoomSelectionScreen())
                          ?.then((_) => controller.loadHotelData()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomText(
                            '${AppStrings.viewAll.tr} ',
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          Icon(Icons.arrow_right_alt,
                              color: AppColors.primaryColor),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
    );
  }
}

/// Three-dot "more" menu on each room card exposing Edit (amenities) and
/// Delete (with a confirmation prompt) actions for that specific room.
class _RoomMoreMenu extends StatelessWidget {
  final Rooms room;
  final HotelDetailController controller;
  const _RoomMoreMenu({required this.room, required this.controller});

  void _onEdit() {
    Get.to(RoomAmenitiesScreen(roomID: room.id))
        ?.then((_) => controller.loadHotelData());
  }

  void _onDelete(BuildContext context) {
    commonConformationDialog(
      context: context,
      text: AppStrings.hotelDeleteRoomConfirm.tr,
      confirmCallback: () {
        Get.back();
        controller.deleteRoom(room.id ?? "");
      },
      cancelCallback: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.black),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (value) {
          if (value == 0) {
            _onEdit();
          } else if (value == 1) {
            _onDelete(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<int>(
            value: 0,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size8),
                CustomText(AppStrings.edit.tr),
              ],
            ),
          ),
          PopupMenuItem<int>(
            value: 1,
            child: Row(
              children: [
                const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.red),
                SizedBox(width: SizeConfig.size8),
                CustomText(AppStrings.delete.tr, color: AppColors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryColor),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Rooms room;
  final HotelDetailController controller;
  const _RoomCard({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      height: 303,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [

          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                room.images?.exteriorImages?.firstOrNull ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.hotel,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  room.name ?? 'Room Name',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                CustomText(
                  '₹${room.pricePerDay}/day',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.bad, imgColor: Colors.white),
                    const SizedBox(width: 8),
                    CustomText(room.bedType ?? '', color: Colors.white),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    LocalAssets(
                        imagePath: AppIconAssets.occupancy,
                        imgColor: Colors.white),
                    const SizedBox(width: 8),
                    CustomText(
                      room.maxOccupancy ?? '',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _RoomMoreMenu(room: room, controller: controller),
          ),
        ],
      ),
    );
  }
}
