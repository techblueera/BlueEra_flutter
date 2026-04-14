import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_opd_controller.dart';
import 'package:BlueEra/features/me/hospital/view/opd/opd_doctor_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpdDoctorListScreen extends StatefulWidget {
  final String departmentId;
  final String? hospitalId;

  const OpdDoctorListScreen(
      {super.key, required this.departmentId, this.hospitalId});

  @override
  State<OpdDoctorListScreen> createState() => _OpdDoctorListScreenState();
}

class _OpdDoctorListScreenState extends State<OpdDoctorListScreen> {
  late final HospitalOpdController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalOpdController());
    controller.hospitalIdArg = widget.hospitalId;
    controller.loadByDepartment(widget.departmentId);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.opdDoctors,
        showRightTextButton: true,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: GestureDetector(
            onTap: () {
              controller.startCreate();
              Get.to(() => OpdDoctorFormScreen(
                    departmentId: widget.departmentId,
                    hospitalId: widget.hospitalId,
                  ));
            },
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
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor));
          }
          if (controller.doctors.isEmpty) {
            return Center(child: CustomText(AppStrings.nodata));
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ListView.separated(
              padding: EdgeInsets.all(SizeConfig.paddingM),
              itemCount: controller.doctors.length,
              separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
              itemBuilder: (context, index) {
                final d = controller.doctors[index];
                return CommonCardWidget(
                  cardMargin: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Container(
                                  height: 70,
                                  child: NetWorkOcToAssets(
                                    imgUrl: d.imageUrl,
                                    customErrorImage:
                                        AppIconAssets.place_holder_image,
                                  ))),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(d.name,
                                    fontSize: 16, fontWeight: FontWeight.w700),
                                SizedBox(height: 6),
                                if ((d.position ?? '').isNotEmpty)
                                  CustomText(d.position ?? '',
                                      color: AppColors.black28),
                                SizedBox(height: 6),
                                if ((d.education ?? '').isNotEmpty)
                                  CustomText(d.education ?? '',
                                      color: AppColors.black28),
                              ],
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
                                  controller.startEdit(d);
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    Get.to(() => OpdDoctorFormScreen(
                                        departmentId: widget.departmentId,
                                        hospitalId: widget.hospitalId));
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
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    commonConformationDialog(
                                      context: context,
                                      text: AppStrings.areYouSureDelete.tr,
                                      confirmCallback: () async {
                                        Navigator.of(context).pop();
                                        await controller.deleteOpd(d);
                                      },
                                      cancelCallback: () =>
                                          Navigator.of(context).pop(),
                                    );
                                  });
                                },
                                child: CustomText(AppStrings.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      if (d.fees != null)
                        CustomText("${AppStrings.fees.tr}: ₹${d.fees}",
                            color: AppColors.secondaryTextColor),
                      if (d.timing.isNotEmpty)
                        CustomText("${AppStrings.timing.tr}: ${d.timing}",
                            color: AppColors.secondaryTextColor),
                      if (d.description.isNotEmpty)
                        ExpandableText(
                          text: d.description,
                          trimLines: 2,
                          isReadMoreNewLine: false,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
