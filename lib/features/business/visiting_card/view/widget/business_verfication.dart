import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../../../widgets/common_document_picker.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../../auth/controller/view_business_details_controller.dart';

class BusinessVerification extends StatefulWidget {
  const BusinessVerification({super.key});

  @override
  State<BusinessVerification> createState() => _BusinessVerificationState();
}

class _BusinessVerificationState extends State<BusinessVerification> {
  final TextEditingController gstController = TextEditingController();
  final TextEditingController docController = TextEditingController();
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();
  bool isFormComplete() {
    return gstController.text.isNotEmpty ||
        (selectedDocType != null && selectedImage != null);
  }

  String? selectedDocType;
  String? customDocType;
  bool showOtherField = false;

  String? selectedImage;

  final List<String> documentTypes = [
    'Udhyam / MSME Certificate',
    'Shop Act License',
    'Labor License',
    'Business Pan Card',
    'Fssai/ Foods License',
    'Medical License',
  ];

  // Pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {

    }
  }


  void verify() async {
    final selectedDocument = customDocType ?? selectedDocType;

    if (gstController.text.isNotEmpty ||
        (selectedDocument != null && selectedImage != null)) {
      String fileName = selectedImage?.split('/').last ?? "";
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(selectedImage ?? "",
          filename: fileName);
      Map<String,dynamic> data={
       if(gstController.text.isNotEmpty)
         ApiKeys.docNumber:gstController.text
        else
          ApiKeys.docType:selectedDocType,

        if(gstController.text.isEmpty)ApiKeys.document:imageByPart
      };
      viewBusinessDetailsController.postVerifyBusinessDocs(data);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide the required information')),
      );
    }
  }

 String? updateActualValue(){
   String apiValue= viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc?.docType?.toLowerCase()??'';
   int? gettedVal= documentTypes.indexWhere((elemnt)=>elemnt.toLowerCase().contains("${apiValue}"));
   if(gettedVal!=-1){
     return '${documentTypes[gettedVal]}';
   }else{
     return null;
   }

}
  @override
  void initState() {
    // TODO: implement initState
    if(viewBusinessDetailsController.viewBusinessVerifyStatus!=null){
      if(viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc!=null){
        if(viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc?.docType=="GST"){
          gstController.text=viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc?.docNumber??'';
        }else{
          selectedImage=viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc?.docUrl??"";
          selectedDocType=updateActualValue();
        }
      }

    }
    super.initState();
  }
  selectImage(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);

    selectedImage = await SelectProfilePictureDialog.showLogoDialog(
        context,
        appLocalizations!.uploadYourDocumentPhoto);
    setState(() {

    });
    if (selectedImage?.isNotEmpty ?? false) {
      ///SET IMAGE PATH...

    }
  }

  @override
  Widget build(BuildContext context) {
    print("lakdcmlksdc ${viewBusinessDetailsController.viewBusinessVerifyStatus?.value.businessDoc?.docType}");
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
        backgroundColor: AppColors.white,
        appBar: CommonBackAppBar(
          title: "Business Verification",
          titleColor: Colors.black,
          appBarColor: AppColors.white,
        ),

        body:  SizedBox(
          height: 600,
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size20,vertical:  SizeConfig.size20,),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.bottomAndTopShadow
              ),
              padding: EdgeInsets.all( SizeConfig.size18,),
              child: ListView(
                  children: [
                    const SizedBox(height: 8,),
                    CustomText("Choose one method to verify your business.",fontWeight: FontWeight.w700,fontSize: SizeConfig.size18,color: AppColors.black,),

                    SizedBox(height: 31),

                    CommonTextField(

                      textEditController: gstController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                      title: appLocalizations?.enterGSTNumber,
                      hintText: appLocalizations?.enterGSTNumber,
                      isValidate: false,
                    ),
                    SizedBox(height: 16),
                    Center(child: CustomText("Or",fontWeight: FontWeight.w600,fontSize: SizeConfig.size18,color: AppColors.black,)),
                    SizedBox(height: 16),
                    CustomText("Choose Document Type",fontWeight: FontWeight.w400,fontSize: SizeConfig.size14,color: AppColors.black),
                    SizedBox(
                      height: 8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(

                          focusColor: AppColors.fillColor,
                          dropdownColor:AppColors.fillColor,
                          style: TextStyle(
                              color: Colors.black, fontSize: 16, fontFamily: AppConstants.OpenSans),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(18),
                            filled: true,
                            fillColor:  AppColors.fillColor,
                            border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey99,),
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          value: selectedDocType,
                          hint: Text(
                            "Select a document type",
                            style: TextStyle(color: Colors.black),
                          ),
                          items: [
                            ...documentTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            )),
                            DropdownMenuItem(
                              value: "Other Govt License",
                              child: Text("Other Govt License"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              gstController.clear();
                              selectedDocType = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),

                        if(selectedDocType=='Other Govt License')
                          TextField(
                            controller: docController,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Enter Document Type',
                              hintStyle: TextStyle(color: Color(0xFF7A8B9A)),
                              filled: true,
                              contentPadding: EdgeInsets.all(18),
                              fillColor: AppColors.fillColor,
                              border:
                              OutlineInputBorder(borderRadius: BorderRadius.circular(2),borderSide: BorderSide(color: AppColors.grey99)),
                            ),
                          ),
                        if(selectedDocType=="Other Govt License")
                          SizedBox(height: 20),
                        CommonDocumentPicker(
                          imagePath: selectedImage,
                          onClear: () {
                            setState(() {
                              selectedImage = null;
                            });

                          },
                          onSelect: (context) {
                            selectImage(context); // your method to pick image
                          },
                        ),
                        SizedBox(height: 19),
                        GestureDetector(
                          onTap: isFormComplete()
                              ? () {
                            verify();
                          }
                              : null,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: isFormComplete()
                                  ? Color(0xFF25BAFF)
                                  : Color(0xFF7A7F83),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Verify',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ]),
            ),
          ),
        ));
  }

}
