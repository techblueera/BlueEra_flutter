import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/my_grocery_products_reponse.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryScreen extends StatefulWidget {
  final String categoryId;
  final bool? isShowInGrid;

  const MyGroceryScreen({
    super.key,
    required this.categoryId,
    this.isShowInGrid = true
  });

  @override
  State<MyGroceryScreen> createState() => _MyGroceryScreenState();
}

class _MyGroceryScreenState extends State<MyGroceryScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_){
      controller.fetchMyGroceryProducts(
          categoryId: widget.categoryId,
          isSubCategoryProducts: true
      );

      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          controller.fetchMyGroceryProducts(
              isLoadMore: true,
              categoryId: widget.categoryId,
              isSubCategoryProducts: true
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
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) =>
        base * (width / 390);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Grocery & Veg',
      ),

      body: SafeArea(
        child:
        Obx(() {
          // First time loading
          if (controller.isMyGroceryDataFirstLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final groceryProductsVariantList = List<Variants>.from(controller.myGroceryProductsVariantsList);

          // Empty state
          if (groceryProductsVariantList.isEmpty) {
            return Center(
              child: CustomText(
                  'Not found any grocery',
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700
              ),
            );
          }

          return (widget.isShowInGrid ?? false)
              ? Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size8
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = 2;
                final crossSpacing = 10.0;
                final mainSpacing = 10.0;

                final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
                final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

                final approximateItemHeight = SizeConfig.size280;

                final childAspectRatio = itemWidth / approximateItemHeight;

                return GridView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size10
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: groceryProductsVariantList.length +
                      (controller.isMyGroceryDataLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= groceryProductsVariantList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final groceryProductsVariantItem = groceryProductsVariantList[index];

                    return MyGroceryCard(
                      groceryProductsVariantItem: groceryProductsVariantItem,
                      isShowInGrid: true,
                    );
                  },
                );
              },
            ),
          )
              : ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size8
            ),
            itemCount: groceryProductsVariantList.length +
                (controller.isMyGroceryDataLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              // Pagination Loader
              if (index >= groceryProductsVariantList.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final groceryProductsVariantItem = groceryProductsVariantList[index];

              return Padding(
                padding: EdgeInsets.only(bottom: dynamicSize(10)),
                child: MyGroceryCard(
                  groceryProductsVariantItem: groceryProductsVariantItem,
                  isShowInGrid: false,
                ),
              );
            },
          );
        }),
      ),
    );
  }

}
