import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_detail_screen.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => FinanceDiscoverController());
    controller.fetchInitial(widget.categorySlugId);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        child: Builder(
          builder: (context) {
            final rows = buildNativeAdRows(controller.profiles.length);
            return ListView.builder(
              controller: _scrollController,
              itemCount:
                  rows.length + (controller.isLoadingMore.value ? 1 : 0),
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size12
              ),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == rows.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size12),
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
      );
    });
  }
}

class _FinanceCard extends StatelessWidget {
  final FinanceBusinessItem item;

  const _FinanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final String address = item.location?.name ?? item.location?.address ?? '';
    final String phone =
        item.contactUs?.firstOrNull?.departments?.firstOrNull?.phone ?? '';
    final String email =
        item.contactUs?.firstOrNull?.departments?.firstOrNull?.email ?? '';
    final String category = item.category ?? item.type ?? '';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    child: Container(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      color: AppColors.liteWhite,
                      child: (item.logoUrl?.isNotEmpty ?? false)
                          ? Image.network(
                              item.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image),
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
                          (item.profileName?.isNotEmpty ?? false)
                              ? item.profileName
                              : "Unknown",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomText(
                              category.replaceAll('_', ' ').capitalize ?? '',
                              fontSize: 10,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (address.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size6),
                          CustomText(
                            "Address : $address",
                            fontSize: SizeConfig.small,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // ─── Gallery / Cover / Logo Photo ───
              Builder(builder: (_) {
                final galleryPhotos = <String>[];
                if (item.gallery != null) {
                  for (final g in item.gallery!) {
                    if (g.imageUrls != null) {
                      galleryPhotos.addAll(
                          g.imageUrls!.where((u) => u.trim().isNotEmpty));
                    }
                  }
                }
                final hasCover = (item.coverUrl ?? '').isNotEmpty;
                final hasLogo = (item.logoUrl ?? '').isNotEmpty;

                if (galleryPhotos.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: StoreLivePhotoWidget(
                      livePhotos: galleryPhotos,
                      natureOfBusiness: item.type ?? 'Finance',
                      height: 200,
                      onViewFullScreen: ({
                        required int index,
                        required List<String> storeImage,
                        required String natureOfBusiness,
                      }) {
                        Get.to(() => ImageViewScreen(
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
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () => Get.to(() => ImageViewScreen(
                            subTitle: item.type ?? 'Finance',
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
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () => Get.to(() => ImageViewScreen(
                            subTitle: item.type ?? 'Finance',
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

              if (phone.isNotEmpty || email.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (phone.isNotEmpty) ...[
                      Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 4),
                      CustomText(phone, fontSize: 12),
                    ],
                    if (phone.isNotEmpty && email.isNotEmpty)
                      const SizedBox(width: 12),
                    if (email.isNotEmpty) ...[
                      Icon(Icons.email_outlined,
                          size: 14, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          email,
                          fontSize: 12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
