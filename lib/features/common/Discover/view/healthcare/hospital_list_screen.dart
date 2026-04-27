import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_address_pill.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.serviceType});
  final String serviceType;
  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  late final HospitalServiceAiController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalServiceAiController());
    controller.fetchInitial(widget.serviceType);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore(widget.serviceType);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value && controller.profiles.isEmpty) {
          // One Shimmer drives all skeleton cards. Per-card shimmers flooded
          // BLASTBufferQueue with redraws (visible as the "Already acquired
          // max frames" spam in logcat).
          return buildLoadingShimmer(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
              itemCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, __) => const _HospitalCardSkeletonBody(),
            ),
          );
        }
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "Failed to load data",
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "No hospitals found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            await controller.fetchInitial(widget.serviceType);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
            itemCount: controller.profiles.length +
                (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.profiles.length) {
                // Load-more footer: wrap a single body in one shimmer.
                return buildLoadingShimmer(
                  child: const _HospitalCardSkeletonBody(),
                );
              }
              final item = controller.profiles[index];
              return _HospitalCard(item: item);
            },
          ),
        );
      }),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalFullData item;

  const _HospitalCard({required this.item});

  bool _isEmpty(String? s) => s == null || s.trim().isEmpty;

  String _valueOr(String? s, {String fallback = "Not available"}) =>
      _isEmpty(s) ? fallback : s!.trim();

  List<String> _collectGalleryPhotos() {
    final photos = <String>[];
    if (item.gallery != null) {
      for (final g in item.gallery!) {
        if (g.uploadPhoto != null && g.uploadPhoto!.isNotEmpty) {
          photos.add(g.uploadPhoto!);
        }
        if (g.images != null) {
          photos.addAll(g.images!.where((u) => u.trim().isNotEmpty));
        }
      }
    }
    return photos;
  }

  List<String> _buildFacilities() {
    final list = <String>[];
    final ec = item.emergencyCare;
    final of = item.otherFacilities;
    if (ec?.emergencyCasualty ?? false) list.add("Emergency");
    if (ec?.traumaCare ?? false) list.add("Trauma Care");
    if (ec?.icu ?? false) list.add("ICU");
    if (ec?.ccu ?? false) list.add("CCU");
    if (ec?.nicu ?? false) list.add("NICU");
    if (ec?.picu ?? false) list.add("PICU");
    if (of?.ambulance ?? false) list.add("Ambulance");
    if (of?.bloodBank ?? false) list.add("Blood Bank");
    if (of?.diagnosticDepartments ?? false) list.add("Diagnostics");
    if (of?.medicalStore ?? false) list.add("Medical Store");
    if (of?.pmSwasthyaBimaYojana ?? false) list.add("PM Yojana");
    return list;
  }

  String? _primaryPhone() {
    final contacts = item.contacts;
    if (contacts == null || contacts.isEmpty) return null;
    for (final c in contacts) {
      final depts = c.departments;
      if (depts == null) continue;
      for (final d in depts) {
        if (!_isEmpty(d.phone)) return d.phone;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _buildFacilities();
    final departmentsCount = item.departments?.length ?? 0;
    final phone = _primaryPhone();
    final hasLogo = !_isEmpty(item.logoUrl);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      child: InkWell(
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        onTap: () {
          try {
            final controller = Get.find<HospitalServiceAiController>();
            controller.hospitalDataResModel?.value =
                HospitalFullDetailsResModel(success: true, data: item);
            Get.to(()=> DiscoverHospitalHomeScreen());
          } on Exception catch (e) {
            logs("ERROR $e");
          }
        },
        child: CommonCardWidget(
          cardMargin: 0,
          padding: SizeConfig.size12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: logo + name + address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size30),
                    child: Container(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      color: AppColors.liteWhite,
                      child: hasLogo
                          ? Image.network(
                              item.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => LocalAssets(
                                  imagePath:
                                      AppIconAssets.place_holder_image),
                            )
                          : LocalAssets(
                              imagePath: AppIconAssets.place_holder_image),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          _valueOr(item.name, fallback: "Unknown Hospital"),
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_subCategoryLabel() != null) ...[
                          SizedBox(height: SizeConfig.size6),
                          _subCategoryBadge(_subCategoryLabel()!),
                        ],
                        if (!_isEmpty(phone)) ...[
                          SizedBox(height: SizeConfig.size4),
                          Row(
                            children: [
                              Icon(Icons.call_outlined,
                                  size: SizeConfig.size14,
                                  color: AppColors.primaryColor),
                              SizedBox(width: SizeConfig.size4),
                              Expanded(
                                child: CustomText(
                                  phone!,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  DiscoverChatIcon(
                    userId: item.userId ?? '',
                    name: item.name,
                    profile: item.logoUrl,
                    businessId: item.id,
                    trackingSource: ChatClickSource.searchResult,
                  ),
                ],
              ),

              // Address & Distance Card (tappable → opens map)
              SizedBox(height: SizeConfig.size10),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _buildAddressCard(context),
              ),

              // Description — 2-line trim with "Read more" opening a dialog.
              if (!_isEmpty(item.description)) ...[
                SizedBox(height: SizeConfig.size10),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: ExpandableText(
                    text: item.description!.trim(),
                    trimLines: 2,
                    expandMode: ExpandMode.dialog,
                    dialogTitle: item.name ?? 'Hospital',
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ],

              // ─── Gallery / Cover / Logo Photo ───
              Builder(builder: (_) {
                final galleryPhotos = _collectGalleryPhotos();
                final hasCover = !_isEmpty(item.coverUrl);

                if (galleryPhotos.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size10, left: 20),
                    child: StoreLivePhotoWidget(
                      livePhotos: galleryPhotos,
                      natureOfBusiness: item.name ?? 'Hospital',
                      height: 200,
                      onViewFullScreen: ({
                        required int index,
                        required List<String> storeImage,
                        required String natureOfBusiness,
                      }) {
                        navigatePushTo(
                          context,
                          ImageViewScreen(
                            subTitle: natureOfBusiness,
                            appBarTitle: AppStrings.imageViewer,
                            imageUrls: storeImage,
                            initialIndex: index,
                          ),
                        );
                      },
                    ),
                  );
                } else if (hasCover) {
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size10, left: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () => navigatePushTo(
                          context,
                          ImageViewScreen(
                            subTitle: item.name ?? 'Hospital',
                            appBarTitle: AppStrings.imageViewer,
                            imageUrls: [item.coverUrl!],
                            initialIndex: 0,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          memCacheHeight: 600,
                          placeholder: (_, __) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.fill,
                          ),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (hasLogo) {
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size10, left: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () => navigatePushTo(
                          context,
                          ImageViewScreen(
                            subTitle: item.name ?? 'Hospital',
                            appBarTitle: AppStrings.imageViewer,
                            imageUrls: [item.logoUrl!],
                            initialIndex: 0,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.logoUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          memCacheHeight: 600,
                          placeholder: (_, __) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.fill,
                          ),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Departments — icon + label + count chip, pills underneath.
              SizedBox(height: SizeConfig.size12),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _infoSection(
                  icon: Icons.local_hospital_outlined,
                  title: 'Departments',
                  count: departmentsCount,
                  pills: (item.departments ?? [])
                      .map((d) => d.name ?? '')
                      .where((s) => s.trim().isNotEmpty)
                      .toList(),
                  emptyLabel: 'No departments listed',
                ),
              ),

              // Facilities — same pattern.
              SizedBox(height: SizeConfig.size10),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _infoSection(
                  icon: Icons.medical_services_outlined,
                  title: 'Facilities',
                  count: facilities.length,
                  pills: facilities,
                  emptyLabel: 'No facilities listed',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section block — left accent rail, icon-in-disc header with inline
  /// count, and a wrap of soft-gradient pills below. Built to read like a
  /// medical data panel rather than a generic "chips list".
  Widget _infoSection({
    required IconData icon,
    required String title,
    required int count,
    required List<String> pills,
    required String emptyLabel,
  }) {
    final accent = AppColors.primaryColor;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical accent rail — fades from solid primary at the top to
          // translucent at the bottom, anchoring the section on the left.
          Container(
            width: 3,
            margin: EdgeInsets.only(
                top: 4, bottom: 4, right: SizeConfig.size10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon-disc + title + inline count.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, size: SizeConfig.size14, color: accent),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      title,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '·',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '$count',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                // Pills / empty state.
                if (pills.isEmpty)
                  _sectionEmpty(emptyLabel)
                else
                  Wrap(
                    spacing: SizeConfig.size6,
                    runSpacing: SizeConfig.size6,
                    children: [
                      ...pills.take(4).map(_gradientChip),
                      if (pills.length > 4) _overflowChip(pills.length - 4),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Soft gradient pill used for real items. Subtle white → primary-tint
  /// diagonal gives the chip depth without looking like a button.
  Widget _gradientChip(String label) {
    final accent = AppColors.primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            accent.withValues(alpha: 0.09),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomText(
        label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.mainTextColor,
      ),
    );
  }

  /// Distinct overflow chip — solid primary tint + bold label + trailing
  /// arrow, so users read it as "tap to see more" instead of another item.
  Widget _overflowChip(int extra) {
    final accent = AppColors.primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            '+$extra more',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          const SizedBox(width: 3),
          Icon(Icons.arrow_forward_rounded, size: 11, color: accent),
        ],
      ),
    );
  }

  /// Empty-state row — a muted chip with an info icon + hint copy.
  Widget _sectionEmpty(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: AppColors.greyE5.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 12, color: AppColors.grey9B),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 11,
            color: AppColors.grey9B,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  String? _subCategoryLabel() {
    final depts = item.departments;
    if (depts == null || depts.isEmpty) return null;
    final first = depts.first.name;
    if (first == null || first.trim().isEmpty) return null;
    return first.trim();
  }

  Widget _subCategoryBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size3, horizontal: SizeConfig.size8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.small,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  double _destLat() {
    final coords = item.location?.coordinates;
    // GeoJSON stores [lng, lat].
    if (coords != null && coords.length >= 2) return coords[1];
    return 0.0;
  }

  double _destLng() {
    final coords = item.location?.coordinates;
    if (coords != null && coords.length >= 2) return coords[0];
    return 0.0;
  }

  void _openMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: item.name ?? 'Hospital',
      destinationAddress: item.location?.name ?? '',
      destinationLat: _destLat(),
      destinationLng: _destLng(),
      storeBusinessID: item.id ?? '',
      storeUserID: item.userId ?? '',
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    return DiscoverAddressPill(
      destLat: _destLat(),
      destLng: _destLng(),
      address: item.location?.name,
      onTap: () => _openMapBottomSheet(context),
    );
  }

}

/// Placeholders only — wrap in a single [buildLoadingShimmer] at the list
/// level so all cards share one animation controller. Rendering N shimmers
/// at once saturates Android's BLASTBufferQueue ("Already acquired max
/// frames") on mid-range devices.
class _HospitalCardSkeletonBody extends StatelessWidget {
  const _HospitalCardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      child: CommonCardWidget(
        cardMargin: 0,
        padding: SizeConfig.size12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(
                    width: SizeConfig.size70,
                    height: SizeConfig.size70,
                    radius: SizeConfig.size10
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerContainer(height: SizeConfig.size16),
                      SizedBox(height: SizeConfig.size8),
                      shimmerContainer(
                          height: SizeConfig.size12, width: 180),
                      SizedBox(height: SizeConfig.size6),
                      shimmerContainer(
                          height: SizeConfig.size12, width: 120),
                    ],
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                shimmerContainer(
                    width: SizeConfig.size34,
                    height: SizeConfig.size34,
                    radius: SizeConfig.size20),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            shimmerContainer(height: SizeConfig.size12),
            SizedBox(height: SizeConfig.size6),
            shimmerContainer(height: SizeConfig.size12, width: 220),
            SizedBox(height: SizeConfig.size10),
            shimmerContainer(height: 140, radius: 12),
            SizedBox(height: SizeConfig.size10),
            Row(
              children: [
                Expanded(
                    child: shimmerContainer(
                        height: SizeConfig.size24, radius: 6)),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                    child: shimmerContainer(
                        height: SizeConfig.size24, radius: 6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
