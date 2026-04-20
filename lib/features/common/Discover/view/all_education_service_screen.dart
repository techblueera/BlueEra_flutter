import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AllEducationServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> professionalConsultantCategories;
  final OnboardingCategoryModel? selectedProfessionConsultantData;

  const AllEducationServiceScreen(
      {super.key,
      required this.professionalConsultantCategories,
      this.selectedProfessionConsultantData});

  @override
  State<AllEducationServiceScreen> createState() =>
      _AllEducationServiceScreenState();
}

class _AllEducationServiceScreenState extends State<AllEducationServiceScreen> {
  final controller_ = getOrPut(() => DiscoverController());
  late List<OnboardingCategoryModel> _professionalConsultantCategories;
  ScrollController scrollController = ScrollController();

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/happy-students-classroom_23-2149207191.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-college-students-studying-library_329181-15025.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-young-students-with-books-chalkboard_1303-20932.jpg?w=1380",
  ];

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    controller_.selectedEducationServiceData.value =
        widget.selectedProfessionConsultantData;
    controller_.fetchEducationServiceServices();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller_.fetchEducationServiceServices(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      StickyCategory(
          id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._professionalConsultantCategories.map((c) => StickyCategory(
            id: c.slugId,
            name: c.name,
            imageUrl: c.icon,
          )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor:
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    selectedId:
                        controller_.selectedEducationServiceData.value?.slugId ??
                            'ALL_OPTION',
                    onCategoryTap: (item) {
                      final index =
                          stickyCategories.indexWhere((c) => c.id == item.id);
                      controller_.selectedTabIndex.value = index;
                      controller_.selectedEducationServiceData.value =
                          item.id == 'ALL_OPTION'
                              ? null
                              : _professionalConsultantCategories
                                  .firstWhere((c) => c.slugId == item.id);
                      controller_.fetchEducationServiceServices();
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                _buildListSliver(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver() {
    return Obx(() {
      if (controller_.isEducationServiceLoading.value &&
          controller_.schoolDetailsDataDataList.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller_.schoolDetailsDataDataList.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24,
              vertical: SizeConfig.size40,
            ),
            child: _NoSchoolsFound(
              title: 'No schools found',
              subtitle:
                  'We couldn\'t find any schools or education services in this area. Try another category or change your location.',
              onRetry: () => controller_.fetchEducationServiceServices(),
            ),
          ),
        );
      }

      final list = controller_.schoolDetailsDataDataList;
      final showMoreLoader = controller_.isEducationServiceLoadingMore.value;

      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size10,
        ),
        sliver: SliverList.builder(
          itemCount: list.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return selfProfessionCard(list[index]);
          },
        ),
      );
    });
  }

  Widget selfProfessionCard(SchoolDetailsData service) {
    return InkWell(
      onTap: () {
        final schoolAboutUsController =
            getOrPut(() => SchoolAboutUsController());
        schoolAboutUsController.schoolDetailsData?.value = service;
        Get.to(DiscoverSchoolHomeScreen());
      },
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _schoolLogo(service.logo ?? ''),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        service.name ?? AppStrings.unknownUser.tr,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((service.type ?? '').isNotEmpty)
                        CustomText(
                          service.type!,
                          fontSize: SizeConfig.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.secondaryTextColor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),

            // ─── Gallery / Banner / Logo Photo ───
            if (service.galleryPhotos?.isNotEmpty == true) ...[
              StoreLivePhotoWidget(
                livePhotos: service.galleryPhotos!,
                natureOfBusiness: service.type ?? 'Education',
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
              SizedBox(height: SizeConfig.size8),
            ] else if ((service.bannerUrl ?? '').isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => navigatePushTo(
                    context,
                    ImageViewScreen(
                      subTitle: service.type ?? 'Education',
                      appBarTitle: AppStrings.imageViewer,
                      imageUrls: [service.bannerUrl!],
                      initialIndex: 0,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: service.bannerUrl!,
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
              SizedBox(height: SizeConfig.size8),
            ] else if ((service.logo ?? '').isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => navigatePushTo(
                    context,
                    ImageViewScreen(
                      subTitle: service.type ?? 'Education',
                      appBarTitle: AppStrings.imageViewer,
                      imageUrls: [service.logo!],
                      initialIndex: 0,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: service.logo!,
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
              SizedBox(height: SizeConfig.size8),
            ],

            if ((service.location?.name ?? '').isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalAssets(imagePath: AppIconAssets.location_new),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      service.location?.name,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            if (service.establishmentYear != null) ...[
              SizedBox(height: SizeConfig.size6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: CustomText(
                  "${AppStrings.sincePrefix.tr} ${service.establishmentYear ?? ""}",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.green00,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _schoolLogo(String url) {
    if (url.isEmpty) return _brokenSchoolLogo();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: SizeConfig.size40,
          height: SizeConfig.size40,
          color: AppColors.greyE5,
        ),
        errorWidget: (_, __, ___) => _brokenSchoolLogo(),
      ),
    );
  }

  Widget _brokenSchoolLogo() => Container(
        width: SizeConfig.size40,
        height: SizeConfig.size40,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.school_outlined,
          size: SizeConfig.size22,
          color: AppColors.secondaryTextColor,
        ),
      );
}

class _NoSchoolsFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoSchoolsFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationSize = SizeConfig.size80;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: illustrationSize,
          height: illustrationSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.12),
                AppColors.primaryColor.withValues(alpha: 0.04),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.school_outlined,
            size: illustrationSize * 0.5,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        CustomText(
          title,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size8),
        CustomText(
          subtitle,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (onRetry != null) ...[
          SizedBox(height: SizeConfig.size16),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh,
                      color: AppColors.white,
                      size: SizeConfig.size18),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    'Retry',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
