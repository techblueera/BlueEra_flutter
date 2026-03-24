import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_departments_controller.dart';
import 'package:BlueEra/features/me/hospital/model/department_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/me/hospital/view/opd/opd_doctor_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalOpdScreen extends StatefulWidget {
  const HospitalOpdScreen({super.key});

  @override
  State<HospitalOpdScreen> createState() => _HospitalOpdScreenState();
}

class _HospitalOpdScreenState extends State<HospitalOpdScreen> {
  late final HospitalDepartmentsController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalDepartmentsController());
  }

  void _showAddDepartmentSheet({Department? editDept}) {
    if (editDept != null) {
      controller.startEdit(editDept);
    } else {
      controller.startCreate();
    }
    controller.selectedType.value = "OPD";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              editDept != null
                  ? "Edit OPD Department"
                  : "Add OPD Department",
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: "Department Name *",
                hintText: "e.g. Cardiology, Orthopedics",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => controller.validate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: AppStrings.description.tr,
                hintText: "Description (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => controller.validate(),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isFormValid.value &&
                            !controller.isSaving.value
                        ? () => controller.saveDepartment()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : CustomText(
                            editDept != null
                                ? AppStrings.update.tr
                                : AppStrings.create.tr,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.opdTitle,
        isLeading: true,
        isShadowShow: true,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: GestureDetector(
            onTap: () => _showAddDepartmentSheet(),
            child: Container(
              height: 36,
              width: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                AppStrings.addNew,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        final opd = controller.departments
            .where((e) => e.type.toUpperCase() == "OPD")
            .toList();

        if (opd.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_outlined,
                    size: 48, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size12),
                CustomText(AppStrings.noDataFound, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size12),
                GestureDetector(
                  onTap: () => _showAddDepartmentSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      "Add OPD Department",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 50, top: SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...opd.map((d) => _departmentCard(d)),
              SizedBox(height: SizeConfig.size15),
            ],
          ),
        );
      }),
    );
  }

  Widget _departmentCard(Department d) {
    return InkWell(
      onTap: () {
        Get.to(() => OpdDoctorListScreen(
              departmentId: d.id,
              hospitalId: d.hospitalId,
            ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Row(
          children: [
            LocalAssets(
              imagePath: "assets/svg/${d.key}.svg",
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                d.key,
                fontSize: SizeConfig.size18,
                color: AppColors.mainTextColor,
              ),
            ),
            PopupMenuButton<String>(
              child: const Icon(Icons.more_vert, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              offset: const Offset(-6, 36),
              color: AppColors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "EDIT",
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _showAddDepartmentSheet(editDept: d);
                    });
                  },
                  child: CustomText(AppStrings.edit),
                ),
                const PopupMenuItem(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  height: 1,
                  child: Divider(height: 1),
                ),
                PopupMenuItem(
                  value: "DELETE",
                  height: 15,
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      controller.deleteDepartment(d);
                    });
                  },
                  child: CustomText(AppStrings.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
