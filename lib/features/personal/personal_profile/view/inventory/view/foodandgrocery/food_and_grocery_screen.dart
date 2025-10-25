import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../../core/api/apiService/api_keys.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../../common/food/controller/food_upload_controller.dart';
import '../../../../../../common/food/model/get_food_details_model.dart';

class FoodAndGroceryScreen extends StatefulWidget {
  final ProductServiceProviderType providerType;

  const FoodAndGroceryScreen({super.key, required this.providerType});

  @override
  State<FoodAndGroceryScreen> createState() => _FoodAndGroceryScreenState();
}

class _FoodAndGroceryScreenState extends State<FoodAndGroceryScreen>
    with RouteAware {
  final controller = Get.put(FoodUploadController());
  final ScrollController scrollController = ScrollController();
  late Map<String, dynamic> queryParams;

  @override
  void initState() {
    super.initState();

    queryParams = {
      ApiKeys.all: false,
      ApiKeys.type: "food",
      ApiKeys.providerType: widget.providerType.title,
    };

    // Only call API if first load or list is empty
    if (controller.foodDataList.isEmpty) {
      controller.getFoodService(queryParams);
    }

    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.getFoodService(queryParams, isLoadMore: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (controller.shouldRefresh) {
      controller.getFoodService(queryParams);
      controller.shouldRefresh = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isFoodDataFirstLoading.value) {
          const Center(
            child: CircularProgressIndicator(),
          );
        }

        if(controller.foodDataList.isNotEmpty) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: controller.foodDataList.length,
                  itemBuilder: (context, index) {
                    final food = controller.foodDataList[index];
                    return FoodItemCard(
                      controller: controller,
                      foodData: food,
                    ); // ✅ dynamic card
                  },
                ),
              ),

              if (controller.isFoodDataLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }else{
          return Center(child: Text('No food service found', style: TextStyle(fontSize: 18)));
        }
      }),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  const FoodItemCard({super.key, required this.controller, required this.foodData});

  final GetFoodDetailsModel foodData;
  final FoodUploadController controller;

  @override
  Widget build(BuildContext context) {

    final priceOptions = foodData.priceOptions;

    String priceText = "N/A";
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0, top: 2, left: 8, right: 8),
      child: InkWell(
        onTap: (){
          Get.to(()=> FoodDetailsViewScreen(
            productPriceFormat:(foodData.priceType == "single")?"${foodData.singlePrice ?? "0"}": "$priceText",
            data: foodData,
          ));
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE SECTION
              SizedBox(
                width: 140, // fixed width for image column
                height: 200, // fixed height (adjust as needed)
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: foodData.photos?.first ?? "",
                    fit: BoxFit.cover, // fills entire box
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),

              // CONTENT SECTION
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + menu button
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10.0,
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              foodData.title ?? "N/A",
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),

                          IconButton(
                              onPressed: () async {
                                await showCommonDialog(
                                context: context,
                                text: "Are you sure you want to delete this food service? Once deleted, it cannot be recovered.",
                                confirmText: 'Delete',
                                cancelText: 'Cancel',
                                confirmCallback: () {
                                  controller.deleteFoodService(serviceId: foodData.id ?? '');
                                },
                                cancelCallback: () {
                                  Get.back();
                                },
                                );
                              }, icon: Icon(
                            Icons.more_vert, color: Colors.black, size: 20,
                          ))
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Veg label + category
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: controller.getFoodTypeColor(foodData.vegType),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  foodData.vegType ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                foodData.category ?? "",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Description
                          Text(
                            foodData.description ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: (foodData.priceType == "single")
                                ? CustomText(
                              "Price : ₹ ${foodData.singlePrice ?? "0"}",
                              fontSize: SizeConfig.small,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              color: AppColors.primaryColor,
                            )
                                : CustomText(
                              "Price : ₹${priceText}",
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                            ),
                          ),
                          // Row(
                          //   children: [
                          //     Text("Small: ₹299",
                          //         style: TextStyle(fontWeight: FontWeight.w600)),
                          //     const SizedBox(width: 8),
                          //     Text("Medium: ₹499",
                          //         style: TextStyle(fontWeight: FontWeight.w600)),
                          //     const SizedBox(width: 8),
                          //     Text("Large: ₹799",
                          //         style: TextStyle(fontWeight: FontWeight.w600)),
                          //   ],
                          // ),
                          const SizedBox(height: 4),

                          // Discount
                          if (foodData.discounts != null &&
                              foodData.discounts!.isNotEmpty)
                            Text(
                              foodData.discounts!.first,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          const SizedBox(height: 6),

                          // Add-ons
                          if (foodData.addOns != null && foodData.addOns!.isNotEmpty)
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: foodData.addOns!
                                  .map((addon) => InkWell(
                                onTap: () {},
                                child: Text(
                                  addon,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ))
                                  .toList(),
                            )
                        ],
                      ),
                    )

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
