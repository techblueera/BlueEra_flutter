import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DoctorListCard extends StatelessWidget {
  final DoctorItem item;
  final VoidCallback? onMenuTap;
  final VoidCallback? onManageLeave;

  const DoctorListCard({
    super.key,
    required this.item,
    this.onMenuTap,
    this.onManageLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                              fontSize: 10,  fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor
                        ),
                        const SizedBox(height: 4),

                        CustomText(
                          item.specialty,
                            fontSize: 10,
                            color: Colors.grey.shade600,

                        ),

                        const SizedBox(height: 4),

                        /// Availability
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                "Available: ${item.timing}",
                                fontSize: 10,
                              ),
                            ),
                            LocalAssets(imagePath: AppIconAssets.pen_line
                              ,height: 13,width: 13,),
                          ],
                        ),

                        const SizedBox(height: 6),

                        /// Fees
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CustomText(
                                    "Fees: ${item.fees}",
                                        fontSize: 10
                                  ),
                                  SizedBox(width: 8,),
                                  LocalAssets(imagePath: AppIconAssets.pen_line
                                  ,height: 13,width: 13,),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.primaryColor
                                )
                              ),
                              child: Center(
                                child: CustomText(
                                  "Manage Leave",
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,),
                              ),
                            )
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
  }
}
class DoctorItem {
  final String name;
  final String qualification;
  final String specialty;
  final String timing;
  final String fees;
  final String image;

  DoctorItem({
    required this.name,
    required this.qualification,
    required this.specialty,
    required this.timing,
    required this.fees,
    required this.image,
  });
}

class DoctorListView extends StatelessWidget {
  DoctorListView({super.key});

  final List<DoctorItem> doctors = [
    DoctorItem(
      name: "Dr. Ramesh Gupta",
      qualification: "MBBS",
      specialty: "Child Special",
      timing: "10:00 am - 05:00 pm (Mon-Fri)",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
    DoctorItem(
      name: "Dr. Sarmista Roy",
      qualification: "MBBS",
      specialty: "Child Special",
      timing: "10:00 am - 05:00 pm (Mon-Fri)",
      fees: "₹1000",
      image: "assets/category/medical/otc.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "General Medicine",
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          return DoctorListCard(
            item: doctors[index],
            onMenuTap: () {
              _showMenu(context);
            },
            onManageLeave: () {},
          );
        },
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit"),
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}

