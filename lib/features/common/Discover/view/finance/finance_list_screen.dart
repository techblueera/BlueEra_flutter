import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_detail_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinanceListScreen extends StatefulWidget {
  final String categorySlugId;

  const FinanceListScreen({super.key, required this.categorySlugId});

  @override
  State<FinanceListScreen> createState() => _FinanceListScreenState();
}

class _FinanceListScreenState extends State<FinanceListScreen> {
  late final FinanceDiscoverController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => FinanceDiscoverController());
    controller.fetchInitial(widget.categorySlugId);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;
    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.profiles.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor));
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
            "No services found",
            fontSize: SizeConfig.medium,
            color: AppColors.grey9B,
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          await controller.fetchInitial(widget.categorySlugId);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: Builder(
            builder: (context) {
              final rows = buildNativeAdRows(controller.profiles.length);
              return ListView.builder(
                itemCount:
                    rows.length + (controller.isLoadingMore.value ? 1 : 0),
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == rows.length) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: SizeConfig.size12),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryColor)),
                    );
                  }
                  final row = rows[index];
                  if (row.isAd) {
                    return NativeAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'finance_native_ad',
                    );
                  }
                  final item = controller.profiles[row.contentIndex];
                  return _FinanceCard(item: item);
                },
              );
            },
          ),
        ),
      );
    });
  }
}

class _FinanceCard extends StatelessWidget {
  final FinanceBusinessItem item;

  const _FinanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final String address = _resolveAddress(item);
    final String category = item.category ?? item.type ?? '';

    final List<String> coverImages = <String>[];
    if (item.gallery != null) {
      for (final g in item.gallery!) {
        if (g.imageUrls != null) {
          coverImages.addAll(g.imageUrls!.where((u) => u.trim().isNotEmpty));
        }
      }
    }
    if (coverImages.isEmpty && (item.coverUrl ?? '').isNotEmpty) {
      coverImages.add(item.coverUrl!);
    }

    const String na = 'N/A';
    final double? ratingValue = item.rating;
    final String rating = (ratingValue != null && ratingValue > 0)
        ? ratingValue.toStringAsFixed(1)
        : na;

    final String distance = _distanceFromUser(item);
    final ({String label, Color color}) openBadge = _todayOpenBadge(item);
    final String registryLabel =
        item.rbiRegistered == true ? 'RBI Registered' : 'Not RBI Reg.';
    final Color registryColor =
        item.rbiRegistered == true ? AppColors.greenShade : AppColors.grey83;

