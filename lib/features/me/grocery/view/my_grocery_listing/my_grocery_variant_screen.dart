import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/my_grocery_variant_card.dart';
import 'package:BlueEra/features/me/grocery/widget/common_cart_icon.dart';
import 'package:BlueEra/features/me/grocery/widget/go_to_cart_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';


class MyGroceryVariantScreen extends StatefulWidget {
  final List<ProductVariants> variants;
  final bool isMyGroceryStore;
  final bool? isShowInGrid;

  const MyGroceryVariantScreen({
    super.key,
    required this.variants,
    required this.isMyGroceryStore,
    this.isShowInGrid = true
  });

  @override
  State<MyGroceryVariantScreen> createState() => _MyGroceryVariantScreenState();
}

class _MyGroceryVariantScreenState extends State<MyGroceryVariantScreen> {
  final controller = getOrPut(() => GroceryController());
  final grocerCustomerController = Get.find<GroceryCustomerController>();
  final ScrollController scrollController = ScrollController();
  late List<ProductVariants> _variants;

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
        buildCustomActionWidget: () => (widget.isMyGroceryStore)
            ? SizedBox.shrink()
            : const CommonCartIcon(
            argIsDeliveredByRider: false
        ),

      ),
      bottomNavigationBar: widget.isMyGroceryStore ? null : const GoToCartButton(),
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
            child: MasonryGridView.count(
              controller: scrollController,
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size10
              ),
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              itemCount: _variants.length +
                  (controller.isGroceryDataLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                final variantItem = _variants[index];

                return MyGroceryVariantCard(
                  variant: variantItem,
                  isMyGroceryStore: widget.isMyGroceryStore,
                  isShowInGrid: true,
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
                  variant: variantItem,
                  isMyGroceryStore: widget.isMyGroceryStore,
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
