import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/model/service_model_response.dart';
import 'package:BlueEra/features/common/map/widget/profile_summary_card.dart';
import 'package:BlueEra/features/common/map/widget/sub_category_tab_bar.dart';
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

class HomeServicesBottomSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onClose;
  const HomeServicesBottomSheet({super.key, required this.onClose, required this.lat, required this.lng});

  @override
  State<HomeServicesBottomSheet> createState() => _HomeServicesBottomSheetState();
}

class _HomeServicesBottomSheetState extends State<HomeServicesBottomSheet> {
  final MapServiceController mapServiceController = Get.put(MapServiceController());
  int _selectedSubCategoryIndex = 0;
  String? _selectedSubCategory;
  final List<String> subCategories = [];

  @override
  initState(){
    super.initState();
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
    if (oldWidget.lat != widget.lat && oldWidget.lng != widget.lng) {
      if (widget.lat != 0.0 && widget.lng != 0.0) {
        print("called after getting lat lng");
        getHomeServices();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  void getHomeServices(){
    mapServiceController.fetchHomeService(
        lat: widget.lat,
        lng: widget.lng,
    );
  }

  @override
  Widget build(BuildContext context) {

    return CommonDraggableBottomSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
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
        return Obx((){
          if(mapServiceController.homeServiceResponse.value.status == Status.COMPLETE){

            if(mapServiceController.isHomeServiceLoading.isTrue) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            else{
                List<ServiceData> homeServiceList = mapServiceController.homeServiceList;
                if(homeServiceList.isNotEmpty){
                  final professionMap = mapServiceController.groupServicesByProfession(homeServiceList);

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
                        selectedIndex: _selectedSubCategoryIndex,
                        onSelected: (index, label) {
                          setState(() {
                            _selectedSubCategoryIndex = index;
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

                              final List<ServiceData> serviceData = _selectedSubCategory != null
                                  ? professionMap[_selectedSubCategory] ?? []
                                  : [];

                              return GridView.builder(
                                controller: scrollController,
                                itemCount: serviceData.length,
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(top: 12, bottom: 24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: itemWidth / itemHeight,
                                ),
                                itemBuilder: (context, index) => _buildServiceCard(serviceData[index]),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }else{
                  return Center(
                      child: EmptyStateWidget(
                        message: 'No service available.',
                      )
                  );
                }
              }

          }else if(mapServiceController.homeServiceResponse.value.status == Status.ERROR){
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
      onTap: (){
        // showModalBottomSheet(
        //   context: context,
        //   isScrollControlled: true,
        //   backgroundColor: Colors.transparent, // keep map visible under radius
        //   builder: (_) =>
        //       CommonDraggableBottomSheet(
        //         builder: (scrollController) =>
        //             OtherProfileDetailsBottomSheet(
        //               scrollController: scrollController,
        //               isUserProfile: true,
        //               isPlaceService: false,
        //               placeId: ''
        //             ),
        //       ),
        // );
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    serviceData.profileImage??'',
                    height: SizeConfig.size130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.blackD4,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CustomText(
                        'INR 100/-',
                        fontSize: SizeConfig.extraSmall,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10, horizontal: SizeConfig.size8),
              child: ProfileSummaryCard(
                name: serviceData.name??'',
                imageUrl: serviceData.profileImage??'',
                rating: (serviceData.rating ?? 0).toDouble(),
                reviews: serviceData.reviewCount??0,
                distance: '${(serviceData.distance ?? 0).toStringAsFixed(2)} km',
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: CommonIconContainerButton(
                      onTap: () {
                        if (userId == serviceData.id) {
                          Get.to(() => PersonalProfileSetupScreen());
                        } else {
                          Get.to(() => NewVisitProfileScreen(authorId: serviceData.id??'', screenFromName: AppConstants.feedScreen,));
                        }
                      },
                      icon: LocalAssets(imagePath: AppIconAssets.quillChatIcon, imgColor: AppColors.white),
                      label: "View",
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

