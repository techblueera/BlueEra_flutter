import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/view/widget/food_product_card.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/model/food_service_model_response.dart';
import 'package:BlueEra/features/common/map/widget/profile_summary_card.dart';
import 'package:BlueEra/features/common/map/widget/service_card.dart';
import 'package:BlueEra/features/common/map/widget/store_list_widget.dart';
import 'package:BlueEra/features/common/map/widget/sub_category_tab_bar.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn_with_icon.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/getplace_list_controller.dart';
import '../controller/getstore_list_controller.dart';

class CustomServiceBottomSheet extends StatefulWidget {
  final String serviceType;
  final VoidCallback onClose;
  final double lat;
  final double lng;
  const CustomServiceBottomSheet({super.key, required this.serviceType, required this.onClose, required this.lat, required this.lng});

  @override
  State<CustomServiceBottomSheet> createState() => _CustomServiceBottomSheetState();
}

class _CustomServiceBottomSheetState extends State<CustomServiceBottomSheet> {
  final PlaceController controller = Get.put(PlaceController());
  final StoreController StoreControllers = Get.put(StoreController());
  final MapServiceController mapServiceController = Get.find<MapServiceController>();

  String? _selectedSubCategory;
  final List<String> subCategories = [];

  @override
  void initState() {
    if(widget.serviceType.toUpperCase() == 'FOODS'){
      getFoodServices();
    }else if(widget.serviceType.toUpperCase() == 'PLACES'){
      controller.fetchPlaces(
          widget.lat,
          widget.lng
      );
    }
    // StoreControllers.fetchStores(widget.lat,widget.lng);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomServiceBottomSheet oldWidget) {
    if (oldWidget.lat != widget.lat && oldWidget.lng != widget.lng) {
      if (widget.lat != 0.0 && widget.lng != 0.0) {
        if(widget.serviceType.toUpperCase() == 'FOODS'){
          getFoodServices();
        }
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  void getFoodServices(){
    mapServiceController.fetchFoodService(
      lat: widget.lat,
      lng: widget.lng,
    );
  }

  @override
  Widget build(BuildContext context) {
return CustomText("Comming soon");
    return CommonDraggableBottomSheet(
      initialChildSize: 0.45,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      backgroundColor: AppColors.whiteF1,
      boxShadow: [
        BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4.0,
            offset: Offset(0, -3)
        )
      ],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: EdgeInsets.only(top: SizeConfig.size10, bottom: kToolbarHeight),
      builder: (scrollController) {
        return Column(
          children: [

            /// Close Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
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

            SizedBox(height: SizeConfig.size10),

            if(widget.serviceType.toUpperCase() == 'FOODS')
              _buildFoodServiceBody(scrollController)
            else if(widget.serviceType.toUpperCase() == 'PLACES')
              _buildPlaceServiceBody(scrollController)
            else
              StoreControllers.allStore.isNotEmpty ? Expanded(
                  child:Obx(()=> ListView.builder(
                    controller: scrollController,
                    itemCount: StoreControllers.allStore.length,
                    padding: EdgeInsets.only(bottom: 24, left: SizeConfig.size15, right: SizeConfig.size15),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: StoreListWidget(isPlaceService: false, storeList:StoreControllers.allStore[index]),
                    ),
                  ),
                  )
              ) : Flexible(child: Center(child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Text("No Data Found!",style: TextStyle(color: Colors.blue),),
              )))
          ],
        );
      },
    );
  }

