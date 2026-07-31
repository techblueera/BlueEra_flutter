import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/media_autoplay_list.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TutorialTab extends StatefulWidget {
  final ReferralController controller;
  const TutorialTab({super.key, required this.controller});

  @override
  State<TutorialTab> createState() => _TutorialTabState();
}

class _TutorialTabState extends State<TutorialTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller.tutorials.isEmpty) {
      widget.controller.fetchTutorials();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size10,
        SizeConfig.paddingXSL,
        SizeConfig.size10,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final status = widget.controller.tutorialsResponse.value.status;
            if (status == Status.INITIAL || status == Status.LOADING) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (status == Status.ERROR) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CustomText(
                    AppStrings.somethingWentWrong,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ),
              );
            }
            final items = widget.controller.tutorials;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CustomText(
                    AppStrings.noTutorialsYet,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ),
              );
            }
            return MediaAutoplayList(items: items.toList());
          }),
        ],
      ),
    );
  }
}
