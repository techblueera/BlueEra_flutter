import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../auth/controller/view_business_details_controller.dart';

class OwnershipVerificationScreen extends StatefulWidget {

  const OwnershipVerificationScreen({super.key});

  @override
  State<OwnershipVerificationScreen> createState() => _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState extends State<OwnershipVerificationScreen> {
  OwnershipDocumentType? _selectedOwnershipDocument;
  bool validate = false;
  String? imagePath;
  String? imagePathUrl;
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();

  void verify()async {
    if (_selectedOwnershipDocument!=null&&imagePath!=null) {
      Map<String,dynamic>? data;
      if(imagePathUrl!=null){
        data={
          ApiKeys.docType:_selectedOwnershipDocument?.displayName,
          ApiKeys.document:imagePathUrl,
        };
        viewBusinessDetailsController.postVerifyOwnerBusinessDocs(data);
      }else{
        String fileName = imagePath?.split('/').last ?? "";
        dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(imagePath ?? "",
            filename: fileName);
         data={
          ApiKeys.docType:_selectedOwnershipDocument?.displayName,
          ApiKeys.document:imageByPart,
        };
      }
      viewBusinessDetailsController.postVerifyOwnerBusinessDocs(data);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide the required information')),
      );
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    if(viewBusinessDetailsController.viewBusinessVerifyStatus!=null){
      if(viewBusinessDetailsController.viewBusinessVerifyStatus?.value.ownerDoc!=null){
        _selectedOwnershipDocument=OwnershipDocumentType.fromDisplayName(viewBusinessDetailsController.viewBusinessVerifyStatus?.value.ownerDoc?.docType??'');
        imagePath=viewBusinessDetailsController.viewBusinessVerifyStatus?.value.ownerDoc?.docUrl??'';
        imagePathUrl=viewBusinessDetailsController.viewBusinessVerifyStatus?.value.ownerDoc?.docUrl??'';
      }

    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Ownership Verification",
      ),
      body:Padding(
        padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size20,vertical:  SizeConfig.size20,),
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
          ),

          padding: EdgeInsets.all( SizeConfig.size12,),
          child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      appLocalizations?.uploadOneDocumentToVerifyYourIdentityAsTheBusinessOwner,
                      fontSize: SizeConfig.large,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CustomText(color: Colors.black,
                      appLocalizations?.theNameOnTheDocumentShouldMatchYourPanName,
                      fontSize: SizeConfig.small,
                      fontStyle: FontStyle.italic,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CustomText(color: Colors.black,
                      appLocalizations?.chooseDocumentType,
                      fontSize: SizeConfig.size14,
                    ),
                    SizedBox(
                      height: SizeConfig.size12,
                    ),
                    CommonDropdown<OwnershipDocumentType>(
                      items: OwnershipDocumentType.values,
                      selectedValue: _selectedOwnershipDocument,
                      hintText: AppConstants.selectProfession,
                      displayValue: (ownershipDocumentType) =>
                      ownershipDocumentType.displayName,
                      onChanged: (value) {
                        setState(() {
                          _selectedOwnershipDocument = value;
                          validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          // return appLocalizations??.selectYourProfession;
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: SizeConfig.size12,
                    ),
                    CommonDocumentPicker(
                      imagePath: imagePath,
                      onClear: () {
                        setState(() {
                          imagePath = null;
                        });
                        validateForm(); // or your custom logic
                      },
                      onSelect: (context) {
                        selectImage(context); // your method to pick image
                      },
                    ),
                    SizedBox(
                      height: SizeConfig.size18,
                    ),
                    CustomBtn(
                        onTap: () {
                          verify();
                        },
                        title: appLocalizations?.verifyNow,
                        isValidate: validate
                    ),
                  ],
                ),
              )
          ),
        ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final ownerShipDocumentSelected = _selectedOwnershipDocument != null && _selectedOwnershipDocument!.displayName.isNotEmpty;
    final image = imagePath!=null && imagePath!.isNotEmpty;
    log("image--> $image");
    if (!ownerShipDocumentSelected
         || !image
     ) {
      validate = false;
      setState(() {});

      return;
    }

    validate = true;
    setState(() {});
  }

  ///SELECT IMAGE AND SHOW DIALOG...
  selectImage(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);

    imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        appLocalizations!.uploadYourDocumentPhoto);
    imagePathUrl=null;
    if (imagePath?.isNotEmpty ?? false) {
      ///SET IMAGE PATH...
      validateForm();
    }
  }

}
