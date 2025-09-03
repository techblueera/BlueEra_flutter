import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_delete_widget.dart';
import 'package:BlueEra/widgets/common_edit_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/snackbar_helper.dart';


class ProfileSectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final VoidCallback onAddPressed;
  final Function(Map<String, dynamic> item)? onDeletePressed;
  final Function(Map<String, dynamic> item)? onEditPressed;
  final RxList<LanguageType> speakLanguages = <LanguageType>[].obs;
  final RxList<LanguageType> writeLanguages = <LanguageType>[].obs;
  final double? customTitleFontSize;
  final FontWeight? customTitleFontWeight;
  final bool showEdit;

  ProfileSectionCard({
    required this.title,
    required this.items,
    required this.onAddPressed,
    this.onDeletePressed,
    this.onEditPressed,
    this.showEdit = true,
    this.customTitleFontSize,
    this.customTitleFontWeight,

  });

  @override
  Widget build(BuildContext context) {
    bool _isValidUrl(String? input) {
      if (input == null) return false;
      final uri = Uri.tryParse(input);
      return uri != null && (uri.isScheme("http") || uri.isScheme("https"));
    }

    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title,
              color: AppColors.grey72, fontSize: SizeConfig.medium),
          SizedBox(height: SizeConfig.size15),
          ...items.map((item) => Container(
                width: SizeConfig.screenWidth,
                padding: EdgeInsets.all(SizeConfig.size10),
                margin: EdgeInsets.only(bottom: SizeConfig.size15),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey99, width: 0.5),
                    borderRadius: BorderRadius.circular(10)),
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
                                child: CustomText(
                                  item['title']!,
                                  fontSize: customTitleFontSize ?? SizeConfig.large,
                                  color: AppColors.black28,
                                  fontWeight: customTitleFontWeight ?? FontWeight.w400,
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.only(top: SizeConfig.size3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showEdit && onEditPressed != null)
                                      CommonEditWidget(
                                        imgColor: AppColors.grey72,
                                        voidCallback: () => onEditPressed!(item),
                                      ),

                                    SizedBox(width: SizeConfig.size14),
                                    if (onDeletePressed != null)
                                      CommonDeleteWidget(
                                        voidCallback: () => onDeletePressed!(item),
                                      ),

                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      if (item['subtitle1'] != null && item['subtitle1']!.toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: _isValidUrl(item['subtitle1'])
                              ? InkWell(
                            onTap: () async {
                              final uri = Uri.parse(item['subtitle1']);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                commonSnackBar(message: "Could not launch URL");
                              }
                            },
                            child: Text(
                              item['subtitle1'],
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                              : CustomText(
                            item['subtitle1'],
                            fontSize: SizeConfig.large,
                            color: AppColors.grey72,
                            fontWeight: FontWeight.w400,
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
                              crossAxisCount: 3, // 3 per row
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 4 /
                                  3, // Adjust for your certificate dimensions
                            ),
                            itemBuilder: (context, index) {
                              var documentItem = item['document']![index];
                              return Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primaryColor)),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      documentItem,
                                      fit: BoxFit.cover,
                                    )),
                              );
                            },
                          ),
                        )
                    ],
                  ),
                ),
              )),
          if (items.isEmpty)
            InkWell(
              onTap: onAddPressed,
              child: Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                  SizedBox(width: SizeConfig.size4),
                  CustomText("Add $title",
                      color: AppColors.primaryColor, fontSize: SizeConfig.large),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
