import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/doc_verification_pending_widget.dart';
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
                            document: DocumentKeys.aadhar,
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
                            document: DocumentKeys.pan,
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
                            document: DocumentKeys.drivingLicense,
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
                            document: DocumentKeys.vehicleRC,
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
                            document: DocumentKeys.addressProof,
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
                            document: DocumentKeys.noc,
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
                            document: DocumentKeys.bankersCancelledCheque,
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
                              document: DocumentKeys.gstCertificate,
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
                              document: DocumentKeys.fssaiLicense,
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
                              document: DocumentKeys.medicalLicense,
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
                              document: DocumentKeys.fireSafetyCertificate,
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
                              document: DocumentKeys.municipalCorpCertificate,
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
                              document: DocumentKeys.msmeCertificate,
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
                              document: DocumentKeys.shopActCertificate,
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

  Widget _buildAddButton({
    required String title,
    required String document,
    required VoidCallback onTap,
    required DocStatus status,
  }) {
    bool isUploadable = status == DocStatus.notUploaded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: status == DocStatus.verified
                ? null
                : () {
              if (status == DocStatus.pending) {
                _showPendingInstructionDialog(document);
              } else {
                onTap();
              }
            },
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.add,
                  // Use Primary color only for new uploads, otherwise Gray
                  color: isUploadable ? AppColors.primaryColor : AppColors.secondaryTextColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Flexible(
                  child: CustomText(
                    title,
                    // Use Primary color only for new uploads, otherwise Gray
                    color: isUploadable ? AppColors.primaryColor : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
          ),
        ),


        if (status != DocStatus.notUploaded)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: status == DocStatus.verified
                ? LocalAssets(imagePath: AppIconAssets.green_tick_icon)
                : LocalAssets(
              imagePath: AppIconAssets.storeWatch,
              imgColor: AppColors.yellow,
              height: 20,
              width: 20,
            ),
          ),
      ],
    );
  }

  void _showPendingInstructionDialog(String document) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: DocumentVerificationPendingWidget(
            documentName: document,
            // onOkayTap: ()=> Get.back()
          ),
        ),
      ),
    );
  }

}
