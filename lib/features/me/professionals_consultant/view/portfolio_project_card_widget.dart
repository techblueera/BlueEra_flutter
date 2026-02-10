import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/controller/job_seeker_portfolio_professionals_controller.dart';
import 'package:BlueEra/features/me/job_seekar/view/project_portfolio/job_seeker_portfolio_form_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/portfolio_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class PortfolioProjectCardWidget extends StatelessWidget {
  final ProfessionalPortfolio project;
  final bool isShowMore;
  final bool isDateFormateReq;

  PortfolioProjectCardWidget(
      {Key? key,
      required this.project,
      this.isShowMore = true,
      this.isDateFormateReq = true})
      : super(key: key);

  // final portfolioController = Get.find<PortfolioProfessionalsController>();
  final portfolioController =
      getOrPut(() => PortfolioProfessionalsController(), permanent: true);
  String? formattedDate;

  @override
  Widget build(BuildContext context) {
    // Format the date safely
    if (isDateFormateReq) {
      formattedDate = project.completionDate != null
          ? DateFormat('d MMMM, yyyy')
              .format(DateTime.parse(project.completionDate ?? ""))
          : "No Date";
    } else {
      formattedDate = project.completionDate ?? "No Date";
    }
    // Calculate "Add More" count
    int additionalImages = (project.media?.length ?? 0) - 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image Section
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(project.media?.first.url ??
                        'https://via.placeholder.com/150'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (additionalImages > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "+$additionalImages Img",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Right: Content Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.projectTitle ?? "Untitled Project",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isShowMore) _buildPopupMenu(context),
                    // const Icon(Icons.more_vert, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 4),
                // Date Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(formattedDate ?? "",
                      color: AppColors.secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 8),

                CustomText(
                  project.description ?? "",
                  color: AppColors.secondaryTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
  ) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          portfolioController.openForEdit(project);
          _openAddEditSheet(context, true);
          // Get.to(() => AddMoreCourseScreen(isEdit: true, courseData: data));
        } else {
          await showCommonDialog(
              context: context,
              text: 'Are you sure you want to delete this data?',
              confirmCallback: () async {
                Navigator.of(context).pop(); // Close the dialog

                final controller = Get.find<PortfolioProfessionalsController>();

                controller.deleteCertificateController(
                    certiId: project.id ?? "");
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppStrings.yes,
              cancelText: AppStrings.no);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text("Edit")),
        PopupMenuItem(
            value: 'delete',
            child: Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _openAddEditSheet(BuildContext context, bool isEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.size14,
                  right: SizeConfig.size14,
                  top: SizeConfig.size14,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      SizeConfig.size14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Edit ", fontWeight: FontWeight.w600),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),

                      CommonTextField(
                        title: "Project Title",
                        textEditController: portfolioController.titleController,
                        hintText: "E.g. Finance & Tax",
                        onChange: (val) {
                          setState(() {});
                        },
                      ),

                      SizedBox(height: SizeConfig.size12),
                      const CustomText("Consultation Mode",
                          color: AppColors.mainTextColor),
                      const SizedBox(height: 10),
                      Obx(() => CommonDropdownDialog<String>(
                            title: "Select Mode",
                            hintText: "E.g. Online",
                            items: portfolioController.categoryList,
                            selectedValue: portfolioController
                                    .selectedCategory.value.isEmpty
                                ? null
                                : portfolioController.selectedCategory.value,
                            displayValue: (mode) => mode,
                            onChanged: (value) {
                              if (value != null)
                                portfolioController.selectedCategory.value =
                                    value;
                            },
                          )),
                      const SizedBox(height: 10),

                      ///DOB selection
                      CustomText(
                        'When the work was completed',
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      NewDatePicker(
                        selectedDay: portfolioController.selectedDay,
                        selectedMonth: portfolioController.selectedMonth,
                        selectedYear: portfolioController.selectedYear,
                        isAgeValidation15: false,
                        onDayChanged: (value) {
                          setState(() {
                            portfolioController.selectedDay = value;
                          });
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            portfolioController.selectedMonth = value;
                          });
                        },
                        onYearChanged: (value) {
                          setState(() {
                            portfolioController.selectedYear = value;
                          });
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      if (!isEdit) ...[
                        CustomText(
                          'Upload Image',
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                        SizedBox(height: SizeConfig.size12),
                      ],
                      Obx(() {
                        return AiDescriptionField(
                          label: AppStrings.description,
                          hintText:
                              "Tell us more about the project or case study...",
                          controller: portfolioController.descriptionController,
                          rxValue: portfolioController.description,
                          // Your RX variable from the controller
                          aiType: "Portfolio,Case Studies",
                          aiData: {
                            "category":
                                portfolioController.selectedCategory.value,
                            "title": portfolioController.titleController.text
                          },
                        );
                      }),
                      SizedBox(height: SizeConfig.size20),
                      Obx(() => CustomBtn(
                            title: isEdit ? "Update" : "Save",
                            isValidate: !(portfolioController.isSaving.value),
                            onTap: portfolioController.isSaving.value
                                ? null
                                : () async {
                                    await portfolioController.save();
                                    Get.back();
                                  },
                          )),
                      SizedBox(height: SizeConfig.size20),
                      SizedBox(height: SizeConfig.size30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class JobSeekerPortfolioProjectCardWidget extends StatefulWidget {
  final ProfessionalPortfolio project;
  final bool isShowMore;
  final bool isDateFormateReq;

  JobSeekerPortfolioProjectCardWidget(
      {Key? key,
      required this.project,
      this.isShowMore = true,
      this.isDateFormateReq = true})
      : super(key: key);

  @override
  State<JobSeekerPortfolioProjectCardWidget> createState() =>
      _JobSeekerPortfolioProjectCardWidgetState();
}

class _JobSeekerPortfolioProjectCardWidgetState
    extends State<JobSeekerPortfolioProjectCardWidget> {
  // final portfolioController = Get.find<PortfolioProfessionalsController>();
  final portfolioController = getOrPut(
      () => JobSeekerPortfolioProfessionalsController(),
      permanent: true);

  String? formattedDate;

  @override
  Widget build(BuildContext context) {
    // Format the date safely
    if (widget.isDateFormateReq) {
      formattedDate = widget.project.completionDate != null
          ? DateFormat('d MMMM, yyyy')
              .format(DateTime.parse(widget.project.completionDate ?? ""))
          : "No Date";
    } else {
      formattedDate = widget.project.completionDate ?? "No Date";
    }
    // Calculate "Add More" count
    int additionalImages = (widget.project.media?.length ?? 0) - 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  child: Image.network(
                    widget.project.projectImage ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              if (additionalImages > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "+$additionalImages Img",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Right: Content Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.project.projectTitle ?? "Untitled Project",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isShowMore) _buildPopupMenu(context),
                    // const Icon(Icons.more_vert, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 4),
                // Date Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(formattedDate ?? "",
                      color: AppColors.secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 8),

                CustomText(
                  widget.project.description ?? "",
                  color: AppColors.secondaryTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
  ) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          portfolioController.openForEdit(widget.project);
          // _openAddEditSheet(context, true);
          Get.to(JobSeekerPortfolioFormScreen());

          // Get.to(() => AddMoreCourseScreen(isEdit: true, courseData: data));
        } else {
          await showCommonDialog(
              context: context,
              text: 'Are you sure you want to delete this data?',
              confirmCallback: () async {
                Navigator.of(context).pop(); // Close the dialog

                final controller =
                    Get.find<JobSeekerPortfolioProfessionalsController>();

                controller.deleteCertificateController(
                    certiId: widget.project.id ?? "");
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppStrings.yes,
              cancelText: AppStrings.no);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text("Edit")),
        PopupMenuItem(
            value: 'delete',
            child: Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    );
  }

}
