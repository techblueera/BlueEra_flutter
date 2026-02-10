import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_category_item.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/my_medical_super_category_model.dart';
import 'package:BlueEra/features/me/medical_new/widget/medical_category_item.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyMedicalSuperCategoryScreen extends StatefulWidget {
  const MyMedicalSuperCategoryScreen({super.key});

  @override
  State<MyMedicalSuperCategoryScreen> createState() => _MyMedicalSuperCategoryScreenState();
}

class _MyMedicalSuperCategoryScreenState extends State<MyMedicalSuperCategoryScreen> {
  final controller = getOrPut(() => MedicalController());

  @override
  void initState() {
    controller.fetchMyMedicalCategory();
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
          if (controller.myMedicalCategoryLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final medicalCategoryList = List<MyMedicalSuperCategoryModel>.from(controller.myMedicalCategoryList);

          // Empty state
          if (medicalCategoryList.isEmpty) {
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
            itemCount: medicalCategoryList.length,
            padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              top: SizeConfig.size15,
              bottom: SizeConfig.size30,
            ),
            itemBuilder: (context, index) {
              var item = medicalCategoryList[index];

              return MedicalCategoryItem(
                url: item.image??'',
                label: item.name??'',
                onTap: () {

                  Get.toNamed(RouteHelper.getMyMedicalProductsScreenRoute(),
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



