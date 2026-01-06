import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/my_grocery_products_reponse.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/grocery_category_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryCategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const MyGroceryCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName});

  @override
  State<MyGroceryCategoryScreen> createState() => _MyGroceryCategoryScreenState();
}

class _MyGroceryCategoryScreenState extends State<MyGroceryCategoryScreen> {
  final controller = getOrPut(() => GroceryController());
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
          isSubCategoryProducts: false
      );

      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          controller.fetchMyGroceryProducts(
              categoryId: categoryId,
              isSubCategoryProducts: false,
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
        if (controller.isMyGroceryDataFirstLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final groceryList = List<MyGroceryProductsData>.from(controller.myGroceryProductsList);

        // Empty state
        if (groceryList.isEmpty) {
          return Center(
            child: CustomText(
                'Not found any grocery',
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w700
            ),
          );
        }

        return ListView.builder(
          itemCount: groceryList.length +
              (controller.isMyGroceryDataLoadingMore.value ? 1 : 0),
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

            final groceryProductsData = groceryList[index];

            return  GroceryCategoryCard(
                groceryProductsData: groceryProductsData,
            );
          },
        );
       }
      )
    );
  }
}



