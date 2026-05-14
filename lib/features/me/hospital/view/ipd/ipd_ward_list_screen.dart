import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_ipd_controller.dart';
import 'package:BlueEra/features/me/hospital/model/ipd_ward_model.dart';
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

  const IpdWardListScreen({
    super.key,
    required this.departmentId,
    this.hospitalId,
  });

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

  void _openForm() => Get.to(
        () => IpdWardFormScreen(
          departmentId: widget.departmentId,
          hospitalId: widget.hospitalId,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.ipdWardsRooms,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              controller.startCreate();
              _openForm();
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.wards.isEmpty) {
          return Center(child: CustomText(AppStrings.nodata));
        }
        return ListView.separated(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          itemCount: controller.wards.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
          itemBuilder: (context, index) =>
              _buildWardCard(context, controller.wards[index]),
        );
      }),
    );
  }

  Widget _buildWardCard(BuildContext context, IpdWard w) {
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
                    CustomText(
                      w.name,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      "${AppStrings.beds.tr}: ${w.bedCount}",
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      "${AppStrings.fees.tr}: ₹${w.fees}",
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              _buildPopupMenu(context, w),
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
  }

  Widget _buildPopupMenu(BuildContext context, IpdWard w) {
    return PopupMenuButton<String>(
      child: const Icon(Icons.more_vert, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "EDIT",
          onTap: () {
            controller.startEdit(w);
            // PopupMenu plays a close animation; let it finish before
            // pushing the next route to avoid a janky transition.
            Future.delayed(const Duration(milliseconds: 100), _openForm);
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
              commonConformationDialog(
                context: context,
                text: AppStrings.areYouSureDelete,
                confirmCallback: () async {
                  Get.back();
                  await controller.deleteWard(w);
                },
                cancelCallback: Get.back,
              );
            });
          },
          child: CustomText(AppStrings.delete),
        ),
      ],
    );
  }
}
