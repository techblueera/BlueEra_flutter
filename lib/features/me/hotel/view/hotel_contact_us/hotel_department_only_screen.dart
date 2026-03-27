import 'package:BlueEra/core/api/model/get_hotel_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_branch_contact_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HotelDepartmentOnlyScreen extends StatefulWidget {
  final HotelContactUsData? contactInfo;
  final bool? isContactInfoEdit;
  final String? branchId;

  const HotelDepartmentOnlyScreen(
      {super.key, this.isContactInfoEdit, this.contactInfo, this.branchId});

  @override
  _HotelDepartmentOnlyScreenState createState() =>
      _HotelDepartmentOnlyScreenState();
}

class _HotelDepartmentOnlyScreenState extends State<HotelDepartmentOnlyScreen> {
  final schoolAboutUsController = Get.find<HotelBranchContactController>();

  final titleController = TextEditingController();
  final websiteController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState

    if (widget.isContactInfoEdit ?? false) {
      // titleController.text = widget.contactInfo?.department ?? "";
      websiteController.text = widget.contactInfo?.website ?? "";
      emailController.text = widget.contactInfo?.email ?? "";
      phoneController.text = widget.contactInfo?.phone ?? "";
      addressController.text = widget.contactInfo?.address ?? "";
      _runValidation();
    }
    super.initState();
  }

// Helper to trigger validation
  void _runValidation() {
    schoolAboutUsController.departmentValidateForm(
      departmentRole: titleController.text,
      departmentEmailAddress: emailController.text,
      departmentPhoneNo: phoneController.text,
      departmentAddress: addressController.text
    );
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:  AppStrings.department,
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HttpsTextField(
                controller: websiteController,
                hintText: "https://yourwebsite.com",
                title: AppStrings.website,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: addressController,
                title: AppStrings.location,
                isShowLeading: false,
                onSelected: (placeId, lat, lng, address) {
                  addressController.text = address;
                  _runValidation();
                },
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: emailController,
                hintText: "dpsdehradun@gmail.com",
                title: AppStrings.email,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: phoneController,
                hintText: "+91 1234567890",
                title: AppStrings.phoneNumber,
                maxLength: 10,
                onChange: (_) => _runValidation(),
              ),
              SizedBox(height: 12),
              Obx(() {
                return CustomBtn(
                    isValidate: schoolAboutUsController.isFormValid.value,
                    onTap: () async {
                      await schoolAboutUsController.updateBranchDetails(
                          address: addressController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          contactID: widget.branchId ?? "",
                          branchName: '',
                          website: websiteController.text,
                          department: '');

                    },
                    title: AppStrings.submit);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
