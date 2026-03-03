import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/campus_life_controller.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_details_screen.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/create_campus_life_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CampusLifeListingScreen extends StatefulWidget {
  const CampusLifeListingScreen({super.key});

  @override
  State<CampusLifeListingScreen> createState() =>
      _CampusLifeListingScreenState();
}

class _CampusLifeListingScreenState extends State<CampusLifeListingScreen> {
  final controller = Get.put(CampusLifeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:AppStrings.campusLife,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
              right: 10.0, left: 10.0, bottom: 40, top: 10),
          child: PositiveCustomBtn(
              bgColor: AppColors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              onTap: () {
                Get.to(CreateCampusLifeScreen());
              },
              title: AppStrings.addCampusLife),
        ),
      ),
      body: Obx((){
        if(controller.getAllCampusLifeDataList.isEmpty)
        {
          return Center(child: CustomText(AppStrings.noCampusPhotos));
        }

       return ListView.builder(
          itemCount: controller.getAllCampusLifeDataList.length,
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          itemBuilder: (context, index) {
            final category = controller.getAllCampusLifeDataList[index];
            final filteredSubcategories =
                category.subcategories?.where((sub) {
                  return (sub.entries?.isNotEmpty ?? false) &&
                      (sub.entries!.first.images?.isNotEmpty ?? false);
                }).toList() ??
                    [];

            return filteredSubcategories.isNotEmpty
                ? CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredSubcategories.isNotEmpty)
                    CustomText(category.name ?? "",
                        fontSize: 16, fontWeight: FontWeight.bold),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  // 2. Use the filtered list in the GridView
                  filteredSubcategories.isEmpty
                      ? SizedBox
                      .shrink() // Hide the whole category if no subcategories have images
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredSubcategories.length,
                    // Use filtered length
                    itemBuilder: (context, subIndex) {
                      final sub = filteredSubcategories[subIndex];
                      final imageUrl =
                          sub.entries!.first.images!.first.url ??
                              "";

                      return InkWell(
                        onTap: () {
                          Get.to(CampusLifeDetailsScreen(
                            subcategories: sub,
                          ));
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                  border: Border.all(
                                      color:
                                      Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (c, e, s) =>
                                        _placeholder(),
                                  )
                                      : _placeholder(),
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            CustomText(
                              sub.name ?? "",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
                : SizedBox.shrink();
          },
        );
      }),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400]),
    );
  }

}
