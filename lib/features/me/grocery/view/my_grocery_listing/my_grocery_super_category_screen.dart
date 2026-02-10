import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/my_grocery_super_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_category_item.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGrocerySuperCategoryScreen extends StatefulWidget {
  const MyGrocerySuperCategoryScreen({super.key});

  @override
  State<MyGrocerySuperCategoryScreen> createState() => _MyGrocerySuperCategoryScreenState();
}

class _MyGrocerySuperCategoryScreenState extends State<MyGrocerySuperCategoryScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  void initState() {
    controller.fetchMyGroceryCategory();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Obx((){
          // First time loading
          if (controller.myGroceryCategoryLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final groceryCategoryList = List<MyGrocerySuperCategoryModel>.from(controller.myGroceryCategoryList);

          // Empty state
          if (groceryCategoryList.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                   message: 'You Have Nor Post any Product',
                   actionText: 'Add Product Now!',
                   actionCallback: ()=> Get.toNamed(
                       RouteHelper.getGrocerySuperCategoryScreenRoute(),
                       arguments: {ApiKeys.argMyGrocery: true}
                   ),
              ),
            );
          }

          return ListView.builder(
            itemCount: groceryCategoryList.length,
            padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              top: SizeConfig.size15,
              bottom: SizeConfig.size30,
            ),
            itemBuilder: (context, index) {
              var item = groceryCategoryList[index];

              return GroceryCategoryItem(
                url: item.image??'',
                label: item.name??'',
                onTap: () {

                  Get.toNamed(RouteHelper.getMyGroceryProductsScreenRoute(),
                    arguments: {
                      ApiKeys.argCategoryId: item.sId,
                      ApiKeys.argCategoryName: item.name
                    },
                  );

                },
              );

            },
          );
        }
        )
    );
  }
}



