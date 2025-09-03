import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_all_resumes_model.dart';
import 'package:BlueEra/features/common/jobs/controller/job_details_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/show_resumes_screen_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShowResumes extends StatefulWidget {
  const ShowResumes({super.key});

  @override
  State<ShowResumes> createState() => _ShowResumesState();
}

class _ShowResumesState extends State<ShowResumes> {
  String? selectedResumeId;
  late JobDetailsScreenController jobDetailsScreenController;
  late ShowResumesScreenController showResumesController;

  late final String? jobId;

  @override
  void initState() {
    super.initState();
    // Initialize controllers properly
    jobId = Get.arguments['jobId'];
    jobDetailsScreenController = Get.find<JobDetailsScreenController>();
    showResumesController = Get.put(ShowResumesScreenController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            // if (jobDetailsScreenController.isLoading.value) {
            //   return Center(
            //     child: CircularProgressIndicator(
            //       color: AppColors.primaryColor,
            //     ),
            //   );
            // }
            logs("jobDetailsScreenController.getSelfResumeSelectionResponse.value.status==== ${jobDetailsScreenController
                .getSelfResumeSelectionResponse.value.status}");
            if (jobDetailsScreenController
                    .getSelfResumeSelectionResponse.value.status ==
                Status.COMPLETE) {
              final resumes =
                  jobDetailsScreenController.getResumes.value?.resumes;
              logs("resumes====${resumes}");

              if (resumes != null && (resumes.isNotEmpty)) {
                return _buildResumesGridView(resumes);
              }
              if (resumes?.isEmpty??true) {
                return _buildNoResumesView();
              }
            }
            return _buildNoResumesView();
          }),
        ),
      ),
    );
  }

  Widget _buildNoResumesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: AppColors.grey9A,
          ),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            "Your resume is not created",
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.black28,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size15),
          CustomText(
            "Create your first resume to apply for jobs",
            fontSize: SizeConfig.medium,
            color: AppColors.grey9A,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size30),
          CustomBtn(
            onTap: () {
              Get.toNamed(RouteHelper.getCreateResumeScreenRoute());
            },
            title: "Create Resume",
            bgColor: AppColors.primaryColor,
            borderColor: Colors.transparent,
            fontWeight: FontWeight.w600,
            textColor: AppColors.white,
            fontSize: SizeConfig.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildResumesGridView(List<Resumes> resumes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Select a Resume",
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.black28,
        ),
        SizedBox(height: SizeConfig.size15),
        CustomText(
          "Choose the resume you want to submit for this job",
          fontSize: SizeConfig.medium,
          color: AppColors.grey9A,
        ),
        SizedBox(height: SizeConfig.size20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: SizeConfig.size15,
              mainAxisSpacing: SizeConfig.size15,
              childAspectRatio: 0.8,
            ),
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              final resume = resumes[index];
              final isSelected = selectedResumeId == resume.id;
              return _buildResumeCard(resume, isSelected);
            },
          ),
        ),
        SizedBox(height: SizeConfig.size20),
        if (selectedResumeId != null)
          CustomBtn(
            onTap: () async {
              if (selectedResumeId != null && selectedResumeId!.isNotEmpty) {
                await showResumesController.getResumeByIdApi(
                    resumeId: selectedResumeId!,
                    jobId: jobId ?? "");
              }
              ;
            },
            title: "Submit Resume",
            bgColor: AppColors.primaryColor,
            borderColor: Colors.transparent,
            fontWeight: FontWeight.w600,
            textColor: AppColors.white,
            fontSize: SizeConfig.medium,
          ),
      ],
    );
  }

  Widget _buildResumeCard(Resumes resume, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedResumeId = resume.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.whiteE0,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black25,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.whiteF4,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.whiteE0,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description,
                      size: 40,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.grey9A,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CustomText(
                      "Resume",
                      fontSize: SizeConfig.small,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.grey9A,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    resume.fileName ?? "Untitled Resume",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black28,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size5),
                  CustomText(
                    "Created: ${_formatDate(resume.createdAt)}",
                    fontSize: SizeConfig.small - 2,
                    color: AppColors.grey9A,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown";
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Unknown";
    }
  }
}
