import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../../../widgets/custom_text_cm.dart';
class CategoryItem {
  final String title;
  final String lastUpdate;
  final String image;
  final int productCount;

  CategoryItem({
    required this.title,
    required this.lastUpdate,
    required this.image,
    required this.productCount,
  });
}

class _CategoryListCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const _CategoryListCard({
    required this.item,
    this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(left: 10,right: 6,top: 10,bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [AppShadows.textFieldShadow],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.image,
                    height: 122,
                    width: 182,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 10,
                  child: Container(
                    padding:
                    const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomText(
                      "+${item.productCount} Product",
                      fontSize: 12,
                      color: AppColors.liteWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),


            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [


                  CustomText(
                    item.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    "Last Update:",
                    fontSize: 10,
                    fontWeight: FontWeight.w400,

                    color: AppColors.secondaryTextColor,
                    fontFamily:  AppConstants.Regular,
                  ),CustomText(
                    "${item.lastUpdate}",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,

                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),

            InkWell(
              onTap: onMenuTap,
              child: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.mainTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  CategoryListView({super.key});

  final List<CategoryItem> items = [
    CategoryItem(
      title: "OTC Items",
      lastUpdate: "20 April, 2025",
      image: "assets/category/medical/otc.png",
      productCount: 10,
    ),
    CategoryItem(
      title: "Patanjali Product",
      lastUpdate: "20 April, 2025",
      image: "assets/category/medical/otc.png",
      productCount: 10,
    ),
    CategoryItem(
      title: "General Medicines",
      lastUpdate: "20 April, 2025",
      image: "assets/category/medical/otc.png",
      productCount: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8,vertical: SizeConfig.size10),
        itemBuilder: (context, index) {
          return _CategoryListCard(
            item: items[index],
            onTap: () {

            },
            onMenuTap: () {
              _showMenu(context);
            },
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
                title: CustomText("Edit"),
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: CustomText("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}

