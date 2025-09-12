import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class InstaSliderNetwork extends StatefulWidget {
  const InstaSliderNetwork({
    super.key,
  });

  @override
  State<InstaSliderNetwork> createState() => _InstaSliderNetworkState();
}

class _InstaSliderNetworkState extends State<InstaSliderNetwork> {
  int _currentPage = 0;
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.width * 0.5,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView.builder(
        itemCount: msgPostController.uploadImageList.length,
        scrollDirection: Axis.horizontal, // swipe left/right
        controller: PageController(viewportFraction: 1.0), // full width page
        onPageChanged: (index){
          _currentPage=index;
          setState(() {

          });
        },
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: Get.width * 0.5,
                    width: Get.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      image: DecorationImage(
                        image: NetworkImage(
                            msgPostController.uploadImageList[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              if (msgPostController.uploadImageList.length > 1)
                // --- Page Indicator ---
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      "${_currentPage + 1}/${msgPostController.uploadImageList.length}",
                      color: Colors.white,
                    ),
                  ),
                ),

              /// --- Debug: Show image width ---
            ],
          );
        },
      ),
    );
  }
}