  Widget _buildPlaceServiceBody(ScrollController scrollController) {
    return  controller.allPlaces.isNotEmpty ? Expanded(
      child:Obx(()=> ListView.builder(
        controller: scrollController,
        itemCount: controller.allPlaces.length,
        padding: EdgeInsets.only(bottom: 24, left: SizeConfig.size15, right: SizeConfig.size15),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(isPlaceService: true, placeList:controller.allPlaces[index],),
        ),
      ),
      ),):Flexible(child: Center(child: Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Text("No Data Found!",style: TextStyle(color: Colors.blue),),
      )
     )
    );
  }
  int _selectedSubCategoryIndex = 0;

  _buildFoodServiceBody(ScrollController scrollController) {
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
        return Obx(() {
          if (mapServiceController.foodServiceResponse.value.status ==
              Status.COMPLETE) {
            if (mapServiceController.isHomeServiceLoading.isTrue) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              List<FoodServicesData> foodServicesList = mapServiceController.foodServiceList;

              if (foodServicesList.isNotEmpty) {
                final professionMap = mapServiceController
                    .groupFoodServicesByProfessionDataList(foodServicesList);

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

                            final List<FoodServicesData> serviceData =
                            _selectedSubCategory != null
                                ? professionMap[_selectedSubCategory] ?? []
                                : [];

                            return GridView.builder(
                              controller: scrollController,
                              itemCount: serviceData.length,
                              shrinkWrap: true,
                              padding:
                              const EdgeInsets.only(top: 12, bottom: 24),
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.67,
                                // childAspectRatio: 0.712,
                                crossAxisSpacing: 6.0,
                                mainAxisSpacing: 6.0,
                                // childAspectRatio: itemWidth / itemHeight,
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
          } else if (mapServiceController.foodServiceResponse.value.status ==
              Status.ERROR) {
            // return LoadErrorWidget(
            //     errorMessage: 'Failed to load home services',
            //     onRetry: () => getHomeServices());
          }

          return SizedBox();
        });
      },
    );
    if(mapServiceController.foodServiceResponse.value.status == Status.COMPLETE){
      return Obx(() {
        if(mapServiceController.isFoodServiceLoading.isTrue) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }else{
          List<FoodServices> foodServicesList = mapServiceController.foodServicesList;
          if(foodServicesList.isNotEmpty) {
            final professionMap = mapServiceController.groupFoodServicesByProfession(foodServicesList);

            final List<String> subCategories = professionMap.keys.toList();

            if (_selectedSubCategory == null && subCategories.isNotEmpty) {
              _selectedSubCategory = subCategories.first;
            }


            // foodServiceData.isNotEmpty ? Expanded(
            //   child: Obx(() =>
            //       ListView.builder(
            //         controller: scrollController,
            //         itemCount: controller.allPlaces.length,
            //         padding: EdgeInsets.only(bottom: 24,
            //             left: SizeConfig.size15,
            //             right: SizeConfig.size15),
            //         itemBuilder: (context, index) =>
            //             Padding(
            //               padding: const EdgeInsets.only(bottom: 16),
            //               child: ServiceCard(isPlaceService: true,
            //                 placeList: controller.allPlaces[index]),
            //             ),
            //       ),
            //   )) : Flexible(child: Center(child: Padding(
            //   padding: const EdgeInsets.only(bottom: 50.0),
            //   child: Text(
            //     "No Data Found!", style: TextStyle(color: Colors.blue),),
            //     )
            //   )
            // );
          }

            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
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
                  selectedIndex: 0,
                  onSelected: (index, label) {
                    setState(() {
                      // _selectedSubCategoryIndex = index;
                      _selectedSubCategory = label;
                    });
                  }, labelBuilder: (label) => label,
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 10) / 2;
                        final itemHeight = SizeConfig.size220;
                        //
                        // final List<FoodServices> serviceData = _selectedSubCategory != null
                        //     ? professionMap[_selectedSubCategory] ?? []
                        //     : [];

                        return GridView.builder(
                          controller: scrollController,
                          itemCount: foodServicesList.length,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: itemWidth / itemHeight,
                          ),
                          itemBuilder: (context, index) => FoodCardBusiness(serviceData: GetFoodDetailsModel(photos: foodServicesList[index].data?.first.livePhotos),),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        // else{
        //     return Center(
        //         child: EmptyStateWidget(
        //           message: 'No service available.',
        //         )
        //     );
        //   }

          return SizedBox();
        // }
      }
      );
    }else if(mapServiceController.foodServiceResponse.value.status == Status.ERROR){
      return LoadErrorWidget(
          errorMessage: 'Failed to load food services',
          onRetry: () => getFoodServices());
    }

    return SizedBox();
  }
  Widget _buildServiceCard(FoodServicesData serviceData) {
    return InkWell(
      onTap: () {
        if (userId == serviceData) {
          Get.to(() => PersonalProfileSetupNewScreen());
        } else {
          Get.to(() => NewVisitProfileScreen(
            authorId: serviceData.userId ?? '',
            screenFromName: AppConstants.feedScreen,
          ));
        }

      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: 210,
                    imagePaths: [
                      serviceData.livePhotos?.firstOrNull ?? ""
                    ],
                    borderRadius: BorderRadius.zero,
                  ),
                ),

              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size10, horizontal: SizeConfig.size8),
              child: ProfileSummaryCard(
                name: serviceData.businessName ?? '',
                imageUrl: serviceData.logo ?? '',
                rating: (serviceData.totalRatings ?? 0).toDouble(),
                reviews:0,
                distance: "${serviceData.distance ?? 0} km",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: CommonIconContainerButton(
                      onTap: () async {
                        final chatViewController =
                        Get.find<ChatViewController>();
                        Map<String, dynamic> detas = {
                          ApiKeys.user_id: serviceData.id
                        };
                        chatViewController.newVisitContactApiResponse?.value;
                        await chatViewController.checkChatConnection(detas);

                        chatViewController.openAnyOneChatFunction(
                          isWithProductSend: false,
                          profileImage: serviceData.logo,
                          otherUserId: (chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.conversationId ??
                              '') ==
                              ""
                              ? chatViewController.newVisitContactApiResponse
                              ?.value?.data?.otherUserId ??
                              ''
                              : null,
                          businessId: "",
                          type: "business",
                          isInitialMessage: (chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.conversationId ??
                              '') ==
                              ""
                              ? true
                              : false,
                          userId: serviceData.id,
                          conversationId: (chatViewController
                              .newVisitContactApiResponse
                              ?.value
                              ?.data
                              ?.conversationId ??
                              ''),
                          contactName: serviceData.businessName,
                          contactNo: "",
                        );
                      },
                      icon: LocalAssets(
                          imagePath: AppIconAssets.quillChatIcon,
                          imgColor: AppColors.white),
                      label: "Chat",
                      backgroundColor: AppColors.primaryColor,
                      height: SizeConfig.size30,
                      fontSize: SizeConfig.size12,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

