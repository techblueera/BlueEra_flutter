import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class RatingSummaryWidget extends StatefulWidget {
  final double rating;
  final String userId;
  final String screenFromName;

  const RatingSummaryWidget({
    Key? key,
    required this.rating,
    required this.userId,
    required this.screenFromName,
  }) : super(key: key);

  @override
  State<RatingSummaryWidget> createState() => _RatingSummaryWidgetState();
}

class _RatingSummaryWidgetState extends State<RatingSummaryWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.all(12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(0),
enabled: false,
          trailing: /*widget.screenFromName == AppConstants.chatScreen
              ? Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.mainTextColor,
                )
              :*/ SizedBox(),
          // onExpansionChanged: (expanded) {
          //   setState(() {
          //     _isExpanded = expanded;
          //   });
          // },
          onExpansionChanged: (val)=>null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText("Rating Summary",
                  fontSize: 16, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    widget.rating.toStringAsFixed(1),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < widget.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return InkWell(
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();

                        return;
                      }
                      logs("userId ${widget.userId}");
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return RatingFeedbackDialog(
                            businessId: widget.userId,
                            reviewFor: AppConstants.individual ?? "",
                          );
                        },
                      );
                    },
                    child: LocalAssets(imagePath: AppIconAssets.star_rounded));
              }),
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),
            // Expanded rating details
            // Column(
            //   children: List.generate(5, (index) {
            //     int stars = 5 - index;
            //     return Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 4),
            //       child: Row(
            //         children: [
            //           Text("$stars"),
            //           const SizedBox(width: 4),
            //           const Icon(Icons.star, color: Colors.amber, size: 18),
            //           const SizedBox(width: 8),
            //           Expanded(
            //             child: LinearProgressIndicator(
            //               value: (stars * 0.2), // dummy distribution
            //               backgroundColor: Colors.grey.shade200,
            //               valueColor:
            //               const AlwaysStoppedAnimation<Color>(Colors.amber),
            //             ),
            //           ),
            //           const SizedBox(width: 8),
            //           Text("${stars * 200}"), // dummy review count
            //         ],
            //       ),
            //     );
            //   }),
            // )
          ],
        ),
      ),
    );
  }
}
