import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/jobs/widget/dialog_card.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/common_drop_down.dart';
import '../../../../../../widgets/custom_text_cm.dart';

Future<void> showCustomDialog(BuildContext context) {
  final List<Map<String, dynamic>> allOptions = [
    {'icon': AppIconAssets.messageIcon, 'label': 'MESSAGE'},
    {'icon': AppIconAssets.angryIcon, 'label': 'CRITIQUE'},
    {'icon': AppIconAssets.storyIcon, 'label': 'STORY'},
    {'icon': AppIconAssets.job_post, 'label': 'JOB POST'},
    {'icon': AppIconAssets.shortsIcon, 'label': 'SHORTS'},
    {'icon': AppIconAssets.videoIcon, 'label': 'VIDEOS'},
    {'icon': AppIconAssets.travelIcon, 'label': 'TRAVEL'},
    {'icon': AppIconAssets.locationIcon, 'label': 'LOCATION'},
    {'icon': AppIconAssets.more_option, 'label': 'MORE'},
  ];

  String selectedType = 'Reels';

  return showDialog(
    context: context,
    barrierDismissible: true,

    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final filteredOptions = allOptions.where((item) {
          if (selectedType == 'Reels') {
            return item['label'] == 'SHORTS' || item['label'] == 'VIDEOS';
          } else {
            return item['label'] != 'SHORTS' && item['label'] != 'VIDEOS';
          }
        }).toList();

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          backgroundColor: Colors.white,

          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.8,
                      minHeight: 100,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXXXL),
                    padding: EdgeInsets.all(SizeConfig.paddingL),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(SizeConfig.size10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                "Post via",
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(
                                width: SizeConfig.size160,
                                height: SizeConfig.size45,
                                child: CommonDropdown<String>(
                                  items: ['Reels', 'Post'],
                                  selectedValue: selectedType,
                                  hintText: "Select Type",
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedType = val);
                                    }
                                  },
                                  displayValue: (val) => val,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size15),

                          /// Grid Section
                          GridView.builder(
                            itemCount: filteredOptions.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:filteredOptions.length>2? 3:2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (_, index) {
                              final item = filteredOptions[index];
                              return DialogCard(
                                icon: item['icon'],
                                label: item['label'],
                                onTap: () {},
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Close Button
                  Positioned(
                    bottom: -65,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                        ),
                        padding: EdgeInsets.all(SizeConfig.paddingS),
                        child: const Icon(Icons.close, color: AppColors.black, size: 25),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}


