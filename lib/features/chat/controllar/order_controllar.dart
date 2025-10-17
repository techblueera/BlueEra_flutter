import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OrderNowController extends GetxController {
  var address = "".obs;

  void copyAddress() {
    Clipboard.setData(ClipboardData(text: address.value));
    commonSnackBar(message: "Copied Store location copied to clipboard");
  }
}

class OrderNowDialog {
  static void showDialogBox() {
    final controller = Get.put(OrderNowController());
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(0xffF1F1F3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText("Order Now",
                      fontSize: 22, fontWeight: FontWeight.bold),
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: LocalAssets(imagePath: AppIconAssets.close_black))
                ],
              ),
              SizedBox(height: SizeConfig.size10),

              // Step 1
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText("Step 1",
                        fontSize: 18, fontWeight: FontWeight.w600),
                    const SizedBox(height: 5),
                    const CustomText("Copy Store Location",
                        color: AppColors.secondaryTextColor),
                    const SizedBox(height: 10),

                    // Address Box with Copy Button
                    Obx(() => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: CustomText(
                                    controller.address.value,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    color: Colors.black54),
                                onPressed: controller.copyAddress,
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 25),

                    // Step 2
                    const CustomText("Step 2",
                        fontSize: 18, fontWeight: FontWeight.w600),
                    const SizedBox(height: 5),
                    const CustomText(
                      "Now Book Delivery Partner",
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 12),

                    // Buttons (Rapido & Porter)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size8),
                            ),
                            icon: LocalAssets(
                              imagePath: AppIconAssets.rapido,
                              height: SizeConfig.size30,
                              width: SizeConfig.size30,
                            ),
                            label: const CustomText("Rapido",
                                fontWeight: FontWeight.w600),
                            onPressed: () {
                              Get.back();
                              Get.to(CommonWebView(
                                urlLink: AppConstants.rapidoLink,
                                urlTitle: 'Rapido',
                              ));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size8),
                            ),
                            icon: LocalAssets(
                                imagePath: AppIconAssets.porter,
                                height: SizeConfig.size30,
                                width: SizeConfig.size30),
                            label: const CustomText("Porter",
                                fontWeight: FontWeight.w600),
                            onPressed: () {
                              Get.back();

                              Get.to(CommonWebView(
                                urlLink: AppConstants.porterLink,
                                urlTitle: 'Porter',
                              ));
                            },
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
      ),
    );
  }
}
