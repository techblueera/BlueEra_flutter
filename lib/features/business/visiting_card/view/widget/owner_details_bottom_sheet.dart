import 'dart:developer';

import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';

class OwnerDetailsBottomSheet extends StatefulWidget {
  final BusinessProfileDetails? prevBusinessDetails;
  final bool isFromCreateUser;

  const OwnerDetailsBottomSheet({
    super.key,
    this.prevBusinessDetails,
    this.isFromCreateUser = false,
  });

  @override
  State<OwnerDetailsBottomSheet> createState() =>
      _OwnerDetailsBottomSheetState();
}

class _OwnerDetailsBottomSheetState extends State<OwnerDetailsBottomSheet> {
  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController yourRoleController = TextEditingController();
  final TextEditingController emailTextController = TextEditingController();

  bool validate = false;

  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    if (widget.prevBusinessDetails != null) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final data = widget.prevBusinessDetails;
    if (data?.ownerDetails != null &&
        (data?.ownerDetails?.isNotEmpty ?? false)) {
      nameTextController.text = data?.ownerDetails?.first.name ?? '';
      emailTextController.text = data?.ownerDetails?.first.email ?? '';
      yourRoleController.text =
          data?.ownerDetails?.first.role_in_business ?? '';

      // Check if all fields are filled
      final isAllFieldsFilled = nameTextController.text.isNotEmpty &&
          emailTextController.text.isNotEmpty &&
          yourRoleController.text.isNotEmpty;

      validate = isAllFieldsFilled;
      log('validate--> $validate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: SizeConfig.size16,
          right: SizeConfig.size16,
          top: SizeConfig.size16,
          bottom: SizeConfig.size30,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Owner Details",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: SizeConfig.size20),

              CommonTextField(
                textEditController: nameTextController,
                inputLength: 50,
                keyBoardType: TextInputType.text,
                title: "Your Name",
                hintText: "Enter Name",
                onChange: (_) => validateForm(),
              ),
              SizedBox(height: SizeConfig.size20),

              CommonTextField(
                textEditController: yourRoleController,
                inputLength: 50,
                keyBoardType: TextInputType.text,
                title: "Your Role",
                hintText: "Owner/Co-founder",
                onChange: (_) => validateForm(),
              ),
              SizedBox(height: SizeConfig.size20),

              CommonTextField(
                textEditController: emailTextController,
                inputLength: 50,
                keyBoardType: TextInputType.emailAddress,
                title: "Email",
                hintText: "Enter Email",
                onChange: (_) => validateForm(),
              ),
              SizedBox(height: SizeConfig.size28),

              CustomBtn(
                title: "Save",
                bgColor: AppColors.primaryColor,
                radius: 10,
                isValidate: validate,
                onTap: () {
                  if (!validate) return;

                  final updatedOwnerDetails = [
                    {
                      'name': nameTextController.text,
                      'role_in_business': yourRoleController.text,
                      'email': emailTextController.text,
                    }
                  ];

                  // Call controller to save
                  viewBusinessDetailsController.updateBusinessDetails({
                    'owner_details': updatedOwnerDetails,
                  });

                  if (widget.isFromCreateUser == false) {
                    Navigator.of(context).pop();
                  } else {
                    Get.offNamedUntil(
                      RouteHelper.getBottomNavigationBarScreenRoute(),
                          (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final validations = {
      'Name': nameTextController.text.isNotEmpty,
      'Your Role': yourRoleController.text.isNotEmpty,
      'Email': emailTextController.text.isNotEmpty,
    };

    final hasEmptyField = validations.values.contains(false);
    print(hasEmptyField);

    if (hasEmptyField) {
      validate = false;
      setState(() {});
      return;
    }

    validate = true;
    setState(() {});
  }
}
