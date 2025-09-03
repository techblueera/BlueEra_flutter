import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/business_verification/view/widget/custom_dropdown_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({super.key});

  @override
  State<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends State<BusinessVerificationScreen> {
  TextEditingController gstNumberController = TextEditingController();
  String? selectedDocument;
  bool validate = false;
  String? imagePath;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
          isLeading: true,
          title: appLocalizations?.businessVerification
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
             child: Column(
               children: [
                 Align(
                   alignment: Alignment.centerLeft,
                   child: CustomText(
                     appLocalizations?.chooseWhatYouWantToVerify,
                     fontSize: SizeConfig.large,
                     fontWeight: FontWeight.w700,
                   ),
                 ),
                 SizedBox(
                   height: SizeConfig.size20,
                 ),
                 CommonTextField(
                   textEditController: gstNumberController,
                   inputLength: AppConstants.inputCharterLimit50,
                   keyBoardType: TextInputType.text,
                   // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                   title: appLocalizations?.enterGSTNumber,
                   hintText: appLocalizations?.enterGSTNumber,
                   isValidate: false,
                   onChange: (value) => validateForm(),
                 ),
                 SizedBox(
                   height: SizeConfig.size25,
                 ),
                 CustomText(
                   appLocalizations?.or,
                   fontSize: SizeConfig.extraLarge22,
                 ),
                 SizedBox(
                   height: SizeConfig.size25,
                 ),
                 // Document dropdown
                 CustomDropdownForDocumentType(
                   title: appLocalizations?.chooseDocumentType,
                   hint: appLocalizations?.selectADocumentType??"",
                   items: BusinessDocumentType.values,
                   onChanged: (value) {
                     log('Selected or Typed: $value');
                     setState(() {
                       selectedDocument = value;
                       validateForm();
                     });
                   },
                 ),
                 SizedBox(
                   height: SizeConfig.size5,
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

                 CustomBtn(
                     onTap: () {

                     },
                     title: appLocalizations?.verifyNow,
                     isValidate: validate
                 ),
               ],
             ),
          ),
        ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final gstNumber = gstNumberController.text.isNotEmpty;
    final ownerShipDocumentSelected = selectedDocument != null && selectedDocument!.isNotEmpty;
    final image = imagePath!=null && imagePath!.isNotEmpty;
    log("image--> $image");
    if ((gstNumber)
        || (ownerShipDocumentSelected && image)
    ) {
      validate = true;
      setState(() {});

      return;
    }

    validate = false;
    setState(() {});
  }

  ///SELECT IMAGE AND SHOW DIALOG...
  selectImage(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);

    imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        appLocalizations!.uploadYourDocumentPhoto);
    if (imagePath?.isNotEmpty ?? false) {
      ///SET IMAGE PATH...
      validateForm();
    }
  }

}
