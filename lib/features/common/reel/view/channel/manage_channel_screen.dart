import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/reel/controller/manage_channel_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../controller/channel_controller.dart';

class ManageChannelScreen extends StatefulWidget {
  const ManageChannelScreen({super.key});

  @override
  State<ManageChannelScreen> createState() => _ManageChannelScreenState();
}

class _ManageChannelScreenState extends State<ManageChannelScreen> {
  bool isUserNameVerify = false;
  ChannelData? _channelData;
  File? _profileImage;
  TextEditingController _channelNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController _channelBioController = TextEditingController();
  TextEditingController _websiteController = TextEditingController();
  final authController = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final List<SocialInputFieldsModel> selectedInputFields = [
    SocialInputFieldsModel(
      name: 'YouTube',
      icon: 'assets/svg/youtube_grey.svg',
      linkController: TextEditingController(),
    ),

  ];
  final manageChannelController =
      Get.put<ManageChannelController>(ManageChannelController());

  bool get hasExistingLogo =>
      _channelData != null &&
      _channelData?.logoUrl != null &&
      _channelData!.logoUrl.isNotEmpty;

  @override
  void dispose() {
    _channelNameController.dispose();
    userNameController.dispose();
    _channelBioController.dispose();
    _websiteController.dispose();
    disposeInputFields(selectedInputFields);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _channelData = args[ApiKeys.channelData];
        if (_channelData != null) {
          _populateFields();
        }
      }
      setState(() {});
    });
  }

  void _populateFields() {
    _channelNameController.text = _channelData?.name ?? '';
    userNameController.text = _channelData?.username ?? '';
    _channelBioController.text = _channelData?.bio ?? '';

    if (_channelData?.websites != null && _channelData!.websites.isNotEmpty) {
      _websiteController.text = _channelData!.websites.join(', ');
    }

    if (_channelData?.socialLinks != null) {
      for (var socialLink in _channelData!.socialLinks) {
        try {
          var field = selectedInputFields.firstWhere(
            (field) =>
                field.name.toLowerCase() == socialLink.platform.toLowerCase(),
          );

          String url = socialLink.url;
          if (url.isNotEmpty) {
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
          }

          field.linkController.text = url;
        } catch (e) {
          print(
              "Social link field not found for platform: ${socialLink.platform}");
        }
      }
    }

    setState(() {});
  }

  void disposeInputFields(List<SocialInputFieldsModel> fields) {
    for (var field in fields) {
      field.linkController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: (_channelData != null) ? AppStrings.updateChannel : AppStrings.createChannel,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              top: SizeConfig.size15,
              bottom: SizeConfig.size35,
            ),
            padding: EdgeInsets.all(SizeConfig.size15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: SizeConfig.size10,
                  offset: Offset(0, SizeConfig.size2),
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: SizeConfig.size100,
                            width: SizeConfig.size100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2.0,
                              ),
                            ),
                            child: _profileImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        SizeConfig.size50),
                                    child: Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                      height: SizeConfig.size100,
                                      width: SizeConfig.size100,
                                    ),
                                  )
                                : hasExistingLogo
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.size50),
                                        child: Image.network(
                                          _channelData?.logoUrl??"",
                                          fit: BoxFit.cover,
                                          height: SizeConfig.size100,
                                          width: SizeConfig.size100,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryColor,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                "Error loading image: $error");
                                            return Center(
                                              child: SvgPicture.asset(
                                                'assets/svg/person-rounded.svg',
                                                fit: BoxFit.fitHeight,
                                                height: SizeConfig.size60,
                                                width: SizeConfig.size60,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: SvgPicture.asset(
                                          'assets/svg/person-rounded.svg',
                                          fit: BoxFit.fitHeight,
                                          height: SizeConfig.size60,
                                          width: SizeConfig.size60,
                                        ),
                                      ),
                          ),
                          Positioned(
                            right: -(SizeConfig.size2),
                            bottom: -(SizeConfig.size2),
                            child: InkWell(
                              onTap: () => _selectImage(context),
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryColor),
                                child: Icon(Icons.edit_outlined,
                                    color: AppColors.white,
                                    size: SizeConfig.size18),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CustomText(
                        AppStrings.channelLogo,
                        fontSize: SizeConfig.small,
                      ),
                      SizedBox(height: SizeConfig.size4),
                      CustomText(
                        AppStrings.addChannelLogo,
                        fontSize: SizeConfig.small,
                        color: AppColors.grey80,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size20),

                /// Channel Name
                CommonTextField(
                  textEditController: _channelNameController,
                  inputLength: AppConstants.inputCharterLimit50,
                  keyBoardType: TextInputType.text,
                  title:AppStrings.channelName,
                  hintText: "Eg. McDonald's India",
                  isValidate: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.channelNameError.tr;
                    }
                    return null;
                  },
                  onChange: (value) {},
                ),

                SizedBox(height: SizeConfig.size20),
                Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(AppStrings.createUsername)),

                // SizedBox(height: SizeConfig.size5),

                Obx(() {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                          authController.userNameList.length, (i) {
                        final isSelected =
                            authController.selectedIndex.value == i;
                        return GestureDetector(
                          onTap: () {
                            userNameController.text =
                                authController.userNameList[i];
                            authController.select(i);
                            isUserNameVerify = true;
                            setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.black,
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          blurRadius: 6,
                                          spreadRadius: 0.5,
                                          color: Colors.black.withValues(alpha: 0.15))
                                    ]
                                  : null,
                            ),
                            child: CustomText(
                              authController.userNameList[i],
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: SizeConfig.small,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),

                /// User Name
                CommonTextField(
                  textEditController: userNameController,
                  inputLength: 8,
                  keyBoardType: TextInputType.text,
                  regularExpression: RegularExpressionUtils.alphanumericPattern,
                  titleColor: Colors.black,
                  hintText: "Eg @Sachin",
                  isValidate: false,
                  prefixText: userNameController.text.isNotEmpty ? "@" : "",
                  validator: (value) {
                    if (value == null || value.trim().length < 4) {
                      return AppStrings.usernameError.tr;
                    }
                    return null;
                  },
                  onChange: (value) {
                    authController.isShowCheck.value = true;
                    setState(() {});
                  },
                ),

                SizedBox(height: SizeConfig.size20),

                /// Channel bio
                CommonTextField(
                  textEditController: _channelBioController,
                  maxLength: 120,
                  maxLine: 3,
                  inputLength: AppConstants.inputCharterLimit120,
                  keyBoardType: TextInputType.text,
                  title: AppStrings.channelBio,
                  hintText: "Eg. India's fastest-growing streetwear brand...",
                  isValidate: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.channelBioError.tr;
                    }
                    return null;
                  },
                  isCounterVisible: true,
                  onChange: (value) {},
                ),

                SizedBox(height: SizeConfig.size20),
                HttpsTextField(
                  controller: _websiteController,
                  pIcon: Container(
                    width: 40,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/web_icon.svg',
                        height: SizeConfig.size24,
                        width: SizeConfig.size24,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  title: AppStrings.websiteOptional,
                  hintText: "eg. https://mcdindia.com/",
                  isUrlValidate: false,
                ),

                SizedBox(height: SizeConfig.size18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.otherSocialLinks,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                ...selectedInputFields.map(
                  (field) => Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size14),
                    child: HttpsTextField(
                      controller: field.linkController,
                      pIcon: Container(
                        width: 40,
                        child: Center(
                          child: SvgPicture.asset(
                            field.icon,
                            height: SizeConfig.size24,
                            width: SizeConfig.size24,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      hintText: AppStrings.youtubeHint,
                      isUrlValidate: false,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size20),

                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        height: SizeConfig.size40,
                        radius: 8,
                        title: AppStrings.cancel,
                        borderColor: AppColors.primaryColor,
                        bgColor: Colors.white,
                        textColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CustomBtn(
                        onTap: () => _onSubmit(),
                        height: SizeConfig.size40,
                        radius: 8,
                        title: (_channelData != null) ? AppStrings.update : AppStrings.create,
                        borderColor: AppColors.primaryColor,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectImage(BuildContext context) async {
    final imagePath = await PhotoPickerService.pickSinglePhoto(
        context, AppStrings.uploadChannelLogo);
    if (imagePath == null || imagePath.isEmpty) return;
    _profileImage = File(imagePath);
    setState(() {});
  }

  Future<void> _onSubmit() async {
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (isFormValid) {
      if (_channelData == null && _profileImage == null && !hasExistingLogo) {
        commonSnackBar(
            message: "Please add your brand logo or profile picture.");
        return;
      }

      final profileImage = (_profileImage != null) ? _profileImage : null;
      dio.MultipartFile? imageByPart;

      if (profileImage?.path.isNotEmpty ?? false) {
        String fileName = profileImage?.path.split('/').last ?? "";
        imageByPart = await dio.MultipartFile.fromFile(profileImage?.path ?? "",
            filename: fileName);
      }

      List<String> websitesList = [];
      if (_websiteController.text.trim().isNotEmpty) {
        websitesList = _websiteController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) {
          if (!e.startsWith('http://') && !e.startsWith('https://')) {
            return 'https://$e';
          }
          return e;
        }).toList();
      }
      Map<String, dynamic> requestData = {
        ApiKeys.name: _channelNameController.text.trim(),
        ApiKeys.username: userNameController.text.trim(),
        ApiKeys.bio: _channelBioController.text.trim(),
      };

      if (websitesList.isNotEmpty) {
        requestData[ApiKeys.websites] = websitesList;
      } else {
        requestData[ApiKeys.websites] = [];
      }

      if (imageByPart != null) {
        requestData[ApiKeys.logo] = imageByPart;
      }

      List<Map<String, String>> socialLinkRequestData = [];

      for (var field in selectedInputFields) {
        String url = field.linkController.text.trim();
        if (url.isNotEmpty) {
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }

          if (Uri.tryParse(url) != null) {
            socialLinkRequestData.add({
              ApiKeys.platform: field.name,
              ApiKeys.url: url,
            });
          } else {
            commonSnackBar(message: "Invalid URL format for ${field.name}");
            return;
          }
        }
      }
      // return;
      try {
        if (_channelData != null) {

          ChannelController channelController = Get.put(ChannelController());
          await channelController.updateChannel(
              reqData: requestData, socialLinkReqData: socialLinkRequestData);

        } else {
          if (channelId.isEmpty) {
            await manageChannelController.createChannel(
                reqData: requestData, socialLinkReqData: socialLinkRequestData);
          } else {
            /// call social link api only cause channel is created but social link is failed
            manageChannelController.socialLinks(
                id: channelId, reqData: socialLinkRequestData);
          }
        }
      } catch (e) {
        print("Error in _onSubmit: $e");
        commonSnackBar(message: "Something went wrong. Please try again.");
      }
    } else {
      setState(() {});
    }
  }
}
