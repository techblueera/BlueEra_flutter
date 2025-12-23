import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../../../widgets/local_assets.dart';
import '../../../../../hospital/view/widget/general_medicine.dart';
class ManagementAndTrust extends StatelessWidget {
  ManagementAndTrust({super.key});

  final List<DoctorItem> doctors = [
    DoctorItem(
      name: "Dr. Ramesh Gupta",
      qualification: "PHD",
      specialty: "Managing Director",
      timing: "Lorem Ipsum Dolor Amet Set....",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
    DoctorItem(
      name: "Dr. Sarmista Roy",
      qualification: "PHD",
      specialty: "Managing Director",
      timing: "Lorem Ipsum Dolor Amet Set....",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Management / Trust",
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          var item=doctors[index];
          return Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Doctor Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.image,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Name + Menu
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                  item.name,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainTextColor

                              ),
                            ),
                            InkWell(
                              // onTap: onMenuTap,
                              child: const Icon(Icons.more_vert, size: 20,
                                  color: AppColors.mainTextColor
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.greyE5,width: 1)
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              CustomText(
                                  item.qualification,
                                  fontSize: 10,  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                  item.specialty,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      "Message: ${item.timing}",
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),


                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
