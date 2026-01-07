import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/grocery_controller.dart';
import 'package:BlueEra/features/common/food/model/my_grocery_products_reponse.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/my_grocery_variant_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryVariantScreen extends StatefulWidget {
  final List<Variants> variants;
  final bool? isShowInGrid;

  const MyGroceryVariantScreen({
    super.key,
    required this.variants,
    this.isShowInGrid = true
  });

  @override
  State<MyGroceryVariantScreen> createState() => _MyGroceryVariantScreenState();
}

class _MyGroceryVariantScreenState extends State<MyGroceryVariantScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();
  late List<Variants> _variants;

  @override
  void initState() {
    super.initState();
    _variants = widget.variants;

      // WidgetsBinding.instance.addPostFrameCallback((_){
      // controller.fetchMyGroceryProducts(
      //     categoryId: widget.productId,
      //     isSubCategoryProducts: true
      // );
      //
      // scrollController.addListener(() {
      //   if (scrollController.position.pixels >=
      //       scrollController.position.maxScrollExtent - 200) {
      //     controller.fetchMyGroceryProducts(
      //         isLoadMore: true,
      //         categoryId: widget.productId,
      //         isSubCategoryProducts: true
      //     );
      //   }
      // });
      // });

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

      ),

      body: SafeArea(
        child:
        Builder(
          builder: (BuildContext context) {
          // Empty state
          if (_variants.isEmpty) {
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
                  itemCount: _variants.length +
                      (controller.isMyGroceryDataLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    final variantItem = _variants[index];

                    return MyGroceryVariantCard(
                      variantItem: variantItem,
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
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              final variantItem = _variants[index];

              return Padding(
                padding: EdgeInsets.only(bottom: dynamicSize(10)),
                child: MyGroceryVariantCard(
                  variantItem: variantItem,
                  isShowInGrid: false,
                ),
              );
            },
          );
        }, ),
      ),
    );
  }

}
