import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widget/aadhar_card_widget.dart';
import '../widget/address_card_widget.dart';
import '../widget/driving_license_card_widget.dart';
import '../widget/pan_card_widget.dart';
import '../widget/rc_book_card_widget.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {

  final controller = getOrPut(() => MyDocumentsController());

  @override
  void initState() {
    controller.fetchAllDocumentStatusApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.addDocuments,
          isLeading: true,
        ),
        body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size15),
              child: Obx(()=>   Column(
                children: [
                  CustomFormCard(
                      padding: EdgeInsets.only(
                          top: SizeConfig.size16,
                          bottom: SizeConfig.size8
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                            child: CustomText(
                              AppStrings.personalDocument,
                              color: AppColors.mainTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.large,
                            ),
                          ),
                          SizedBox(
                              height: SizeConfig.size8
                          ),

                          _buildAddButton(
                            title: AppStrings.uploadAadhar,
                            status: controller.getStatus(DocumentKeys.aadhar),
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.aadharCard,
                                  child: AadharCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadPan,
                            status: controller.getStatus(DocumentKeys.pan),
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.panCard,
                                  child: PanCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadDrivingLicense,
                            status: controller.getStatus(DocumentKeys.drivingLicense),
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.drivingLicence,
                                  child: DrivingLicenceCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadVehicleRC,
                            status: controller.getStatus(DocumentKeys.vehicleRC),
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.rc,
                                  child: RcBookCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadAddressProof,
                            status: controller.getStatus(DocumentKeys.addressProof),
                            onTap: () {
                              Get.bottomSheet(
                                CommonDocumentBottomSheet(
                                  title: AppStrings.addressProof,
                                  child: AddressCardWidget(),
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadNOC,
                            status: controller.getStatus(DocumentKeys.noc),
                            onTap: () {
                              // Get.bottomSheet(
                              //   CommonDocumentBottomSheet(
                              //     title: AppStrings.panCard,
                              //     child: PanCardWidget(),
                              //   ),
                              //   isScrollControlled: true,
                              //   backgroundColor: Colors.transparent,
                              // );
                            },
                          ),
                          _buildAddButton(
                            title: AppStrings.uploadBankerCancelCheck,
                            status: controller.getStatus(DocumentKeys.bankersCancelledCheque),
                            onTap: () {

                            },
                          ),

                        ],
                      )
                  ),

                  // if(isBusinessUser())
                  ...[
                    SizedBox(
                        height: SizeConfig.paddingXSL
                    ),
                    CustomFormCard(
                        padding: EdgeInsets.only(
                            top: SizeConfig.size16,
                            bottom: SizeConfig.size8
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                              child: CustomText(
                                AppStrings.businessDocument,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),
                            ),
                            SizedBox(
                                height: SizeConfig.size8
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadGSTCertificate,
                              status: controller.getStatus(DocumentKeys.gstCertificate),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.panCard,
                                //     child: PanCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadFoodLicense,
                              status: controller.getStatus(DocumentKeys.fssaiLicense),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.aadharCard,
                                //     child: AadharCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMedicalLicense,
                              status: controller.getStatus(DocumentKeys.medicalLicense),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.panCard,
                                //     child: PanCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadFireSafetyCertificate,
                              status: controller.getStatus(DocumentKeys.fireSafetyCertificate),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.addressProof,
                                //     child: AddressCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMunicipalCorpCertificate,
                              status: controller.getStatus(DocumentKeys.municipalCorpCertificate),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.addressProof,
                                //     child: AddressCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadMSMECertificate,
                              status: controller.getStatus(DocumentKeys.msmeCertificate),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.addressProof,
                                //     child: AddressCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                            _buildAddButton(
                              title: AppStrings.uploadShopActCertificate,
                              status: controller.getStatus(DocumentKeys.shopActCertificate),
                              onTap: () {
                                // Get.bottomSheet(
                                //   CommonDocumentBottomSheet(
                                //     title: AppStrings.addressProof,
                                //     child: AddressCardWidget(),
                                //   ),
                                //   isScrollControlled: true,
                                //   backgroundColor: Colors.transparent,
                                // );
                              },
                            ),
                          ],
                        )
                    ),
                  ]

                 ],
               )
              ),
            )
        )

    );
  }

// Updated Button Builder
  Widget _buildAddButton({
    required String title,
    required VoidCallback onTap,
    required DocStatus status, // Changed from bool to Enum
  }) {
    // Determine if the button should be clickable (disable if pending or verified)
    bool isClickable = status == DocStatus.notUploaded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: isClickable ? onTap : null, // Disable click if uploaded
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.add,
                  color: isClickable ? AppColors.primaryColor : AppColors.secondaryTextColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Flexible(
                  child: CustomText(
                    title,
                    color: isClickable ? AppColors.primaryColor : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Status Icons Logic
        if (status != DocStatus.notUploaded)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: status == DocStatus.verified
                ? LocalAssets(imagePath: AppIconAssets.green_tick_icon) // Verified
                : LocalAssets(
                    imagePath: AppIconAssets.storeWatch,
                    imgColor: AppColors.yellow,
                    height: 20,
                    width: 20
            ), // Pending (isVerified: false)
          ),
      ],
    );
  }

}
