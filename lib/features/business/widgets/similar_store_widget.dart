import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/controller/view_business_details_controller.dart';

class SimilarStoreWidget extends StatelessWidget {
  const SimilarStoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
    Get.find<ViewBusinessDetailsController>();
    final businessData = controller.visitedBusinessProfileDetails?.relatedStoresList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              "Similar Stores",
              fontWeight: FontWeight.bold, fontSize: 16,
            ),
            InkWell(
              onTap: (){
                Get.back();
              },
              child: const CustomText(
                "View All",
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,

              ),
            ),
          ],
        ),

        SizedBox(
          height: 250,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(businessData?.length??0, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),

                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 200,
                        // width: 210,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            (businessData?[index].livePhotos?.isNotEmpty??false)?ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                "${businessData?[index].livePhotos?.first}",
                                height: 147,
                                width: 188,
                                fit: BoxFit.cover,
                              )
                            ):Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 147,
                                  width: 188,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.secondaryTextColor.withOpacity(0.2)
                                  ),
                                  child: Center(
                                    child: Icon(Icons.store_mall_directory_sharp,size: 44,color: AppColors.secondaryTextColor,),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      (businessData?[index].logo==''||businessData?[index].logo==null)?
                                      Container(
                                        width: 35,
                                        height: 35,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: AppColors.secondaryTextColor.withOpacity(0.2)
                                        ),
                                        child: Center(
                                          child: Icon(Icons.store_mall_directory_sharp,size: 20,color: AppColors.secondaryTextColor,),
                                        ),
                                      ):ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          "${businessData?[index].logo}",
                                          width: 35,
                                          height: 35,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 128,
                                            child: CustomText(
                                              "${businessData?[index].businessName??''}",
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis, // this adds "..."
                                              maxLines: 1,                     // ensures it doesn't wrap to the next line
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: List.generate(businessData?[index].avg_rating??0, (
                                                  starIndex,
                                                ) {
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        size: 10,
                                                        color: Colors.amber,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              Text(
                                                "  ${businessData?[index].avg_rating??0}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
