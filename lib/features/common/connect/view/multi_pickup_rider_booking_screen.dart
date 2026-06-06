import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Static multi-pickup ride booking screen — visually mirrors
/// [ProductOrderBookingRiderMain] but shows MULTIPLE pickup locations (the
/// selected inquiry orders) and the single, already-chosen drop location.
///
/// The pickups are presented farthest-from-drop first (index 0 = farthest), so
/// the rider's route collects from the farthest shop and ends nearest the drop.
///
/// UI only — no API calls / no rider search is performed here.
class MultiPickupRiderBookingScreen extends StatefulWidget {
  const MultiPickupRiderBookingScreen({
    super.key,
    required this.pickups,
    required this.dropAddress,
  });

  /// Selected inquiry conversations, used as pickup points (ordered
  /// farthest-from-drop first).
  final List<ChatList> pickups;

  /// The already-selected drop location.
  final SavedAddress dropAddress;

  @override
  State<MultiPickupRiderBookingScreen> createState() =>
      _MultiPickupRiderBookingScreenState();
}

class _MultiPickupRiderBookingScreenState
    extends State<MultiPickupRiderBookingScreen> {
  int _selectedVehicle = 0;

  // In-City vehicle choices (static — same set as the transport flow).
  final List<_VehicleOption> _vehicles = [
    _VehicleOption(AppStrings.transportBike.tr, AppIconAssets.transport_bike),
    _VehicleOption(AppStrings.transportTaxi.tr, AppIconAssets.transport_taxi),
    _VehicleOption(AppStrings.transportAuto.tr, AppIconAssets.transport_auto),
    _VehicleOption(
        AppStrings.transportERickshaw.tr, AppIconAssets.transport_big_auto),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: 'Book Rider'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: CustomBtn(
            height: 44,
            // UI-only screen — no rider API. Surface a placeholder action.
            onTap: () => commonSnackBar(message: 'Coming soon....'),
            title: AppStrings.callToRider.tr,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                /// Route card — multiple pickups + single drop.
                _buildRouteCard(),

                const SizedBox(height: 16),

                /// Vehicle options (In City).
                _buildVehicleOptions(),

                SizedBox(height: SizeConfig.size16),
                CustomText(AppStrings.chooseYourRider.tr,
                    fontSize: 16, fontWeight: FontWeight.w600),
                SizedBox(height: SizeConfig.size12),

                /// Static rider placeholder cards.
                _buildRiderPlaceholders(),

                SizedBox(height: SizeConfig.size30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppShadows.bottomShadow],
        color: AppColors.white,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route,
                  size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              CustomText(
                '${widget.pickups.length} pickup${widget.pickups.length == 1 ? '' : 's'} • 1 drop',
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup points (index 0 = farthest from drop).
          ...List.generate(widget.pickups.length, (i) {
            final chat = widget.pickups[i];
            return _routeStop(
              index: i + 1,
              isLast: false,
              title: chat.sender?.name ?? 'Pickup ${i + 1}',
              subtitle: i == 0
                  ? 'Farthest pickup'
                  : 'Pickup point ${i + 1}',
              dotColor: AppColors.primaryColor,
              highlight: i == 0,
            );
          }),

          // Drop point.
          _routeStop(
            index: null,
            isLast: true,
            title: widget.dropAddress.label.isNotEmpty
                ? widget.dropAddress.label
                : 'Drop location',
            subtitle: widget.dropAddress.fullAddress,
            dotColor: AppColors.red00,
            highlight: false,
          ),
        ],
      ),
    );
  }

  /// One stop in the route column. A numbered/coloured dot with a connecting
  /// line (omitted for [isLast]) beside the stop's title + subtitle.
  Widget _routeStop({
    required int? index,
    required bool isLast,
    required String title,
    required String subtitle,
    required Color dotColor,
    required bool highlight,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: index != null
                    ? CustomText(
                        '$index',
                        fontSize: SizeConfig.size11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )
                    : const Icon(Icons.location_on,
                        size: 14, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.whiteE5,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (highlight)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            'Start',
                            fontSize: SizeConfig.size10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOptions() {
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedVehicle == i;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedVehicle = i),
            child: Container(
              height: 82,
              width: 86,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.whiteE5),
                boxShadow: AppShadows.lightBottomShadow,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryColor.withValues(alpha: 0.0),
                          AppColors.primaryColor.withValues(alpha: 0.2),
                        ],
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: LocalAssets(imagePath: _vehicles[i].svgImage)),
                  const SizedBox(height: 6),
                  CustomText(
                    _vehicles[i].name,
                    textAlign: TextAlign.center,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiderPlaceholders() {
    return Column(
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.lightBottomShadow,
            color: AppColors.white,
            border: Border.all(color: AppColors.whiteE5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.person,
                    color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Rider ${i + 1}',
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      _vehicles[_selectedVehicle].name,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.radio_button_unchecked,
                  color: Colors.grey, size: 22),
            ],
          ),
        );
      }),
    );
  }
}

class _VehicleOption {
  final String name;
  final String svgImage;

  _VehicleOption(this.name, this.svgImage);
}
