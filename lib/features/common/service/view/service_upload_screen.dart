import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceUploadScreen extends StatefulWidget {
  final ProviderType providerType;
  final String? channelId;

  ServiceUploadScreen({
    Key? key,
    required this.providerType,
    this.channelId
  })
      : super(key: key);

  @override
  State<ServiceUploadScreen> createState() => _ServiceUploadScreenState();
}

class _ServiceUploadScreenState extends State<ServiceUploadScreen> {
  final ServiceController controller = Get.put(ServiceController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    viewBusinessDetailsController.getAllCategories();
    controller.providerType = widget.providerType;
    if(widget.channelId!=null) controller.channelId = widget.channelId;
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<ServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.service,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: CommonCardWidget(
              child:  Obx(()=> AbsorbPointer(
                absorbing: controller.isGenerateAiServiceLoading.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.paddingXSL),

                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade50,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Colors.lightBlue.shade200, width: 1),
                      ),
                      child: accountTypeGlobal == AppConstants.individual
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(" ⚠️ "),
                                    Expanded(
                                      child: CustomText(
                                        AppStrings.yourProfessionDesignation,
                                        color: Colors.blue.shade800,
                                        fontSize: SizeConfig.size16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: SizeConfig.size10,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      AppStrings.profession,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    Flexible(
                                      child: CustomText(
                                        userProfessionGlobal,
                                        color: Colors.blue.shade700,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      '${AppStrings.workType} : ',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    Flexible(
                                      child: CustomText(
                                        "$userDesignationGlobal",
                                        color: Colors.blue.shade700,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                CustomText(
                                  AppStrings.kindlyAddServicesProfession,
                                  color: AppColors.red00,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: SizeConfig.small,
                                  maxLines: 3,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(" ⚠️ "),
                                    Expanded(
                                      child: CustomText(
                                        AppStrings.yourCategorySubcategory,
                                        color: Colors.blue.shade800,
                                        fontSize: SizeConfig.size16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      '${AppStrings.category.tr} : ',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    Flexible(
                                      child: CustomText(
                                        businessCategoryGlobal,
                                        color: Colors.blue.shade700,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      '${AppStrings.subcategory.tr}',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    Flexible(
                                      child: CustomText(
                                        businessSubCategoryGlobal,
                                        color: Colors.blue.shade700,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                CustomText(
                                  AppStrings.kindlyAddServicesCategory,
                                  color: AppColors.red00,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: SizeConfig.small,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                    ),

                    SizedBox(height: SizeConfig.paddingM),

                    // Upload Images Section
                    _buildUploadImagesSection(context),
                    SizedBox(height: SizeConfig.paddingM),

                    // Service Category Dropdown (individual providers only)
                    if (accountTypeGlobal == AppConstants.individual) ...[
                      CustomText(
                        AppStrings.category.tr,
                        fontSize: SizeConfig.large,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Obx(() => CommonDropdown<ServiceCategoryOption>(
                            items: ServiceController.serviceCategoryOptions,
                            selectedValue:
                                controller.selectedServiceCategory.value,
                            hintText: 'Select a category',
                            onChanged: (val) =>
                                controller.selectedServiceCategory.value = val,
                            displayValue: (val) => val.name,
                          )),
                      SizedBox(height: SizeConfig.paddingM),
                    ],

                    // Service Name Field
                    CommonTextField(
                      title: AppStrings.serviceName,
                      textEditController: controller.serviceNameController,
                      hintText: AppStrings.hintServiceName,
                      onChange: (value) {
                        controller.serviceName.value = value;
                      },
                    ),

                    SizedBox(height: SizeConfig.paddingM),

                    // Short description Field (Optional)
                    CommonTextField(
                      title: AppStrings.shortDescription,
                      textEditController:
                          controller.serviceShortDescriptionController,
                      hintText: AppStrings.hintShortDescription,
                      maxLine: 2,
                      isValidate: true,
                      validator: validateServiceDescription,
                      // minLines: 15,
                      onChange: (value) {
                        controller.shortDescriptionName.value = value;
                      },
                    ),
                    SizedBox(height: SizeConfig.size30),

                    // Generate Button
                    _buildGenerateButton(),
                    SizedBox(height: SizeConfig.paddingXSL),
                  ],
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadImagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.uploadImages,
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() => GestureDetector(
              onTap: () async {
                final String? selected =
                    await PhotoPickerService.pickSinglePhoto(
                  context,
                      AppStrings.selectPhoto.tr,
                );
                if ((selected?.isNotEmpty ?? false) && selected != null) {
                  controller.selectedImage.value = File(selected);
                }
              },
              // onTap: () => controller.showImagePickerDialog(context),
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  // color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: controller.selectedImage.value != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          controller.selectedImage.value!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(SizeConfig.size30),
                        child: LocalAssets(
                          imagePath: AppIconAssets.chat_input_gallery,
                          imgColor: AppColors.greyAF,
                        ),
                      ) /*Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey[500],
                      )*/
                ,
              ),
            )),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Obx(() {
      if (accountTypeGlobal == AppConstants.individual)
        return CustomBtn(
            isValidate: isPersonalServiceValidate(),
            onTap: isPersonalServiceValidate()
                ? () async {
                    if (isPersonalServiceValidate()) {
                      controller.serviceSubType = 'homeService';
                      controller.category =
                          controller.selectedServiceCategory.value?.tagId ?? '';

                      await controller.generateServiceAiController(
                        serviceDetailsReq: {
                          ApiKeys.service_name: controller.serviceName.value,
                          ApiKeys.category: controller.category,
                          if (controller.shortDescriptionName.value.isNotEmpty) ApiKeys.short_description: controller.shortDescriptionName.value,
                        },
                      );
                    }
                  }
                : null,
            title: controller.isGenerateAiServiceLoading.value
                ? null // hide text
                : AppStrings.generate,
            isLoading: controller.isGenerateAiServiceLoading.value
        );
      else
        return CustomBtn(
            isValidate: isValidate(),
            onTap: isValidate()
                ? () async {
                    if (isValidate()) {
                      controller.category = businessCategoryGlobal;
                      await controller.generateServiceAiController(
                          serviceDetailsReq: {
                            ApiKeys.service_name: controller.serviceName.value,
                            if (isBusiness()) ApiKeys.category: businessCategoryGlobal,
                            if (isBusiness()) ApiKeys.sub_category: businessSubCategoryGlobal,
                            if (controller.shortDescriptionName.value.isNotEmpty) ApiKeys.short_description: controller.shortDescriptionName.value,
                          },
                      );
                    }
                  }
                : null,
            title: controller.isGenerateAiServiceLoading.value
                ? null // hide text
                : AppStrings.generate,
            isLoading: controller.isGenerateAiServiceLoading.value
        );
    });
  }

  isValidate() {
    if (isBusiness()) {
      return (controller.selectedImage.value != null &&
          controller.serviceName.value.isNotEmpty);
    } else {
      return (controller.selectedImage.value != null &&
          controller.serviceName.value.isNotEmpty);
    }
  }

  isPersonalServiceValidate() {
    log('selectedImage-- ${controller.serviceName.value.isNotEmpty}');
    return (controller.selectedImage.value != null &&
        controller.serviceName.value.isNotEmpty &&
        controller.selectedServiceCategory.value != null);
  }

  String? validateServiceDescription(String? value) {
    if (value == null || value.isEmpty)
      return AppStrings.serviceDescriptionRequired.tr;
    if (value.length < 15)
      return AppStrings.serviceDescriptionMinLength.tr;
    return null;
  }
}
