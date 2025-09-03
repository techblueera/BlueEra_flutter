import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/store/controller/add_update_product_controller.dart';
import 'package:BlueEra/features/common/store/models/get_channel_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddUpdateProductScreen extends StatefulWidget {
  final String channelId;
  final ProductData? productData;
  AddUpdateProductScreen({super.key, required this.channelId, required this.productData});

  @override
  State<AddUpdateProductScreen> createState() => _AddUpdateProductScreenState();
}

class _AddUpdateProductScreenState extends State<AddUpdateProductScreen> {
  final addUpdateProductController = Get.put(AddUpdateProductController());
  late final String channelId;
  late final ProductData? productData;

  @override
  initState(){
    super.initState();
    channelId = widget.channelId;
    productData = widget.productData;
    if(productData != null){
      addUpdateProductController.selectedImage.value = productData?.image??'';
      addUpdateProductController.titleController.text = productData?.name??'';
      addUpdateProductController.productDescriptionController.text = productData?.description??'';
      addUpdateProductController.productPriceController.text = productData?.price??'';
      addUpdateProductController.linkController.text = productData?.link??'';
      setState(() {});
    }
  }

  @override
  dispose(){
    super.dispose();
    // addProductController.titleController.dispose();
    // addProductController.productDescriptionController.dispose();
    // addProductController.productPriceController.dispose();
    // addProductController.linkController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: productData != null ? 'Update Product' : 'Add Product',
      ),
      body: SafeArea(
          child: Form(
            key: addUpdateProductController.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                  vertical: SizeConfig.size8
              ),
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size15),
                decoration: BoxDecoration(
                    color: AppColors.whiteFE
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Product Image
                    _buildTitle(title: 'Product Image'),
                    Obx(()=> _buildImagePickerWidget(
                      imagePath: addUpdateProductController.selectedImage.value,
                      context: context,
                      onClear: () {
                        addUpdateProductController.selectedImage.value = '';
                      },
                      onSelect: (context) {
                        addUpdateProductController.selectImage(context); // your method to pick image
                      },
                    )),

                    SizedBox(height: SizeConfig.size10),

                    /// Product Title
                    CommonTextField(
                      textEditController: addUpdateProductController.titleController,
                      maxLength: 50,
                      maxLine: 1,
                      keyBoardType: TextInputType.text,
                      title: "Title",
                      hintText: "Enter Product Title",
                      isValidate: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product title';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    SizedBox(height: SizeConfig.size10),

                    ///Product Description
                    CommonTextField(
                      textEditController: addUpdateProductController.productDescriptionController,
                      maxLength: 200,
                      inputLength: 200,
                      maxLine: 4,
                      keyBoardType: TextInputType.text,
                      title: "Product Description",
                      hintText: "Enter Product Description",
                      isValidate: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product description';
                        }else if(value.length < 10){
                          return 'Product description should be at least 10 character long';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    SizedBox(height: SizeConfig.size10),

                    ///Product Price
                    CommonTextField(
                      textEditController: addUpdateProductController.productPriceController,
                      maxLine: 1,
                      keyBoardType: TextInputType.number,
                      title: "Product Price",
                      hintText: "E.g. ₹499",
                      isValidate: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product price';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    SizedBox(height: SizeConfig.size10),

                    /// Add Link
                    HttpsTextField(
                      controller: addUpdateProductController.linkController,
                      title: 'Add Link',
                      hintText: "E.g. https://...",
                      isUrlValidate: true,
                    ),

                    SizedBox(height: SizeConfig.size30),

                    CustomBtn(
                        onTap:() {
                          if(productData != null){
                            addUpdateProductController.updateChannelProduct(productData?.sId??'');
                          }else{
                            addUpdateProductController.addChannelProduct(widget.channelId);
                          }
                        },
                        radius: 10,
                        title: (productData != null) ? 'Update Post' : 'Post Now',
                        borderColor: AppColors.primaryColor,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white
                    ),

                  ],
                ),
              ),
            ),
          )
      )
    );
  }

  Widget _buildTitle({required String title}){
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: CustomText(
        'Product Image',
        color: AppColors.mainTextColor,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildImagePickerWidget(
  {
    final String? imagePath,
    required final BuildContext context,
    required final VoidCallback onClear,
    required final Function(BuildContext context) onSelect
  }){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.0),
      child: (imagePath?.isNotEmpty ?? false)
          ? Container(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                width: 1,
                color: AppColors.greyE5
            ),
          color: AppColors.whiteFE,
          boxShadow: [AppShadows.textFieldShadow]
        ),
        child: Row(
          children: [
             isNetworkImage(imagePath)
                ? CachedAvatarWidget(
                     imageUrl: imagePath,
                     size: SizeConfig.size40,
            ) : ClipRRect(
               borderRadius: BorderRadius.circular(5.0),
               child: Image.file(
                  File(imagePath!),
                  height: SizeConfig.size40,
                  width: SizeConfig.size40,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                maxLines: 2,
                addUpdateProductController.selectedImage.split('/').last,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.grey9B,
              ),
            ),
            SizedBox(width: SizeConfig.size4),
            InkWell(
              onTap: onClear,
              child: Icon(Icons.close, color: AppColors.black),
            ),
          ],
        ),
      )
          : InkWell(
        onTap: () => onSelect(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size15),
          margin: EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  width: 1,
                  color: AppColors.greyE5
              ),
              color: AppColors.whiteFE,
              boxShadow: [AppShadows.textFieldShadow]
          ),
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(imagePath: AppIconAssets.documentUploadIcon),
              SizedBox(width: SizeConfig.size10),
              CustomText(
                "Upload Product Image",
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
