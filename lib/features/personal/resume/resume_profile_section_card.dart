import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/resume_common_delete_widget.dart';
import 'package:BlueEra/features/personal/resume/resume_common_edit_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ResumeProfileSectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onAddPressed;
  final void Function(int index)? itemsEditCallback;
  final void Function(int index)? itemsDeleteCallback;
  final Color? titleColor;
  final Color? subtitle1Color;
  final bool isPortfolioSection;

  const ResumeProfileSectionCard({
    required this.title,
    required this.items,
    this.onAddPressed,
    this.itemsEditCallback,
    this.itemsDeleteCallback,
    this.titleColor,
    this.subtitle1Color,
    this.isPortfolioSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title,
              color: AppColors.grey72, fontSize: SizeConfig.medium),
          SizedBox(height: SizeConfig.size15),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              width: SizeConfig.screenWidth,
              padding: EdgeInsets.all(SizeConfig.size10),
              margin: EdgeInsets.only(bottom: SizeConfig.size15),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey99, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['title'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomText(item['title']!,
                                    fontSize: SizeConfig.large,
                                    color: titleColor ?? AppColors.grey72,
                                    fontWeight: FontWeight.w400),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: SizeConfig.size3),
                                // child: Row(
                                //   crossAxisAlignment: CrossAxisAlignment.start,
                                //   children: [
                                //     ResumeCommonEditWidget(
                                //       imgColor: AppColors.grey72,
                                //       voidCallback: itemsEditCallback != null
                                //           ? () => itemsEditCallback!(index)
                                //           : () {},
                                //     ),
                                //     SizedBox(width: SizeConfig.size14),
                                //     // CommonDeleteWidget(voidCallback: () {}),
                                //     ResumeCommonDeleteWidget(
                                //       voidCallback: () =>
                                //           itemsDeleteCallback != null
                                //               ? itemsDeleteCallback!(index)
                                //               : () {},
                                //     ),
                                //   ],
                                // ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isPortfolioSection &&
                                        itemsEditCallback != null) ...[
                                      ResumeCommonEditWidget(
                                        imgColor: AppColors.grey72,
                                        voidCallback: () =>
                                            itemsEditCallback!(index),
                                      ),
                                      SizedBox(width: SizeConfig.size14),
                                    ],
                                    if (itemsDeleteCallback != null)
                                      ResumeCommonDeleteWidget(
                                        voidCallback: () =>
                                            itemsDeleteCallback!(index),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item['subtitle1'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(item['subtitle1']!,
                              fontSize: SizeConfig.large,
                              color: subtitle1Color ?? AppColors.grey72,
                              fontWeight: FontWeight.w400),
                        ),
                      if (item['trailing'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(item['trailing']!,
                              fontSize: SizeConfig.large,
                              color: AppColors.grey72,
                              fontWeight: FontWeight.w400),
                        ),
                      if (item['document'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: GridView.builder(
                            itemCount: item['document']!.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 4 / 3,
                            ),
                            itemBuilder: (context, index) {
                              var documentItem = item['document']![index];
                              Widget imageWidget;
                              if (documentItem is String &&
                                  (documentItem.startsWith("http://") ||
                                      documentItem.startsWith("https://"))) {
                                imageWidget = Image.network(documentItem,
                                    fit: BoxFit.cover);
                              } else {
                                imageWidget = Image.asset(documentItem,
                                    fit: BoxFit.cover);
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.primaryColor),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageWidget,
                                ),
                              );
                            },
                          ),
                        ),
                      if (item['subtitle2'] != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(item['subtitle2']!,
                              fontSize: SizeConfig.large,
                              color: AppColors.grey72,
                              fontWeight: FontWeight.w400),
                        ),
                      if (item['subtitle3'] != null &&
                          item['subtitle3']!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(item['subtitle3']!,
                              fontSize: SizeConfig.large,
                              color: AppColors.grey72,
                              fontWeight: FontWeight.w400),
                        ),
                    ]),
              ),
            );
          }),
          if (onAddPressed != null)
            InkWell(
              onTap: onAddPressed,
              child: Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                  SizedBox(width: SizeConfig.size4),
                  CustomText("Add $title",
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.large),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

