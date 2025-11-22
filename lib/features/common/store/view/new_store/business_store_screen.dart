import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BusinessStoreScreen extends StatefulWidget {
  final String? typeOfBusiness;
  final String? selectedStoreCategoryId;
  final String? selectedStoreCategoryName;

  const BusinessStoreScreen({
    super.key,
    this.typeOfBusiness,
    this.selectedStoreCategoryId,
     this.selectedStoreCategoryName,
    });

  @override
  State<BusinessStoreScreen> createState() => _BusinessStoreScreenState();
}

class _BusinessStoreScreenState extends State<BusinessStoreScreen> {
  final controller = Get.isRegistered<NewStoreController>()
      ? Get.find<NewStoreController>()
      : Get.put(NewStoreController());
  final ScrollController storesScrollController = ScrollController();


  @override
    void initState() {
      log('init state called');
      controller.typeOfBusiness = widget.typeOfBusiness;
      controller.businessCategoryId = widget.selectedStoreCategoryId;
      controller.getAllStoreNearBy();
      storesScrollController.addListener(_onLoadMore);
      super.initState();
    }

    void _onLoadMore(){
      if (storesScrollController.position.pixels >=
          storesScrollController.position.maxScrollExtent - 200) {
        controller.getAllStoreNearBy(isLoadMore: true);
      }
    }

  @override
  void dispose() {
    storesScrollController.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
   final width = SizeConfig.screenWidth;

   double dynamicSize(double base) =>
       base * (width / 390);

   return Scaffold(
     appBar: CommonBackAppBar(),

     body: SafeArea(
       child: Obx(() {
         // First time loading
         if (controller.isAllStoreFirstLoading.value) {
           return const Center(child: CircularProgressIndicator());
         }
       
         // Empty state
         if (controller.allStore.isEmpty) {
           return Center(
             child: CustomText(
                 "${AppStrings.no.tr} ${widget.selectedStoreCategoryName} ${AppStrings.found.tr}.",
                 fontSize: SizeConfig.large,
                 color: AppColors.mainTextColor,
                 fontWeight: FontWeight.w700
             ),
           );
         }
       
         return ListView.builder(
           controller: storesScrollController,
           padding: EdgeInsets.all(SizeConfig.size15),
           itemCount: controller.allStore.length +
               (controller.isAllStoreLoadingMore.value ? 1 : 0),
           itemBuilder: (context, index) {

             // Pagination Loader
             if (index >= controller.allStore.length) {
               return const Padding(
                 padding: EdgeInsets.all(20),
                 child: Center(child: CircularProgressIndicator()),
               );
             }
       
             final storeData = controller.allStore[index];
             final String businessId = storeData.id ?? "";
       
             return VisibilityDetector(
               key: Key("business_$businessId"),
               onVisibilityChanged: (info) {
                 if (info.visibleFraction >= 0.5 && businessId.isNotEmpty) {
                   trackBusinessStoreView(businessId);
                 }
               },
               child: Padding(
                 padding: EdgeInsets.only(bottom: dynamicSize(10)),
                 child: BusinessStoreCard(
                   ds: dynamicSize,
                   getAllStoreResData: storeData,
                 ),
               ),
             );
           },
         );
       }),
     ),
   );
  }

  final Set<String> _viewedBusinessIds = {};

  void trackBusinessStoreView(String storeId) {
    if (kReleaseMode) {
      // call API asynchronously without blocking UI
      Future.microtask(() async {
        try {
          if (!_viewedBusinessIds.contains(storeId)) {
            _viewedBusinessIds.add(storeId);
            StoreRepo().businessByViewCountIDApi(businessId: storeId);
          }
        } catch (e) {
          print("Failed to track view: $e");
        }
      });
    }
  }
}
