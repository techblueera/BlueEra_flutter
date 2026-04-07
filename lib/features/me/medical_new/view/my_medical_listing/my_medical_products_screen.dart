import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/view/my_medical_listing/medical_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/my_medical_products_response.dart';

class MyMedicalProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const MyMedicalProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName});

  @override
  State<MyMedicalProductsScreen> createState() => _MyMedicalProductsScreenState();
}

class _MyMedicalProductsScreenState extends State<MyMedicalProductsScreen> {
  final controller = getOrPut(() => MedicalController());
  final ScrollController scrollController = ScrollController();
  late String categoryId;
  late String categoryName;

  @override
  void initState() {
    super.initState();
    categoryId = widget.categoryId;
    categoryName = widget.categoryName;
    WidgetsBinding.instance.addPostFrameCallback((_){
      controller.fetchMyGroceryProducts(
          categoryId: categoryId,
      );

      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          controller.fetchMyGroceryProducts(
              categoryId: categoryId,
              isLoadMore: true
          );
        }
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: categoryName,
      ),
      body: Obx((){
        // First time loading
        if (controller.isMyMedicalDataFirstLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final groceryList = List<Products>.from(controller.myMedicalProductsList);

        // Empty state
        if (groceryList.isEmpty) {
          return Center(
            child: CustomText(
                AppStrings.medicalNoProductsInCategory,
                fontSize: SizeConfig.large,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500
            ),
          );
        }

        return ListView.builder(
          itemCount: groceryList.length +
              (controller.isMyMedicalDataLoadingMore.value ? 1 : 0),
          controller: scrollController,
          padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              top: SizeConfig.size15,
              bottom: SizeConfig.size15 + kBottomNavigationBarHeight
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index >= groceryList.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final medicalProducts = groceryList[index];

            return  MedicalProductCard(
                medicalProducts: medicalProducts,
                categoryId: categoryId,
            );
          },
        );
       }
      )
    );
  }
}



