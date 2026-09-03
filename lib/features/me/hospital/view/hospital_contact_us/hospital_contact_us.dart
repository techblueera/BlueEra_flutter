import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_branch_details_form_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_branch_only_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_department_only_screen.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalContactUs extends StatefulWidget {
  const HospitalContactUs({super.key});

  @override
  State<HospitalContactUs> createState() => _HospitalContactUsState();
}

class _HospitalContactUsState extends State<HospitalContactUs> {
  final controller = Get.put(HospitalBranchContactController());

  @override
  void initState() {
    super.initState();
    controller.getBranchDetailsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.contactUs),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Obx(() => _buildBody())),
            SizedBox(height: SizeConfig.size10),
            AddMoreIconButton(
              onTapEvent: () => Get.to(() => HospitalBranchDetailsFormScreen()),
              buttonName: AppStrings.addAnotherBranch,
            ),
            SizedBox(height: SizeConfig.size25),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final status = controller.getSchoolContactUsResponse.value.status;
    if (status == Status.COMPLETE) {
      final branches = controller.schoolContactUsData;
      if (branches?.isEmpty ?? false) {
        return Center(child: CustomText(AppStrings.noContactsFound));
      }
      return ListView.builder(
        shrinkWrap: true,
        itemCount: branches?.length,
        itemBuilder: (context, index) {
          final data = branches?[index] ?? SchoolContactUsData();
          return _buildBranchCard(context, data);
        },
      );
    }
    if (status == Status.ERROR) {
      return CustomText(AppStrings.somethingWentWrong);
    }
    return const SizedBox();
  }

  Widget _buildBranchCard(BuildContext context, SchoolContactUsData data) {
    return CommonCardWidget(
      child: Column(
        children: [
          Row(
            children: [
              CustomText(
                "Branch: ",
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.large,
              ),
              Expanded(
                child: CustomText(
                  "${data.branch?.name}",
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => Get.to(
                  () => HospitalBranchOnlyScreen(schoolContactUsData: data),
                ),
                child: LocalAssets(
                  imagePath: AppIconAssets.editIcon,
                  imgColor: AppColors.black,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              InkWell(
                onTap: () => _confirmDelete(
                  context: context,
                  isOnlyOne: controller.schoolContactUsData?.length == 1,
                  onlyOneMessage: AppStrings.errBranchRequired,
                  dialogText: AppStrings.deleteBranchConfirm,
                  onConfirm: () => controller.deleteSchoolBranchController(
                    contactId: data.id ?? "",
                  ),
                ),
                child: LocalAssets(
                  imagePath: AppIconAssets.deleteIcon,
                  imgColor: AppColors.red00,
                ),
              ),
            ],
          ),
          iconTextRow(
            iconName: AppIconAssets.website_click,
            isPrimary: true,
            value: '${data.branch?.website}',
          ),
          SizedBox(height: SizeConfig.size5),
          iconTextRow(
            iconName: AppIconAssets.location_new,
            value: '${data.branch?.location?.name}',
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.departments?.length,
            itemBuilder: (context, index) {
              final contactData =
                  data.departments?[index] ?? OtherProfileDepartments();
              return _buildDepartmentCard(context, data, contactData);
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.add, color: AppColors.primaryColor),
              label: CustomText(
                AppStrings.addMoreDepartment,
                color: AppColors.primaryColor,
              ),
              onPressed: () => Get.to(
                () => HospitalDepartmentOnlyScreen(branchId: data.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context,
    SchoolContactUsData data,
    OtherProfileDepartments contactData,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.whiteE5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: iconTextRow(
                  iconName: AppIconAssets.principal,
                  value: contactData.department ?? "",
                ),
              ),
              InkWell(
                onTap: () => Get.to(
                  () => HospitalDepartmentOnlyScreen(
                    contactInfo: contactData,
                    isContactInfoEdit: true,
                    branchId: data.id,
                  ),
                ),
                child: LocalAssets(
                  imagePath: AppIconAssets.editIcon,
                  imgColor: AppColors.black,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              InkWell(
                onTap: () => _confirmDelete(
                  context: context,
                  isOnlyOne: data.departments?.length == 1,
                  onlyOneMessage: AppStrings.errDeptRequired,
                  dialogText: AppStrings.deleteDeptConfirm,
                  onConfirm: () =>
                      controller.deleteSchoolBranchDepartmentController(
                    departmentId: contactData.id ?? "",
                    contactId: data.id ?? "",
                  ),
                ),
                child: LocalAssets(
                  imagePath: AppIconAssets.deleteIcon,
                  imgColor: AppColors.red00,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size5),
          iconTextRow(
            iconName: AppIconAssets.email,
            value: contactData.email ?? "",
          ),
          SizedBox(height: SizeConfig.size5),
          Row(
            children: [
              Expanded(
                child: iconTextRow(
                  iconName: AppIconAssets.call,
                  value: contactData.phone ?? "",
                ),
              ),
              LocalAssets(
                imagePath: AppIconAssets.chat,
                imgColor: AppColors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shared "last-item gate + confirmation dialog" flow for branch and
  /// department delete buttons. If [isOnlyOne], the user is shown
  /// [onlyOneMessage] in a snackbar; otherwise a confirm dialog runs
  /// [onConfirm] on yes.
  Future<void> _confirmDelete({
    required BuildContext context,
    required bool isOnlyOne,
    required String onlyOneMessage,
    required String dialogText,
    required Future<void> Function() onConfirm,
  }) async {
    if (isOnlyOne) {
      commonSnackBar(message: onlyOneMessage);
      return;
    }
    await showCommonDialog(
      context: context,
      text: dialogText,
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
      confirmCallback: () async => onConfirm(),
      cancelCallback: Get.back,
    );
  }

  Widget iconTextRow({
    required String iconName,
    required String value,
    bool? isPrimary = false,
  }) {
    final highlight = isPrimary ?? false;
    return Row(
      children: [
        LocalAssets(
          imagePath: iconName,
          imgColor: highlight ? AppColors.primaryColor : AppColors.black,
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: CustomText(
            value,
            color: highlight
                ? AppColors.primaryColor
                : AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
