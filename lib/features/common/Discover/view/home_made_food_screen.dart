import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/map/widget/profile_summary_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodScreen extends StatefulWidget {
  const HomeMadeFoodScreen({super.key});

  @override
  State<HomeMadeFoodScreen> createState() => _HomeMadeFoodScreenState();
}

class _HomeMadeFoodScreenState extends State<HomeMadeFoodScreen> {
  final controller = getOrPut(() => DiscoverController());
  final List<OnboardingCategoryModel> _homeMadeFoodCategories = homeMadeFoodCategories;
  ScrollController scrollController = ScrollController();
  String serviceSubType = EarnServiceTypes.homeMadeFood.label;
  String earnServiceType = AppConstants.food;

  @override
  initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      clearSelectedCategory();
      controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType
      );

      // Listener for Pagination
      scrollController.addListener(() {
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
          controller.fetchEarnServices(
              earnServiceType: earnServiceType,
              subType: serviceSubType,
              isLoadMore: true);
        }
      });
    });
  }

  void clearSelectedCategory(){
    controller.selectedEarnServiceData.value = null;
    controller.selectedTabIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Column(
          children: [

            SizedBox(
              height: SizeConfig.paddingM,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8),
              child: InkWell(
                onTap: () {

                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5, width: 1.2),
                      boxShadow: [AppShadows.textFieldShadow]),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.franchiseIcon,
                        height: SizeConfig.size30,
                        width: SizeConfig.size30,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomText(
                          AppStrings.bookViaBlueEraPartner,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(
              height: SizeConfig.paddingXSL,
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(
                      child: rightContent()
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    final allItem = OnboardingCategoryModel(
      name: 'All',
      slugId: 'ALL_OPTION',
      icon: AppImageAssets.all,
      accountType: AppConstants.individual,
    );

    final fullList = [allItem, ..._homeMadeFoodCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon,
      isSelected: (item) {
        if (item.slugId == 'ALL_OPTION') {
          return controller.selectedEarnServiceData.value == null;
        }
        return controller.selectedEarnServiceData.value?.slugId == item.slugId;
      },
      onTap: (item, index) {
        controller.selectedTabIndex.value = index;
        if (item.slugId == 'ALL_OPTION') {
          controller.selectedEarnServiceData.value = null;
        } else {
          controller.selectedEarnServiceData.value = item;
        }
        controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
        );
      },
    );
  }

  // Widget leftCategoryList() {
  //   return Container(
  //     width: 94,
  //     color: AppColors.white,
  //     child: ListView.builder(
  //       // We keep +1 to accommodate the "All" button at the top
  //       itemCount: _homeMadeFoodCategories.length + 1,
  //       padding: EdgeInsets.only(bottom: SizeConfig.size30),
  //       shrinkWrap: true,
  //       itemBuilder: (context, index) {
  //
  //         // --- CASE 1: The "All" Item (Index 0) ---
  //         if (index == 0) {
  //           return Obx(() => ServiceCategoryItem(
  //             icon: AppIconAssets.electricianIcon,
  //             label: "All",
  //             selected: controller.selectedEarnServiceData.value == null,
  //             onTap: () {
  //               clearSelectedCategory();
  //               controller.fetchEarnServices(
  //                   earnServiceType: earnServiceType,
  //                   subType: serviceSubType
  //               );
  //             },
  //           ));
  //         }
  //
  //         // --- CASE 2: Actual Categories (Index 1+) ---
  //         var item = _homeMadeFoodCategories[index - 1];
  //
  //         return Obx(() => ServiceCategoryItem(
  //           icon: item.icon,
  //           label: item.name,
  //           selected: controller.selectedEarnServiceData.value?.slugId == item.slugId,
  //           onTap: () {
  //             controller.selectedEarnServiceData.value = item;
  //             controller.selectedTabIndex.value = index;
  //             controller.fetchEarnServices(
  //                 earnServiceType: earnServiceType,
  //                 subType: serviceSubType
  //             );
  //           },
  //         ));
  //       },
  //     ),
  //   );
  // }

  Widget rightContent() {
    return Obx(()=> Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HorizontalTabSelector<CategoryFilter>(
            tabs: controller.filters,
            selectedIndex: controller.filters.indexOf(controller.selectedFilter.value),
            horizontalMargin: 0.0,
            onTabSelected: (index, _) {
              final selectedEnum = controller.filters[index];

              if (controller.filters == selectedEnum) return;

              controller.selectedFilter.value = selectedEnum;
              // controller.callApi();
            },
            labelBuilder: (r) => r.label,
            unSelectedBackgroundColor: AppColors.white,
          ),

          SizedBox(
            height: SizeConfig.size5,
          ),

          Expanded(
            child: Obx(() {
              if (controller.isEarnServiceLoading.value &&
                  controller.earnServiceList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.earnServiceList.isEmpty) {
                return Center(child: EmptyStateWidget(message: "No services found"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    controller: scrollController,
                    itemCount: controller.earnServiceList.length,
                    shrinkWrap: true,
                    padding:
                    const EdgeInsets.only(top: 12, bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.80,
                      // 🔹 slightly increased to give more height
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemBuilder: (context, index) =>
                        _buildServiceCard(controller.earnServiceList[index]),
                  );

                },
              );
            }),
          )

        ],
      ),
    ));
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
                      imagePaths: (serviceData
                          .serviceMedia?.photos?.isNotEmpty ??
                          false)
                          ? [
                        serviceData.serviceMedia?.photos?.firstOrNull ??
                            "",
                      ]
                          : [],
                      borderRadius: BorderRadius.zero,
                    ),
                    if (serviceData.priceData?.priceRange?.min != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.blackD4,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomText(
                            (serviceData.priceData?.priceRange?.min ?? 0) >
                                1000000
                                ? "INR ${formatIndianNumber(serviceData.priceData?.priceRange?.min ?? 0)}/-"
                                : 'INR ${formatNumber(serviceData.priceData?.priceRange?.min ?? 0)}/-',
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.white,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                    SizedBox(
                      height: 2,
                    ),
                    ProfileSummaryCard(
                      name: serviceData.name ?? '',
                      imageUrl: serviceData.profileImage ?? '',
                      rating: (serviceData.rating ?? 0).toDouble(),
                      reviews: serviceData.reviewCount ?? 0,
                      distance: "${serviceData.distance ?? 0} km",
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CommonIconContainerButton(
                            onTap: () async {
                              final chatViewController = Get.isRegistered<ChatViewController>()
                                  ? Get.find<ChatViewController>()
                                  : Get.put(ChatViewController());
                              Map<String,dynamic>? userDetailsMap=  await chatViewController.checkChatConnection(
                                  {ApiKeys.user_id: serviceData.id});
                              if(userDetailsMap!=null){
                                final conversationId = userDetailsMap[ApiKeys.conversation_id];

                                final hasExisting = conversationId != null &&
                                    conversationId.toString().isNotEmpty &&
                                    conversationId.toString().toLowerCase() != 'null';
                                chatViewController.openAnyOneChatFunction(
                                  profileImage: serviceData.profileImage ?? '',
                                  otherUserId: hasExisting
                                      ? null
                                      :userDetailsMap[ApiKeys.other_user_id] ?? '',
                                  type: "personal",
                                  isInitialMessage: !hasExisting,
                                  userId: serviceData.id ?? '',
                                  conversationId: userDetailsMap[ApiKeys.conversation_id] ?? '',
                                  contactName: serviceData.name ?? '',
                                  contactNo: "",
                                );
                              }

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
