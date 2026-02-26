import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_ipd_controller.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/ipd_ward_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IpdWardListScreen extends StatefulWidget {
  final String departmentId;
  final String? hospitalId;
  const IpdWardListScreen({super.key, required this.departmentId, this.hospitalId});
  @override
  State<IpdWardListScreen> createState() => _IpdWardListScreenState();
}

class _IpdWardListScreenState extends State<IpdWardListScreen> {
  late final HospitalIpdController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalIpdController());
    controller.departmentIdArg = widget.departmentId;
    controller.hospitalIdArg = widget.hospitalId;
    controller.loadByDepartment(widget.departmentId);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "IPD Wards/Rooms",
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              controller.startCreate();
              Get.to(() => IpdWardFormScreen(departmentId: widget.departmentId, hospitalId: widget.hospitalId));

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
                "Add New",
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.wards.isEmpty) {
          return Center(child: CustomText("No data found"));
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          itemCount: controller.wards.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
          itemBuilder: (context, index) {
            final w = controller.wards[index];
            return CommonCardWidget(
              cardMargin: 0,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (w.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            w.imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(w.name, fontSize: 16, fontWeight: FontWeight.w700,maxLines: 2,overflow: TextOverflow.ellipsis,),
                            SizedBox(height: 6),
                            CustomText("Beds: ${w.bedCount}", color: AppColors.secondaryTextColor),
                            SizedBox(height: 6),

                            CustomText("Fees: ₹${w.fees}", color: AppColors.secondaryTextColor),
                            SizedBox(height: 6),


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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: "EDIT",
                            onTap: () {
                              controller.startEdit(w);
                              Future.delayed(const Duration(milliseconds: 100), () {
                                Get.to(() => IpdWardFormScreen(departmentId: widget.departmentId, hospitalId: widget.hospitalId));
                              });
                            },
                            child: CustomText("Edit"),
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
                                commonConformationDialog(
                                  context: context,
                                  text: "Are you sure to delete?",
                                  confirmCallback: () async {
                                    Navigator.of(context).pop();
                                    await controller.deleteWard(w);
                                  },
                                  cancelCallback: () => Navigator.of(context).pop(),
                                );
                              });
                            },
                            child: CustomText("Delete"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),

                  if (w.description.isNotEmpty)
                    ExpandableText(
                      text: w.description,
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
        );
      }),
    );
  }
}