    final List<String> serviceTags = <String>[
      ...?item.accountType?.where((s) => s.trim().isNotEmpty),
    ];
    if (serviceTags.isEmpty) serviceTags.add(na);
    const int moreTagsCount = 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 10, left: 8),
      child: InkWell(
        onTap: () {
          final controller = Get.find<FinanceDiscoverController>();
          controller.selectedDetail.value = item;
          Get.to(() => const FinanceDetailScreen());
        },
        child: CommonCardWidget(
          cardMargin: 0,
          padding: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverSection(
                images: coverImages,
                rating: rating,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(
                    address: address,
                    distance: distance,
                    registryLabel: registryLabel,
                    registryColor: registryColor,
                    openLabel: openBadge.label,
                    openColor: openBadge.color,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: _buildTagsRow(
                      serviceTags: serviceTags,
                      moreCount: moreTagsCount,
                      category: category,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _buildActionsRow(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveAddress(FinanceBusinessItem item) {
    final branchLoc = item.contactUs?.firstOrNull?.branch?.location;
    final branchName = item.contactUs?.firstOrNull?.branch?.name;
    final candidates = <String?>[
      item.location?.address,
      item.location?.name,
      branchLoc?.address,
      branchLoc?.name,
      branchName,
    ];
    for (final c in candidates) {
      final t = c?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  Future<void> _shareFinance(FinanceBusinessItem item) async {
    final name = (item.profileName?.trim().isNotEmpty ?? false)
        ? item.profileName!.trim()
        : 'this finance service';
    final address = _resolveAddress(item);
    final website = item.effectiveWebsite ?? '';

    final lines = <String>['Check out $name on BlueEra'];
    if (address.isNotEmpty) lines.add(address);
    if (item.rbiRegistered == true) lines.add('RBI Registered');
    final types =
        item.accountType?.where((s) => s.trim().isNotEmpty).toList() ??
            const [];
    if (types.isNotEmpty) lines.add('Accounts: ${types.join(', ')}');
    if (website.isNotEmpty) lines.add(website);
    final shareLink = financialDeepLink(
      businessId: item.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${item.profileName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: item.profileName,
    );
  }

  /// Opens a chat with the finance business owner — same behaviour as the
  /// hospital list card: guest gate, chat-click tracking against the business
  /// id, then opens the discover chat lane.
  void _openChat() {
    final userId = item.userId ?? '';
    if (userId.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = item.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: item.profileName,
      profile: item.logoUrl,
      route: AppConstants.route_discover,
    );
  }

  String _distanceFromUser(FinanceBusinessItem item) {
    final coords = item.contactUs?.firstOrNull?.branch?.location?.coordinates ??
        item.location?.coordinates;
    if (coords == null || coords.length < 2) return 'N/A';
    final lng = coords[0];
    final lat = coords[1];
    if (lat == 0.0 || lng == 0.0) return 'N/A';
    final km = calculateDistance(lat, lng);
    if (km == null) return 'N/A';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m Away';
    if (km < 10) return '${km.toStringAsFixed(1)}KM Away';
    return '${km.toStringAsFixed(0)}KM Away';
  }

  Widget _buildCoverSection({
    required List<String> images,
    required String rating,
  }) {
    final Widget imageWidget = images.isNotEmpty
        ? GestureDetector(
            onTap: () => Get.to(() => ImageViewScreen(
                  subTitle: item.type ?? 'Finance',
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: images,
                  initialIndex: 0,
                )),
            child: CachedNetworkImage(
              imageUrl: images.first,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
              errorWidget: (_, __, ___) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            ),
          )
        : Container(
            height: 170,
            width: double.infinity,
            color: AppColors.liteWhite,
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
          );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    CustomText(
                      rating,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _circleIconBtn(AppIconAssets.share_bold,
                      onTap: () => _shareFinance(item)),
                  const SizedBox(height: 8),
                  _circleIconBtn(AppIconAssets.star, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconBtn(String icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.black25,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: 14,
            width: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required String address,
    required String distance,
    required String registryLabel,
    required Color registryColor,
    required String openLabel,
    required Color openColor,
  }) {
    bool isMeaningful(String s) => s.isNotEmpty && s != 'N/A';
    final bool showDistance = isMeaningful(distance);
    final bool showAddress = isMeaningful(address);
    final bool hasLocation = showDistance || showAddress;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: Container(
                  width: 50,
                  height: 50,
                  color: AppColors.liteWhite,
                  child: (item.logoUrl?.isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: item.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image),
                          errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image),
                        )
                      : LocalAssets(
                          imagePath: AppIconAssets.place_holder_image),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      (item.profileName?.isNotEmpty ?? false)
                          ? item.profileName
                          : 'Unknown',
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black22,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasLocation) ...[
                      SizedBox(height: SizeConfig.size2),
                      Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.location_outline,
                            imgColor: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  if (showDistance)
                                    TextSpan(
                                      text: distance,
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  if (showDistance && showAddress)
                                    TextSpan(
                                      text: "  |  ",
                                      style: TextStyle(
                                        color: AppColors.secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (showAddress)
                                    TextSpan(
                                      text: address,
                                      style: TextStyle(
                                        color: AppColors.secondaryTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          _buildBadgesRow(
            registryLabel: registryLabel,
            registryColor: registryColor,
            openLabel: openLabel,
            openColor: openColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow({
    required String registryLabel,
    required Color registryColor,
    required String openLabel,
    required Color openColor,
  }) {
    return Row(
      children: [
        _outlineBadge(
          icon: Icons.verified_outlined,
          label: registryLabel,
          color: registryColor,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _outlineBadge(
            icon: Icons.access_time,
            label: openLabel,
            color: openColor,
          ),
        ),
      ],
    );
  }

  /// Derives an "Open | HH:MM - HH:MM" / "Closed today" / N/A pill from
  /// the per-day `timings` payload, with a fallback to the legacy
  /// `businessHours` object when `timings` is absent.
  ({String label, Color color}) _todayOpenBadge(FinanceBusinessItem item) {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null) {
      if (today.hasHours) {
        return (
          label: 'Open | ${today.openTime} - ${today.closeTime}',
          color: AppColors.greenShade,
        );
      }
      return (label: 'Closed today', color: AppColors.grey83);
    }
    final bh = item.businessHours;
    if (bh?.hasHours == true) {
      return (
        label: 'Open | ${bh!.openTime} - ${bh.closeTime}',
        color: AppColors.greenShade,
      );
    }
    return (label: 'Open | N/A', color: AppColors.grey83);
  }

  Widget _outlineBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow({
    required List<String> serviceTags,
    required int moreCount,
    required String category,
  }) {
    final tags = serviceTags.isNotEmpty
        ? serviceTags
        : (category.isNotEmpty
            ? [category.replaceAll('_', ' ').capitalize ?? category]
            : <String>[]);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...tags.map((t) => _tagChip(t, AppColors.fillColor, AppColors.grey7E)),
        if (moreCount > 0)
          _tagChip('+$moreCount More', AppColors.red.withValues(alpha: 0.08),
              AppColors.red),
      ],
    );
  }

  Widget _tagChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFDDE2EE), width: 0.5)),
      child: CustomText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
  }

  Widget _buildActionsRow() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.inquiry.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                ],
              ),
            ),
          ),
          // Expanded(
          //   flex: 2,
          //   child: Material(
          //     color: Colors.transparent,
          //     borderRadius: BorderRadius.circular(10),
          //     child: InkWell(
          //       borderRadius: BorderRadius.circular(10),
          //       onTap: _openChat,
          //       child: Container(
          //         height: 44,
          //         decoration: BoxDecoration(
          //           color: AppColors.skyBlueFF,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             LocalAssets(
          //                 imagePath: AppIconAssets.chat,
          //                 imgColor: AppColors.primaryColor),
          //             const SizedBox(width: 6),
          //             CustomText(
          //               'Chat',
          //               fontSize: 13,
          //               fontWeight: FontWeight.w600,
          //               color: AppColors.primaryColor,
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 10),
          // Expanded(
          //   flex: 4,
          //   child: Container(
          //     height: 44,
          //     decoration: BoxDecoration(
          //       color: AppColors.primaryColor,
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         CustomText(
          //           'Open Account',
          //           fontSize: 13,
          //           fontWeight: FontWeight.w700,
          //           color: AppColors.white,
          //         ),
          //         const SizedBox(width: 6),
          //         const Icon(Icons.arrow_forward,
          //             size: 16, color: AppColors.white),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
