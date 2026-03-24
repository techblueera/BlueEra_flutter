import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/business_ratings_model.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_common_gallery_card.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/career_job_widget.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/product_header_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductHomeScreen extends StatefulWidget {
  const ProductHomeScreen({super.key});

  @override
  State<ProductHomeScreen> createState() => _ProductHomeScreenState();
}

class _ProductHomeScreenState extends State<ProductHomeScreen> {
  final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    viewBusinessDetailsController.isLoading.value = true;
    await viewBusinessDetailsController.viewBusinessProfile();
    final businessId = viewBusinessDetailsController.businessProfileDetails.value?.data?.id;
    if (businessId != null && businessId.isNotEmpty) {
      await Future.wait([
        viewBusinessDetailsController.fetchProducts(visitBusinessId: businessId),
        viewBusinessDetailsController.getBusinessDetailedRatings(businessId),
      ]);
    }
    viewBusinessDetailsController.isLoading.value = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      body: SafeArea(
        child: Obx(() {
          if (viewBusinessDetailsController.isLoading.value) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor));
          }
          final profileModel = viewBusinessDetailsController.businessProfileDetails.value;

          final data = profileModel?.data;
          if (data == null) {
            return const Center(child: CustomText("No Profile Data Found"));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 2. Search Bar ──
                // _buildSearchBar(),

                const SizedBox(height: 10),

                // ── 3. Profile Header Card ──
                _buildProfileHeader(data),
                const SizedBox(height: 10),

                // ── 4. Business Stats ──
                _buildBusinessStats(data),
                const SizedBox(height: 10),

                // ── 5. Top Selling Product ──
                _buildSection(
                  title: "Top Selling Product",
                  color: AppColors.skyBlueFF,
                  showViewAll: true,
                  child: _buildTopSellingProducts(),
                ),
                const SizedBox(height: 20),

                // ── 6. Category ──
                _buildSection(
                  title: "Category",
                  child: _buildCategorySection(data),
                ),
                const SizedBox(height: 10),

                // ── 7. Business Live Photos ──
                _buildSection(
                  title: "Business Live Photos",
                  showViewAll: true,
                  child: _buildLivePhoto(data.livePhotos),
                ),
                const SizedBox(height: 10),

                // ── 7. Gallery ──
                CommonGalleryCard(
                  // gallery: data.gallery
                  //     ?.expand((g) => g.imageUrls ?? [])
                  //     .cast<String>()
                  //     .toList(),
                  // onEditTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
                  // onAddTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
                  gallery:  [],
                  onEditTap: () {},
                  onAddTap: () {},
                  emptyTitle: 'You Have Not Post Any Photo',
                  addButtonLabel: 'Add Photo',
                ),
                const SizedBox(height: 10),

                // ── 8. Job ──
                CareerJobsWidget(jobs: []),
                const SizedBox(height: 10),

                // ── 8. Testimonials ──
                _buildSection(
                  title: "Testimonials",
                  child: _buildTestimonials(),
                ),
                const SizedBox(height: 10),

                // ── 9. Contact Us ||  Map ──
                BusinessContactMapCard(
                  businessProfileDetails: data,
                ),
                const SizedBox(height: 10),

                // ── 11. QR Code ──
                BusinessQrCodeWidget(
                  data:       data,
                  onDownload: () {
                    // downloadQrCode();
                  },
                  onShare:    () {
                    // shareQrCode();
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  2. SEARCH BAR
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
              AppColors.primaryColor.withValues(alpha: 0.0),
              AppColors.primaryColor.withValues(alpha: 0.2),
            ],
        ),
        border: Border.all(
          color: AppColors.skyBlueE4
        )
      ),
      child: CommonSearchBar(
        controller: _searchController,
        backgroundColor: AppColors.white,
        boxBorder: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.5),
        ),
        onClearCallback: () => _searchController.clear(),
        hintText: "search anything...",
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  3. PROFILE HEADER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProfileHeader(BusinessProfileDetails data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: ProductProfileHeader(
            details: data,
            controller: viewBusinessDetailsController,
          )
      ),
    );
  }


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  4. BUSINESS STATS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBusinessStats(BusinessProfileDetails? details) {
    String formatCount(dynamic value) {
      if (value == null) return '0';
      final count = (value is String) ? (int.tryParse(value) ?? 0) : (value as num).toInt();
      if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
      if (count >= 1000)    return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
      return count.toString();
    }

    String formatDate(String? isoDate) {
      if (isoDate == null) return '--';
      try {
        final date = DateTime.parse(isoDate);
        return '${date.day}/${date.month}/${date.year}';
      } catch (_) {
        return '--';
      }
    }

    Widget buildStat({required String label, required String value, IconData? icon, Color? iconColor}) {
      return Row(
        children: [
          CustomText('$label: ', fontSize: SizeConfig.small, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size2),
          ],
          CustomText(value, fontSize: SizeConfig.small, fontWeight: FontWeight.w700, color: AppColors.mainTextColor),
        ],
      );
    }

    Widget verticalDivider() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
        child: VerticalDivider(color: AppColors.greyE5, thickness: 1, width: 1),
      );
    }

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      padding: EdgeInsets.all(
          SizeConfig.size12,
      ),
      border: Border.all(
        color: AppColors.greyE5
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [

            // ─── Rating + Views ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildStat(
                    label: 'Rating',
                    value: '${details?.avg_rating ?? '0.0'}',
                    icon: Icons.star_rounded,
                    iconColor: AppColors.rating,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  buildStat(label: 'Views', value: formatCount(details?.total_views)),
                ],
              ),
            ),

            verticalDivider(),

            // ─── Inquiries + Followers ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildStat(label: 'Inquiries', value: formatCount('25')),
                  SizedBox(height: SizeConfig.size8),
                  buildStat(label: 'Followers', value: formatCount(details?.total_followers)),
                ],
              ),
            ),

            verticalDivider(),

            // ─── Joined ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText('Joined', fontSize: SizeConfig.small, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(formatDate(details?.createdAt), fontSize: SizeConfig.small, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  5. TOP SELLING PRODUCT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildTopSellingProducts() {
    return Obx(() {
      final products = viewBusinessDetailsController.products;
      if (products.isEmpty) {
        return _buildEmptyState(
          icon: Icons.shopping_bag_outlined,
          message: "No products added yet",
          btnLabel: "Add Product",
          onAdd: () {},
        );
      }

      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: products.length > 10 ? 10 : products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final details = product.product.details;
            final variants =
                product.product.sellerClassification?.variants ?? [];
            final img = (details?.media.isNotEmpty ?? false)
                ? details!.media.first
                : "";

            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.greyE5
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2)
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: img,
                      height: 160,
                      width: 150,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          height: 160,
                          width: 150,
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.image, color: Colors.grey)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                            details?.name ?? "",
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.mainTextColor),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            CustomText(
                                '₹${variants[0].sellingPrice}',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.0,
                                color: AppColors.secondaryTextColor),
                            const SizedBox(width: 4),
                            CustomText(
                                '₹${variants[0].mrp}',
                                fontWeight: FontWeight.w400,
                                fontSize: 10.0,
                                color: AppColors.secondaryTextColor,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.secondaryTextColor),
                            const SizedBox(width: 6),
                            DiscountBadge(
                              discountText: "${calculateDiscount(
                                variants[0].sellingPrice.toString(),
                                variants[0].mrp.toString(),
                              ).toInt()}% ${AppStrings.off.tr}",
                            ),
                          ],
                        ),
                        // if (price.isNotEmpty) ...[
                        //   const SizedBox(height: 3),
                        //   CustomText(price,
                        //       fontSize: 13,
                        //       fontWeight: FontWeight.bold,
                        //       color: AppColors.primaryColor,
                        //       fontFamily: AppConstants.OpenSans),
                        // ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  6. CATEGORY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCategorySection(BusinessProfileDetails data) {
      return businessProductsCategories.isNotEmpty ?
      MasonryGridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        padding: EdgeInsets.zero,
        primary: false,
        shrinkWrap: true,
        itemCount: businessProductsCategories.length,
        itemBuilder: (context, index) {
          var categoryItem = businessProductsCategories[index];
          return CommonServiceCard(
            service: categoryItem,
            getName: (_categoryItem) => _categoryItem.name??'',
            getIcon: (_categoryItem) => _categoryItem.icon??'',
            iconHeight: SizeConfig.size60,
            boxShadow: [],
            onTap: (_categoryItem) {
              // return Get.toNamed(RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
              //   arguments: {
              //     ApiKeys.userId: userId,
              //     ApiKeys.argGroceryCategoryWithInventory: groceryCategoryList,
              //     ApiKeys.argArrGroceryCatKey: _categoryItem.key,
              //     ApiKeys.argArrGroceryCatName: _categoryItem.name,
              //   },
              // );
            },
          );
        },
      )
          : EmptyStateWidget(
        message: 'You don\'t have inventory yet, Want to create one?',
      );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  7. GALLERY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildLivePhoto(List<String>? photos) {
    if (photos == null || photos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        message: "No gallery photos yet",
        btnLabel: "Add Photos",
        onAdd: () {},
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length > 8 ? 8 : photos.length,
        itemBuilder: (context, index) {
          final url = photos[index];
          final isVideo = url.endsWith('.mp4') || url.endsWith('.mov');
          return GestureDetector(
            onTap: () {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: AppStrings.imageViewer,
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: photos,
                  initialIndex: index,
                ),
              );
            },
            child: Container(
              width: 135,
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey)),
                    ),
                    if (isVideo) ...[
                      Container(
                          color: Colors.black.withValues(alpha: 0.35)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const CustomText("Video (HD)",
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  8. TESTIMONIALS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildTestimonials() {
    return Obx(() {
      final ratings = viewBusinessDetailsController.businessRatingsList;
      if (ratings.isEmpty) {
        return _buildEmptyState(
          icon: Icons.format_quote_outlined,
          message: "No testimonials yet",
          btnLabel: "Request Review",
          onAdd: () {},
        );
      }

      return SizedBox(
        height: 165,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: ratings.length > 5 ? 5 : ratings.length,
          itemBuilder: (context, index) {
            return _testimonialCard(ratings[index]);
          },
        ),
      );
    });
  }

  Widget _testimonialCard(BusinessRatingsData review) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars row
          Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i < (review.rating ?? 0)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.yellow00,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Quote
          Expanded(
            child: CustomText(
              "\"${review.comment ?? "Great experience!"}\"",
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              fontStyle: FontStyle.italic,
            ),
          ),
          Divider(color: Colors.grey[200], height: 16),
          // User row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: (review.user?.profileImage != null &&
                        review.user!.profileImage!.isNotEmpty)
                    ? NetworkImage(review.user!.profileImage!)
                    : null,
                backgroundColor: Colors.grey[200],
                child: (review.user?.profileImage == null ||
                        review.user!.profileImage!.isEmpty)
                    ? const Icon(Icons.person, size: 14, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomText(review.user?.username ?? "User",
                    fontSize: 12, fontWeight: FontWeight.w600, maxLines: 1),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.yellow00.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.yellow00),
                    const SizedBox(width: 2),
                    CustomText("${review.rating ?? 0}",
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow00),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  SECTION WRAPPER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSection({
    required String title,
    required Widget child,
    Color color = Colors.white,
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    return CustomFormCard(
      padding: EdgeInsets.all(10),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontSize: 17, fontWeight: FontWeight.bold),
              if (showViewAll)
                GestureDetector(
                  onTap: onViewAll ?? () {},
                  child: const CustomText("View All",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  EMPTY STATE (reusable)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String btnLabel,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 12),
          CustomText(message,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  CustomText(btnLabel,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
