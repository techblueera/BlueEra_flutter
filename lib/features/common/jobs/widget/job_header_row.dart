import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/controller/job_details_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobHeaderRow extends StatelessWidget {
  final String logoUrl;
  final String title;
  final String companyName;
  final String? trailingIconPath;
  final String? jobId;
  final String? businessUserId;
  final Color? companyNameColor;

  const JobHeaderRow({
    Key? key,
    required this.logoUrl,
    required this.title,
    required this.companyName,
    required this.jobId,
    required this.businessUserId,
    this.trailingIconPath,
    this.companyNameColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        openBusinessProfile(businessUserId: businessUserId);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size4),
            child: CommonCircularImage(url: logoUrl),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: SizeConfig.extraLarge,
                  color: AppColors.black28,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  companyName,
                  color: companyNameColor ?? AppColors.black28,
                ),
              ],
            ),
          ),
          if (trailingIconPath != null &&
              (trailingIconPath?.isNotEmpty ?? false)) ...[
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.size4),
              child: InkWell(
                  onTap: () async {
                    ///SAVE & UNSAVED JOB POST...
                    if (Get.find<JobDetailsScreenController>()
                            .jobDetails
                            .value
                            ?.isSavedByUser ==
                        false) {
                      await Get.find<JobScreenController>()
                          .savedJobPostController(jobId: jobId);
                      await Get.find<JobDetailsScreenController>()
                          .fetchJobDetails(jobId ?? "");
                    } else if (Get.find<JobDetailsScreenController>()
                            .jobDetails
                            .value
                            ?.isSavedByUser ==
                        true) {
                      await Get.find<JobScreenController>()
                          .savedJobDeleteController(jobId: jobId);
                      await Get.find<JobDetailsScreenController>()
                          .fetchJobDetails(jobId ?? "");
                    }
                  },
                  child: LocalAssets(
                    imagePath: (Get.find<JobDetailsScreenController>()
                                .jobDetails
                                .value
                                ?.isSavedByUser ??
                            false)
                        ? AppIconAssets.save_fill
                        : trailingIconPath ?? "",
                  )),
            ),
          ]
        ],
      ),
    );
  }
}
