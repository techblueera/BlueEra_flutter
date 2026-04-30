import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/widget/profile_summary_card.dart';
import 'package:BlueEra/features/common/map/widget/sub_category_tab_bar.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeServicesBottomSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onClose;
  final String category;
  final String subType;

  HomeServicesBottomSheet({
    super.key,
    required this.onClose,
    required this.lat,
    required this.lng,
    required this.category,
    required this.subType,
  });

  @override
  State<HomeServicesBottomSheet> createState() =>
      _HomeServicesBottomSheetState();
}

class _HomeServicesBottomSheetState extends State<HomeServicesBottomSheet> {
  final MapServiceController mapServiceController =
      Get.put(MapServiceController());
  int _selectedSubCategoryIndex = 0;
  String? _selectedSubCategory;
  final List<String> subCategories = [];

  @override
  initState() {
    super.initState();
    getHomeServices();
    // mapServiceController.getHomeServiceDataByProfession(
    //     serviceType: _selectedSubCategory,
    // );

    // if (widget.lat != 0.0 && widget.lng != 0.0) {
    //   print("called after getting lat lng");
    //   getHomeServices();
    // }
  }

  @override
  void didUpdateWidget(covariant HomeServicesBottomSheet oldWidget) {
    // getHomeServices();

    // if (oldWidget.lat != widget.lat && oldWidget.lng != widget.lng) {
    //   if (widget.lat != 0.0 && widget.lng != 0.0) {
    //     print("called after getting lat lng");
    //     getHomeServices();
    //   }
    // }
    super.didUpdateWidget(oldWidget);
  }

  void getHomeServices() {
    mapServiceController.fetchHomeService(
        lat: widget.lat,
        lng: widget.lng,
        serviceType: widget.category,
        subType: widget.subType);
  }

  @override
  Widget build(BuildContext context) {
    // return Container(width: Get.width,height: 200,color: Colors.red,);
    return CommonDraggableBottomSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      backgroundColor: AppColors.whiteF1,
      boxShadow: [
        BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4.0,
            offset: Offset(0, -3))
      ],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: EdgeInsets.only(top: SizeConfig.size10, bottom: kToolbarHeight),
      builder: (scrollController) {
        // return Container(width: Get.width,height: 200,color: Colors.red,);
        return Obx(() {
          if (mapServiceController.homeServiceResponse.value.status ==
              Status.COMPLETE) {
            if (mapServiceController.isHomeServiceLoading.isTrue) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              List<ServiceData> homeServiceList =
                  mapServiceController.homeServiceList;
              if (homeServiceList.isNotEmpty) {
                final professionMap = mapServiceController
                    .groupServicesByProfession(homeServiceList);

                final List<String> subCategories = professionMap.keys.toList();

                if (_selectedSubCategory == null && subCategories.isNotEmpty) {
                  _selectedSubCategory = subCategories.first;
                  _selectedSubCategoryIndex = 0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                        child: IconButton(
                          iconSize: SizeConfig.size18,
                          onPressed: () => widget.onClose(),
                          icon: Icon(
                            Icons.close,
                            size: SizeConfig.size16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SubCategoryTabBar<String>(
                      tabs: subCategories,
                      selectedIndex: _selectedSubCategoryIndex,
                      onSelected: (index, label) {
                        setState(() {
                          _selectedSubCategoryIndex = index;
                          _selectedSubCategory = label;
                        });
                      },
                      labelBuilder: (label) => label,
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // final itemWidth = (constraints.maxWidth - 10) / 2;
                            // final itemHeight = SizeConfig.size220;

                            final List<ServiceData> serviceData =
                                _selectedSubCategory != null
                                    ? professionMap[_selectedSubCategory] ?? []
                                    : [];
                            return GridView.builder(
                              controller: scrollController,
                              itemCount: serviceData.length,
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.78,
                                // 🔹 slightly increased to give more height
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildServiceCard(serviceData[index]),
                            );

                          },
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Center(
                    child: EmptyStateWidget(
                  message: 'No service available.',
                ));
              }
            }
          } else if (mapServiceController.homeServiceResponse.value.status ==
              Status.ERROR) {
            return LoadErrorWidget(
                errorMessage: 'Failed to load home services',
                onRetry: () => getHomeServices());
          }

          return SizedBox();
        });
      },
    );
  }

  Widget _buildServiceCard(ServiceData serviceData) {
    return InkWell(
      onTap: () {
        if (userId == serviceData.id) {
          Get.to(() => PersonalProfileSetupNewScreen());
        } else {
          Get.to(() => NewVisitProfileScreen(
                authorId: serviceData.id ?? '',
                screenFromName: AppConstants.feedScreen,
              ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ✅ Make image flexible — not fixed 190
            AspectRatio(
              aspectRatio: 1.4, // controls image height dynamically
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: [
                        serviceData.serviceMedia?.photos?.firstOrNull ?? "",
                      ],
                      borderRadius: BorderRadius.zero,
                    ),

                  ],
                ),
              ),
            ),

            /// ✅ Rest of info area flexible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    ProfileSummaryCard(
                      name: serviceData.name ?? '',
                      imageUrl: serviceData.profileImage ?? '',
                      rating: (serviceData.rating ?? 0).toDouble(),
                      reviews: serviceData.reviewCount ?? 0,
                      distance: "${serviceData.distance ?? 0} km",
                    ),


                    if (serviceData.priceData?.priceRange?.min != null)
                      CustomText(
                        (serviceData.priceData?.priceRange?.min ?? 0) >
                            1000000
                            ? "Charge : INR ${formatIndianNumber(serviceData.priceData?.priceRange?.min ?? 0)}/-"
                            : 'Charge : INR ${formatNumber(serviceData.priceData?.priceRange?.min ?? 0)}/-',
                        fontSize: SizeConfig.extraSmall,
                        maxLines: 1,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: (serviceData.id != userId)
                              ? CommonIconContainerButton(
                                  onTap: () async {
                                    final chatViewController = Get.isRegistered<ChatViewController>()
                                        ? Get.find<ChatViewController>()
                                        : Get.put(ChatViewController());
                                    chatViewController.checkChatConnectionAndOpenChat(
                                      userId: serviceData.id ?? '',
                                    );

                                  },
                                  icon: LocalAssets(
                                    imagePath: AppIconAssets.quillChatIcon,
                                    imgColor: AppColors.white,
                                  ),
                                  label: AppStrings.chat.tr,
                                  backgroundColor: AppColors.primaryColor,
                                  height: 28,
                                  fontSize: SizeConfig.size12,
                                  textColor: AppColors.white,
                                )
                              : PositiveCustomBtn(
                                  onTap: null,
                                  title: AppStrings.view,
                                  height: 28,
                                  fontSize: SizeConfig.size12,
                                  textColor: AppColors.white,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
