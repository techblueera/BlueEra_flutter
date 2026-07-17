import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_card_adapter.dart';
import 'package:BlueEra/features/me/medical/widget/medical_floating_cart.dart';
import 'package:BlueEra/features/me/medical/widget/medical_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Every popular product for one pharmacy — the "View All" behind the detail
/// screen's popular rail. The pharmacy twin of
/// `AllTopSellingGroceryProductsScreen`.
///
/// Takes the list rather than fetching it: the pharmacy home payload already
/// carries every popular product, so there is nothing to page.
class AllPopularMedicalProductsScreen extends StatelessWidget {
  final List<PopularProduct> products;
  final MedicalCartBusiness businessCtx;

  const AllPopularMedicalProductsScreen({
    super.key,
    required this.products,
    required this.businessCtx,
  });

  @override
  Widget build(BuildContext context) {
    final cart = getOrPut(() => MedicalCartController(), permanent: true);
    // Drop entries with no usable variant id — the card would have nothing to
    // add to the cart.
    final cards = products
        .map((p) => p.toCardProduct())
        .whereType<MedicalCardProduct>()
        .toList();

    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.popularMedicalProducts.tr),
      // StackFit.expand so the cart stays pinned to the bottom even when the
      // body collapses to a short empty state.
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cards.isEmpty)
            Center(
              child: EmptyStateWidget(
                message: AppStrings.groceryViewNoXFound
                    .trParams({'name': AppStrings.popularMedicalProducts.tr}),
              ),
            )
          else
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childCount: cards.length,
                    itemBuilder: (context, i) => MedicalProductCard(
                      product: cards[i],
                      businessCtx: businessCtx,
                    ),
                  ),
                ),
                // Clears the floating cart pinned over the grid.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MedicalFloatingCart(controller: cart),
          ),
        ],
      ),
    );
  }
}
