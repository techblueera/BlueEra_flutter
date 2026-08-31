import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/student_corner_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/school/controller/student_corder_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/full_screen_pdf_view_screen.dart';
import 'package:BlueEra/features/me/school/view/category/student_corder/common_student_corner_form_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonStudentCornerScreen extends StatefulWidget {
  const CommonStudentCornerScreen(
      {super.key,
      required this.title,
      required this.screenName,
      required this.isEdit});

  final bool isEdit;

  final String title;
  final String screenName;

  @override
  State<CommonStudentCornerScreen> createState() =>
      _CommonStudentCornerScreenState();
}

class _CommonStudentCornerScreenState extends State<CommonStudentCornerScreen> {
  final studentCornerController = Get.put(StudentCornerController());
  List<StudentCornerItem> dataList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.title,
      ),
      bottomNavigationBar: widget.isEdit
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    right: 10.0, left: 10.0, bottom: 40, top: 10),
                child: PositiveCustomBtn(
                    bgColor: AppColors.white,
                    textColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                    onTap: () {
                      Get.to(() => CommonStudentCornerFormScreen(
                            title: widget.title,
                            screenName: widget.screenName,
                          ));
                    },
                    title: "${AppStrings.add.tr} ${widget.title}"),
              ),
            )
          : null,
      body: SafeArea(
        child: Obx(() {
          if (studentCornerController.getStudentCornerResponse.value.status ==
              Status.ERROR) {
            return Center(child: CustomText(AppStrings.somethingWentWrong));
          }
          if (studentCornerController.getStudentCornerResponse.value.status ==
              Status.COMPLETE) {
            dataList = <StudentCornerItem>[].obs;

            if (widget.screenName == timeTable) {
              dataList.assignAll(studentCornerController.timeTableList);
            } else if (widget.screenName == syllabus) {
              dataList.assignAll(studentCornerController.syllabusList);
            } else if (widget.screenName == examSchedule) {
              dataList.assignAll(studentCornerController.examScheduleList);
            } else if (widget.screenName == results) {
              dataList.assignAll(studentCornerController.resultsList);
            } else if (widget.screenName == downloads) {
              dataList.assignAll(studentCornerController.downloadsList);
            }
            if (dataList.isNotEmpty) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  StudentCornerItem data = dataList[index];
                  return CustomFormCard(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        rowWidget(
                            title: AppStrings.title,
                            value: "${data.title}",
                            noticeIndex: index,
                            isEditOption: widget.isEdit,
                            noticeID: data.id ?? ""),
                        SizedBox(
                          height: SizeConfig.size5,
                        ),
                        rowWidget(
                            noticeIndex: index,
                            title: AppStrings.description,
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
                              Get.to(() => FullScreenPdfViewer(
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
                              title: AppStrings.uploadDocument,
                              value: (data.uploadPhoto?.isNotEmpty ?? false)
                                  ? "View"
                                  : "N/A",
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
                itemCount: dataList.length,
              );
            }
            return Center(
                child:
                    CustomText("${widget.title} ${AppStrings.noDataFound.tr}"));
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
                    text: AppStrings.areYouSureDelete,
                    confirmCallback: () async {
                      await studentCornerController
                          .deleteSchoolCornerItemController(
                              studentCornerTYPE: widget.screenName,
                              cornerINDEX: noticeIndex);
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppStrings.yes,
                    cancelText: AppStrings.no);
              }, onNoticeNewsEdit: () {
                StudentCornerItem data = dataList[noticeIndex];
                Get.to(() => CommonStudentCornerFormScreen(
                      isEdit: true,
                      studentItem: data,
                      title: widget.title,
                      screenName: widget.screenName,
                      itemIndex: noticeIndex,
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
