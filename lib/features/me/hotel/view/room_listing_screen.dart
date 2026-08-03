import 'package:BlueEra/core/api/model/hotel_room_listing_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/create_room_details_sccreen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lists every room of a given [roomType] for the hotel, with a per-row
/// image carousel, price, bed type / occupancy, and a delete action.
class RoomListingScreen extends StatefulWidget {
  final String roomType;
  final String roomName;

  const RoomListingScreen({
    super.key,
    required this.roomType,
    required this.roomName,
  });

  @override
  State<RoomListingScreen> createState() => _RoomListingScreenState();
}

class _RoomListingScreenState extends State<RoomListingScreen> {
  final controller = Get.put(RoomDetailController());

  @override
  void initState() {
    super.initState();
    // Defer to the next frame: getHotelRoomDetails flips `isLoading` synchronously,
    // and an ancestor Obx (this route was pushed mid-build from the Overview tab)
    // would otherwise be marked dirty during its own build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.getHotelRoomDetails(roomTYPE: widget.roomType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: widget.roomName),
      bottomNavigationBar: SafeArea(child: _buildAddMoreButton()),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wider screens get more horizontal padding.
            final horizontalPadding =
                constraints.maxWidth > 600 ? constraints.maxWidth * 0.2 : 16.0;

            return Obx(() {
              if (controller.hotelRoomDataList.isEmpty) {
                return Center(
                  child: CustomText(AppStrings.hotelNoRoomsCreate.tr),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 16),
                itemCount: controller.hotelRoomDataList.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RoomCard(
                    room: controller.hotelRoomDataList[index],
                    onDelete: _confirmDeleteRoom,
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRoom(HotelRoomData room) {
    return showCommonDialog(
      context: context,
      text: AppStrings.areYouSureDelete.tr,
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
      confirmCallback: () async {
        Get.back();
        await controller.deleteHotelRoomController(
          hotelRoomId: room.id ?? '',
          hotelRoomType: room.type ?? '',
        );
      },
      cancelCallback: Get.back,
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      width: double.infinity,
      color: Colors.white,
      child: OutlinedButton.icon(
        onPressed: () => Get.to(RoomDesignScreen(
          roomType: widget.roomType,
          roomName: widget.roomName,
        )),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: CustomText(AppStrings.addMore.tr, fontWeight: FontWeight.w600),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: const BorderSide(color: AppColors.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// A single room row with its own carousel index. Extracted to a stateful
/// sub-widget so each card owns its page state — the previous implementation
/// allocated a fresh `RxInt` on every parent rebuild, leaking observers.
class _RoomCard extends StatefulWidget {
  final HotelRoomData room;
  final Future<void> Function(HotelRoomData room) onDelete;

  const _RoomCard({required this.room, required this.onDelete});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  int _currentImageIndex = 0;

  List<String> get _images =>
      List<String>.from(widget.room.images?.exteriorImages ?? const []);

  @override
  Widget build(BuildContext context) {
    final images = _images;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCarouselSection(images),
          _buildBodySection(),
        ],
      ),
    );
  }

  Widget _buildCarouselSection(List<String> images) {
    return Stack(
      children: [
        InkWell(
          onTap: () => navigatePushTo(
            context,
            ImageViewScreen(
              subTitle: widget.room.name,
              appBarTitle: AppStrings.imageViewer,
              imageUrls: images,
              initialIndex: _currentImageIndex,
            ),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 220,
                viewportFraction: 1.0,
                enableInfiniteScroll: images.length > 1,
                scrollPhysics: images.length > 1
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                onPageChanged: (index, _) =>
                    setState(() => _currentImageIndex = index),
              ),
              items: images.map(_buildCarouselImage).toList(),
            ),
          ),
        ),
        if (images.length > 1) _buildIndicators(images.length),
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildCarouselImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildIndicators(int count) {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          return Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white
                  .withValues(alpha: _currentImageIndex == i ? 1.0 : 0.4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') widget.onDelete(widget.room);
        },
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          radius: 16,
          child:
              const Icon(Icons.more_vert, color: Colors.white, size: 18),
        ),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 20, color: Colors.red),
                const SizedBox(width: 10),
                CustomText(AppStrings.delete.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    final room = widget.room;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            room.name,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(
              text: '₹${formatNumber(int.tryParse(room.pricePerDay?.toString() ?? '') ?? 0)}',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const TextSpan(
              text: '/day',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ])),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: _amenityIcon(AppIconAssets.bad, room.bedType ?? ''),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: _amenityIcon(
                    AppIconAssets.occupancy, room.maxOccupancy.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amenityIcon(String icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(imagePath: icon),
        const SizedBox(width: 8),
        Flexible(
          child: CustomText(label, color: AppColors.secondaryTextColor),
        ),
      ],
    );
  }
}
