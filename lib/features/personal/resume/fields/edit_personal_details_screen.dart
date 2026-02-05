import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_enum.dart';

class EditPersonalDetailsScreen extends StatefulWidget {
  const EditPersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<EditPersonalDetailsScreen> createState() =>
      _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  // final ProfileBioController controller = Get.put(ProfileBioController());
  final ProfilePicController controller = Get.find<ProfilePicController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool isValid = false;

  @override
  void initState() {
    super.initState();
    final data = controller.getResumeData.value;
    nameController.text = data.name ?? '(No Name)';
    emailController.text = data.email ?? '(No Email)';
    phoneController.text = data.phone ?? '(No Phone)';
    locationController.text = data.location ?? '(No location)';

    nameController.addListener(_validate);
    emailController.addListener(_validate);
    phoneController.addListener(_validate);
    locationController.addListener(_validate);

    _validate();
  }

  void _validate() {
    final phoneValid =
        RegExp(r'^\d{10}$').hasMatch(phoneController.text.trim());
    final valid = nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        phoneValid &&
        locationController.text.trim().isNotEmpty;
    if (valid != isValid) {
      setState(() {
        isValid = valid;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.editPersonalDetails),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingS),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(SizeConfig.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        onChange: (val){
                          setState(() {

                          });
                        },
                        title: AppStrings.fullName,
                        hintText: "E.g. Sujoy Ghosh",
                        fontSize: SizeConfig.small,
                        textEditController: nameController,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CommonTextField(
                        validationType: ValidationTypeEnum.email,
                        onChange: (email){
                          final emailRegex = RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                          if(emailRegex.hasMatch(email)){
                            isValid=true;
                          }else{
                            isValid=false;
                          }
                          setState(() {

                          });
                        },
                        validator:(email){
                            final emailRegex = RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                            if(emailRegex.hasMatch(email??'')){
                              isValid=true;
                              return null;
                            }else{
                              isValid=false;
                              return 'Enter valid email';
                            }
                        },
                        title: AppStrings.email,
                        hintText: "E.g. bluecs.info@gmail.com",
                        fontSize: SizeConfig.small,
                        textEditController: emailController,
                        keyBoardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      CommonTextField(
                        validationType: ValidationTypeEnum.pNumber,
                        onChange: (val){

                        },
                        title: AppStrings.phoneNumber,
                        hintText: "E.g. +91 1234567890",
                        textEditController: phoneController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        fontSize: SizeConfig.small,
                        keyBoardType: TextInputType.phone,
                      ),
                      SizedBox(height: SizeConfig.paddingL),
                      InkWell(

                        child: CommonTextField(
                          onTap: (){
                          Navigator.pushNamed(
                            context,
                            RouteHelper.getSearchLocationScreenRoute(),
                            arguments: {
                              'onPlaceSelected': (double? lat, double? lng,
                                  String? address) {
                                if (address != null) {
                                  locationController.text = address;
                                  setState(() {

                                  });
                                }
                              },
                              ApiKeys.fromScreen: ""
                            },
                          );
                        },
                          textEditController: locationController,
                          hintText: AppStrings.locationHint,
                          isValidate: false,
                          title:AppStrings.location,

                          // onChange: (value) => controller.validateForm(),
                          readOnly: true,
                          // Make it read-only since we'll use the search screen
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingXXL),
                      CustomBtn(
                        title: AppStrings.update,
                        isValidate: isValid,
                        onTap: (isValid==false||phoneController.text.isEmpty||phoneController.text.length<10)
                            ? null:() async {
                          await controller.updateProfileDetails(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            location: locationController.text.trim(),careerObjective:'' ,bio: '',experienceLevel: '',openToWork: ''
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
