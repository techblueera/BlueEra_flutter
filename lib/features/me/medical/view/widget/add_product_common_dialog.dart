import 'dart:io';

import 'package:BlueEra/features/me/medical/view/widget/picked_varient_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import '../../controller/medical_model_controller.dart';
import '../../model/medical_admin_product_details.dart';

class AddProductCommonDialog {
  static void showAddProduct({
    required BuildContext context,
    required String categoryId,
  }) {
    final controller = getOrPut(() => MedicalModelController());
    final _formKey = GlobalKey<FormState>();

    controller.clearProductForm();

    Future<List<String>> pickMultipleImages() async {
      final ImagePicker picker = ImagePicker();

      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // reduce size
      );

      return images.map((e) => e.path).toList();
    }

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const CustomText(
          'Add Product',
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        content: Obx(() {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Image Picker
                  Center(
                    child: InkWell(
                      onTap: () async {
                        final String? image =
                        await PhotoPickerService.pickSinglePhoto(
                            context, "Product Image");
                        if (image != null) {
                          controller.setPickedProductImage(File(image));
                        }
                      },
                      child: Container(
                        height: SizeConfig.size100,
                        width: SizeConfig.size100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: ClipOval(
                          child:
                          controller.pickedProductImage.value != null
                              ? Image.file(
                            controller.pickedProductImage.value!,
                            fit: BoxFit.cover,
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, size: 24),
                              SizedBox(height: 4),
                              Text(
                                "Photo of Product",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),

                  /// Doctor Name
                  CommonTextField(
                    title: "Product Name",
                    hintText: "E.g. Tablet",
                    textEditController: controller.productNameController,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "Product name is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),

                  /// Specialization
                  CommonTextField(
                    title: "Description",
                    hintText: "E.g. This tablet is used for fever and headache",
                    textEditController:
                    controller.productDescriptionController,
                    maxLine: 4,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "Product Description is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),

                  /// Qualification
                  CommonTextField(
                    title: "BasePrice",
                    hintText: "E.g. 1000",
                    textEditController: controller.productBasePriceController,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "BasePrice is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),

                  /// Availability
                  CommonTextField(
                    title: "Selling Price",
                    hintText: "E.g. Mon - Fri (10AM - 4PM)",
                    textEditController:
                    controller.productSellingPriceController,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "Selling Price is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),

                  /// Fees
                  CommonTextField(
                    title: "Quantity",
                    hintText: "E.g. 10",
                    keyBoardType: TextInputType.number,
                    textEditController:
                    controller.productQuantityController,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "Quantity is required";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter valid Value";
                      }
                      return null;
                    },
                  ),
       SizedBox(height: SizeConfig.size12),

                  /// Fees
                  CommonTextField(
                    title: "Variant Weight",
                    hintText: "E.g. 100 gm",
                    keyBoardType: TextInputType.number,
                    textEditController:
                    controller.productVariantWeightController,
                    validator: (value) {
                      if (value == null || value
                          .trim()
                          .isEmpty) {
                        return "Weight is required";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter valid Percent";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CustomText("Variant Images"),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() => PickedImageRow(
                    images: controller.pickedVariantImagePathList.toList(),
                    onAddTap: () async {
                      final images = await pickMultipleImages();
                      controller.pickedVariantImagePathList.addAll(images);
                    },
                    onRemove:(String path){
                      controller.pickedVariantImagePathList.remove(path);
                    }
                  )),
                  SizedBox(height: SizeConfig.size28),

                  /// Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          title: "Cancel",
                          isValidate: false,
                          onTap: () {
                            Get.back();
                          },
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: CustomBtn(
                          title: "Add Product",
                          isValidate: true,
                          isLoading: controller.addProductLoading.value,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              if (controller.pickedProductImage.value == null) {
                                commonSnackBar(
                                    message: "Please select doctor image");

                                return;
                              }
                              controller.addMedicalProduct(categoryId);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  static void addVariant({
    required BuildContext context,
    required String productId,
    VariantModel? preVariantData,


  })

  {
    final controller = getOrPut(() => MedicalModelController());
    final _formKey = GlobalKey<FormState>();
    if(preVariantData!=null){
      controller.setVariantForEdit(preVariantData);

    }else{
      controller.clearProductForm();
    }
   // create this method
    Future<List<String>> pickMultipleImages() async {
      final ImagePicker picker = ImagePicker();

      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // reduce size
      );

      return images.map((e) => e.path).toList();
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title:  CustomText(
        (preVariantData!=null)? 'Edit Variant':'Add More Variant',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Quantity
                CommonTextField(
                  title: "Quantity",
                  hintText: "E.g. 100GM",
                  textEditController: controller.productQuantityController,
                  validator: (v) =>
                  v == null || v.isEmpty ? "Quantity required" : null,
                ),
                SizedBox(height: SizeConfig.size12),
                    CommonTextField(
                  title: "Weight",
                  hintText: "E.g. 100Kg",
                  textEditController: controller.productVariantWeightController,
                  validator: (v) =>
                  v == null || v.isEmpty ? "Weight required" : null,
                ),
                SizedBox(height: SizeConfig.size12),

                /// MRP
                CommonTextField(
                  title: "MRP",
                  hintText: "E.g. ₹1,999",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.productBasePriceController,
                  validator: (v) =>
                  v == null || v.isEmpty ? "MRP required" : null,
                ),
                SizedBox(height: SizeConfig.size12),

                /// Selling price
                CommonTextField(
                  title: "Selling Price",
                  hintText: "E.g. ₹1,500",
                  keyBoardType: TextInputType.number,
                  textEditController: controller.productSellingPriceController,
                  validator: (v) =>
                  v == null || v.isEmpty ? "Selling price required" : null,
                ),

                SizedBox(height: SizeConfig.size12),
                CustomText("Variant Images"),
                SizedBox(height: SizeConfig.size10),
                Obx(() => PickedImageRow(
                    images: controller.pickedVariantImagePathList.toList(),
                    onAddTap: () async {
                      final images = await pickMultipleImages();
                      controller.pickedVariantImagePathList.addAll(images);
                    },
                    onRemove:(String path){
                      controller.pickedVariantImagePathList.remove(path);
                    }
                )),
                SizedBox(height: SizeConfig.size28),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                     if (preVariantData!=null){
                      // controller.setVariantForEdit(productId: productId);

                     }
                      if (_formKey.currentState!.validate()) {
                        controller.addProductVariant(productId: productId);
                      }
                    },
                    child:  CustomText(
                      (preVariantData!=null)?"Edit":"Submit",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );


  }

}
