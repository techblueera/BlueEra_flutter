import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/academic_calender_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/school/controller/academic_calender_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/academic_calender_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/full_screen_pdf_view_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AcademicCalenderScreen extends StatefulWidget {
   AcademicCalenderScreen({super.key, required this.isEdit});
  final bool isEdit;

  @override
  State<AcademicCalenderScreen> createState() => _AcademicCalenderScreenState();
}

class _AcademicCalenderScreenState extends State<AcademicCalenderScreen> {
  final academicCalenderController = Get.put(AcademicCalenderController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    academicCalenderController.getSchoolNoticeNewsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Academic Calender",
      ),
      bottomNavigationBar: widget.isEdit?
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
              right: 10.0, left: 10.0, bottom: 40, top: 10),
          child: PositiveCustomBtn(
              bgColor: AppColors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              onTap: () {
                Get.to(AcademicCalenderFormScreen());
              },
              title: "Add Academic Calender"),
        ),
      ):null,
      body: SafeArea(
        child: Obx(() {
          if (academicCalenderController
                  .getAcademicCalenderResponse.value.status ==
              Status.ERROR) {
            return CustomText(AppStrings.somethingWentWrong);
          }
          if (academicCalenderController
                  .getAcademicCalenderResponse.value.status ==
              Status.COMPLETE) {
            if (academicCalenderController.noticeNewsDataList.isNotEmpty) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  AcademicCalenderData data =
                      academicCalenderController.noticeNewsDataList[index];
                  return CustomFormCard(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rowWidget(
                            title: "Title",
                            value: "${data.title}",
                            noticeIndex: index,
                            isEditOption: widget.isEdit,
                            noticeID: data.id ?? ""),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        rowWidget(
                            noticeIndex: index,
                            title: "Description",
                            isEditOption: widget.isEdit,

                            value: "${data.description}",
                            noticeID: data.id ?? ""),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        InkWell(
                          onTap: () {
                            final urlType = data.uploadPhoto ?? "";
                            if (urlType.isPdf) {
                              Get.to(FullScreenPdfViewer(
                                fileUrl: data.uploadPhoto ?? "",
                                title: data.description ?? "",
                              ));
                            }

                            if (urlType.isImageUrl) {
                              navigatePushTo(
                                context,
                                ImageViewScreen(
                                  subTitle: data.description,
                                  appBarTitle: data.title ?? "",
                                  imageUrls: [data.uploadPhoto ?? ""],
                                  initialIndex: 0,
                                ),
                              );
                            }

                            //
                          },
                          child: rowWidget(
                              title: "Document",
                              value: (data.uploadPhoto?.isNotEmpty ?? false)
                                  ? "View"
                                  : "N/A",
                              isEditOption: widget.isEdit,

                              noticeID: data.id ?? "",
                              isDecoration:
                                  (data.uploadPhoto?.isNotEmpty ?? false)
                                      ? true
                                      : false,
                              noticeIndex: index),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: academicCalenderController.noticeNewsDataList.length,
              );
            }
            return Center(child: CustomText("Academic Calender Not Found"));
          }
          return SizedBox();
        }),
      ),
    );
  }

  Widget rowWidget({
    required String title,
    required String value,
    required String noticeID,
    required int noticeIndex,
    bool isDecoration = false,
    bool isEditOption = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: CustomText(
          "$title : ",
          fontWeight: FontWeight.bold,
        )),
        Expanded(
            flex: 3,
            child: isDecoration
                ? CustomText(
                    "${value}",
                    color: AppColors.primaryColor,
                    decorationColor: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                  )
                : Padding(
                    padding: EdgeInsets.only(left: isEditOption ? 1 : 0),
                    child: CustomText("${value}"),
                  )),
        (isEditOption)
            ? _buildNoticeNewsPopUpMenu(onNoticeNewsDelete: () async {
                await showCommonDialog(
                    context: context,
                    text:
                        'Are you sure you want to delete this academic calender?',
                    confirmCallback: () async {
                      await academicCalenderController
                          .deleteSchoolNoticeNewsController(noticeId: noticeID);
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppStrings.yes,
                    cancelText: AppStrings.no);
              }, onNoticeNewsEdit: () {
                AcademicCalenderData data =
                    academicCalenderController.noticeNewsDataList[noticeIndex];
                Get.to(AcademicCalenderFormScreen(
                  isEdit: true,
                  newsData: data,
                ));
              })
            : SizedBox(
                width: 10,
              ),
      ],
    );
  }

  Widget _buildNoticeNewsPopUpMenu({
    VoidCallback? onNoticeNewsEdit,
    VoidCallback? onNoticeNewsDelete,
  }) {
    return PopupMenuButton<EditDeleteMenuAction>(
      color: AppColors.white,
      menuPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: BoxConstraints(),
      onSelected: (EditDeleteMenuAction value) {
        switch (value) {
          case EditDeleteMenuAction.noticeEdit:
            if (onNoticeNewsEdit != null) onNoticeNewsEdit();
            break;
          case EditDeleteMenuAction.noticeDelete:
            if (onNoticeNewsDelete != null) onNoticeNewsDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: EditDeleteMenuAction.noticeEdit,
          child: CustomText(AppStrings.edit),
        ),
        PopupMenuItem(
          value: EditDeleteMenuAction.noticeDelete,
          child: CustomText(
            AppStrings.delete,
            color: AppColors.red00,
          ),
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: Colors.black,
        size: SizeConfig.size20,
      ),
    );
  }
}
