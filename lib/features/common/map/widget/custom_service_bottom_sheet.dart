import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';
import 'package:BlueEra/features/common/map/model/food_service_model_response.dart';
import 'package:BlueEra/features/common/map/widget/service_card.dart';
import 'package:BlueEra/features/common/map/widget/store_list_widget.dart';
import 'package:BlueEra/features/common/map/widget/sub_category_tab_bar.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
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

  int _selectedSubCategoryIndex = 0;
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

  _buildFoodServiceBody(ScrollController scrollController) {
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
              _selectedSubCategoryIndex = 0;
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

          //   return Column(
          //     children: [
          //       Align(
          //         alignment: Alignment.centerRight,
          //         child: Padding(
          //           padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          //           child: IconButton(
          //             iconSize: SizeConfig.size18,
          //             onPressed: () => widget.onClose(),
          //             icon: Icon(
          //               Icons.close,
          //               size: SizeConfig.size16,
          //               color: AppColors.black,
          //             ),
          //           ),
          //         ),
          //       ),
          //
          //       SubCategoryTabBar<String>(
          //         tabs: subCategories,
          //         selectedIndex: _selectedSubCategoryIndex,
          //         onSelected: (index, label) {
          //           setState(() {
          //             _selectedSubCategoryIndex = index;
          //             _selectedSubCategory = label;
          //           });
          //         }, labelBuilder: (label) => label,
          //       ),
          //
          //       Expanded(
          //         child: Padding(
          //           padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
          //           child: LayoutBuilder(
          //             builder: (context, constraints) {
          //               final itemWidth = (constraints.maxWidth - 10) / 2;
          //               final itemHeight = SizeConfig.size220;
          //
          //               final List<ServiceData> serviceData = _selectedSubCategory != null
          //                   ? professionMap[_selectedSubCategory] ?? []
          //                   : [];
          //
          //               return GridView.builder(
          //                 controller: scrollController,
          //                 itemCount: serviceData.length,
          //                 shrinkWrap: true,
          //                 padding: const EdgeInsets.only(top: 12, bottom: 24),
          //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //                   crossAxisCount: 2,
          //                   mainAxisSpacing: 10,
          //                   crossAxisSpacing: 10,
          //                   childAspectRatio: itemWidth / itemHeight,
          //                 ),
          //                 itemBuilder: (context, index) => _buildServiceCard(serviceData[index]),
          //               );
          //             },
          //           ),
          //         ),
          //       ),
          //     ],
          //   );
        //   }
        // else{
        //     return Center(
        //         child: EmptyStateWidget(
        //           message: 'No service available.',
        //         )
        //     );
        //   }

          return SizedBox();
        }
      }
      );
    }else if(mapServiceController.foodServiceResponse.value.status == Status.ERROR){
      return LoadErrorWidget(
          errorMessage: 'Failed to load food services',
          onRetry: () => getFoodServices());
    }

    return SizedBox();
  }

}

