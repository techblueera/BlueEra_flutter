import "package:BlueEra/core/api/apiService/api_keys.dart";
import "package:BlueEra/core/constants/app_colors.dart";
import "package:BlueEra/core/constants/app_enum.dart";
import "package:BlueEra/core/constants/app_icon_assets.dart";
import "package:BlueEra/core/constants/regular_expression.dart";
import "package:BlueEra/core/constants/shared_preference_utils.dart";
import "package:BlueEra/core/constants/size_config.dart";
import "package:BlueEra/core/routes/route_helper.dart";
import "package:BlueEra/features/common/jobs/controller/job_details_overview_screen_controller.dart";
import "package:BlueEra/features/common/jobs/controller/show_resumes_screen_controller.dart";
import "package:BlueEra/widgets/commom_textfield.dart";
import "package:BlueEra/widgets/common_back_app_bar.dart";
import "package:BlueEra/widgets/common_horizontal_divider.dart";
import "package:BlueEra/widgets/custom_btn.dart";
import "package:BlueEra/widgets/custom_text_cm.dart";
import "package:BlueEra/widgets/local_assets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:get/get.dart";
import "package:intl/intl.dart";

class JobDetailsOverviewScreen extends StatefulWidget {
  JobDetailsOverviewScreen({super.key});

  @override
  State<JobDetailsOverviewScreen> createState() =>
      _JobDetailsOverviewScreenState();
}

class _JobDetailsOverviewScreenState extends State<JobDetailsOverviewScreen> {
  JobDetailsOverviewController controller =
      Get.put(JobDetailsOverviewController());

  // Dynamic answers from JobQNAScreen
  List<Map<String, dynamic>> selectedAnswers = [];

  // Controllers for answer editing
  Map<String, TextEditingController> answerControllers = {};

  // State to track which answers are being edited
  Map<String, bool> answerEditStates = {};

  late final String? resumeId;
  late final String? jobId;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final mobileNumberEditController = TextEditingController();

  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  final resumeController = Get.find<ShowResumesScreenController>();

  @override
  void initState() {
    super.initState();
    jobId = Get.arguments?['jobId'];
    resumeId = Get.arguments?['resumeId'];

    // Get selected answers from arguments
    final arguments = Get.arguments;
    if (arguments != null && arguments['selectedAnswers'] != null) {
      selectedAnswers =
          List<Map<String, dynamic>>.from(arguments['selectedAnswers']);

      // Initialize controllers and edit states for each answer
      for (var answer in selectedAnswers) {
        String question = answer['question'] ?? '';
        String answerText = answer['answer'] ?? '';

        // Create controller for this answer
        answerControllers[question] = TextEditingController(text: answerText);

        // Initialize edit state as false (not editing)
        answerEditStates[question] = false;
      }
    }

    nameController.text = resumeController.getResumeById.value?.resume?.name??"";
    emailController.text =resumeController.getResumeById.value?.resume?.email??"";
    locationController.text =resumeController.getResumeById.value?.resume?.location??"";
    mobileNumberEditController.text = userMobileGlobal;
  }

  @override
  void dispose() {
    // Dispose all answer controllers
    answerControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: SingleChildScrollView(
              padding: EdgeInsets.all(SizeConfig.size15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Basic info
                  Container(
                    padding: EdgeInsets.all(SizeConfig.size15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: AppColors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headingWidget(text: "Contact information"),
                        SizedBox(height: SizeConfig.size20),
                        CommonTextField(
                          title: "Full Name",
                          hintText: "Enter your full name",
                          textEditController: nameController,
                          validationType: ValidationTypeEnum.name,
                          readOnly: true,

                        ),
                        SizedBox(height: SizeConfig.size18),


                        CommonTextField(
                          title: "Email",
                          hintText: "Enter your email address",
                          textEditController: emailController,
                          validationType: ValidationTypeEnum.email,
                          onChange: (val) {},
                        ),
                        SizedBox(height: SizeConfig.size18),

                      /*  CommonTextField(
                          hintText: "Enter Location",
                          title: "Location",
                          textEditController: locationController,
                          onChange: (val) {},
                        ),*/
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteHelper.getSearchLocationScreenRoute(),
                              arguments: {
                                'onPlaceSelected': (double? lat, double? lng,
                                    String? address) {
                                  if (address != null) {
                                    locationController.text = address;
                                    setState(() {

                                    });
                                  }
                                },
                                ApiKeys.fromScreen: ""
                              },
                            );
                          },
                          child: CommonTextField(
                            textEditController: locationController,
                            hintText: "E.g., Rajiv Chowk, Delhi",
                            isValidate: false,
                            title: "Location",

                            // onChange: (value) => controller.validateForm(),
                            readOnly: true,
                            // Make it read-only since we'll use the search screen
                          ),
                        ),
                        SizedBox(height: SizeConfig.size18),

                        CommonTextField(
                          title: "Phone number",
                          textEditController: mobileNumberEditController,
                          inputLength: 10,
                          maxLength: 10,
                          keyBoardType: TextInputType.number,
                          regularExpression:
                              RegularExpressionUtils.digitsPattern,
                          validationType: ValidationTypeEnum.pNumber,
                          hintText: "Enter mobile number",
                          onTapOutsideTrue: false,
                          autovalidateMode: _autoValidate,
                          validator: (value) {
                            if (value?.length != 10) {
                              return 'Mobile number must be 10 digits';
                            }
                            return null;
                          },
                        )
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size15),

                  // Resume Attachment
                  Obx(() => resumeAttachmentCard(
                        fileName:( resumeController.getResumeById.value?.resume?.name?.isNotEmpty??false)?"${(resumeController.getResumeById.value?.resume?.name??"")}.pdf":"${DateTime.now().microsecondsSinceEpoch}.pdf",
                        fileSize: "",
                        uploadDateTime:
                        DateFormat("dd MMM yyyy 'at' hh:mm a").format(DateTime.now()),
                      )),

                  SizedBox(height: SizeConfig.size10),

                  /// Employer Question
                  SizedBox(height: SizeConfig.size10),

                  employerQuestionsWidget(
                    questionsAnswers: selectedAnswers,
                  ),

                  SizedBox(height: SizeConfig.size20),

                  CustomBtn(
                    onTap: () {
                      // Get updated answers from controllers, excluding the "Explain why you are the right person" question
                      List<Map<String, dynamic>> updatedAnswers = [];
                      for (var answer in selectedAnswers) {
                        String question = answer['question'] ?? '';

                        // Skip the "Explain why you are the right person for this job" question
                        if (question ==
                            'Explain why you are the right person for this job?') {
                          continue;
                        }

                        TextEditingController? controller =
                            answerControllers[question];
                        String updatedAnswer =
                            controller?.text ?? answer['answer'] ?? '';

                        updatedAnswers.add({
                          'question': question,
                          'answer': updatedAnswer,
                          'isInput': answer['isInput'] ?? false,
                        });
                      }
                      // // Convert answers to the format expected by API
                      // List<Map<String, String>> answersToCustomQuestions = [];
                      // if (answers != null) {
                      //   for (var answer in answers) {
                      //     answersToCustomQuestions.add({
                      //       "question": answer['question'] ?? "",
                      //       "answer": answer['answer'] ?? "",
                      //     });
                      //   }
                      // }
                      final Map<String, dynamic> params = {
                        ApiKeys.jobId: jobId,
                        ApiKeys.candidateName: nameController.text,
                        ApiKeys.candidateEmail: emailController.text,
                        ApiKeys.candidatePhone: mobileNumberEditController.text,
                        ApiKeys.address: {
                          ApiKeys.city: locationController.text,
                        },
                        ApiKeys.answersToCustomQuestions: updatedAnswers,
                        ApiKeys.resumeId: resumeId,
                      };
                      controller.submitNewJobApplicationApi(parameter: params);
                    },
                    title: "Submit Your Application",
                    isValidate: true,
                  ),

                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget headingWidget({required String text}) {
    return CustomText(
      text,
      color: AppColors.black28,
    );
  }

  Widget titleWidget({required String text}) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      color: AppColors.grey9A,
    );
  }

  Widget subtitleWidget({required String text}) {
    return CustomText(text,
        fontSize: SizeConfig.large, color: AppColors.black28);
  }

  Widget editIconWidget() {
    return LocalAssets(imagePath: AppIconAssets.pencilIcon);
  }

  Widget resumeAttachmentCard({
    required String fileName,
    required String fileSize,
    required String uploadDateTime,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: titleWidget(
                  text: "Resume",
                ),
              ),
              SizedBox(width: SizeConfig.size10),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Obx(
            () => Tooltip(
              message: controller.documentPath?.value.isNotEmpty == true
                  ? 'Long press to remove document'
                  : '',
              child: Container(
                  padding: EdgeInsets.all(SizeConfig.size15),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: controller.documentPath?.value.isNotEmpty == true
                          ? AppColors.primaryColor.withOpacity(0.3)
                          : AppColors.whiteE9,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                    color: controller.documentPath?.value.isNotEmpty == true
                        ? AppColors.primaryColor.withOpacity(0.05)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: SizeConfig.size45,
                        height: SizeConfig.size45,
                        child: Obx(() => LocalAssets(
                              imagePath:
                                  controller.documentPath?.value.isNotEmpty ==
                                          true
                                      ? AppIconAssets.pdfIcon
                                      : AppIconAssets.folderSkyIcon,
                            )),
                      ),
                      SizedBox(width: SizeConfig.size15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headingWidget(
                              text: fileName,
                            ),
                            SizedBox(height: SizeConfig.size6),
                            CustomText(
                              "$uploadDateTime",
                              color: AppColors.grey83,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget employerQuestionsWidget({
    required List<Map<String, dynamic>> questionsAnswers,
  }) {
    // Filter out the "Explain why you are the right person for this job" question
    List<Map<String, dynamic>> filteredAnswers = questionsAnswers.where((qa) {
      String question = qa['question'] ?? '';
      return question != 'Explain why you are the right person for this job?';
    }).toList();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.white,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
              child: headingWidget(
                text: "Employer questions",
              ),
            ),
            SizedBox(width: SizeConfig.size10),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredAnswers.asMap().entries.map((entry) {
            final index = entry.key;
            final qa = entry.value;
            bool isLast = index == filteredAnswers.length - 1;
            String question = qa['question'] ?? '';
            bool isEditing = answerEditStates[question] ?? false;
            TextEditingController? controller = answerControllers[question];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: SizeConfig.size20,
                      bottom: isLast ? 0.0 : SizeConfig.size20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: titleWidget(
                              text: question,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                answerEditStates[question] = !isEditing;
                              });
                            },
                            child: editIconWidget(),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size10),
                      isEditing && controller != null
                          ? CommonTextField(
                              textEditController: controller,
                              hintText: "Enter your answer",
                              isValidate: false,
                              maxLength: 1000,
                              minLines: qa['isInput'] == true ? 5 : 1,
                              maxLine: qa['isInput'] == true ? 10 : 3,
                            )
                          : subtitleWidget(
                              text: controller?.text ?? qa['answer'] ?? '',
                            ),
                    ],
                  ),
                ),
                // Optional: Only add divider if not the last item
                if (!isLast)
                  CommonHorizontalDivider(
                    color: AppColors.whiteE9,
                  ),
              ],
            );
          }).toList(),
        )
      ]),
    );
  }

  Future<void> SuccessfulDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.white, // Inner background color
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(blurRadius: 20, color: AppColors.black25)
                ]),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size20,
              vertical: SizeConfig.size20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON
                SvgPicture.asset(AppIconAssets.illustrationIcon),

                SizedBox(height: SizeConfig.size18),

                // Title
                CustomText(
                  "Successful!",
                  textAlign: TextAlign.center,
                  color: AppColors.black28,
                  fontSize: SizeConfig.extraLarge,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: SizeConfig.size10),
                CustomText(
                  "Congratulations, your application has been sent",
                  textAlign: TextAlign.center,
                  color: AppColors.black28,
                  fontSize: SizeConfig.medium,
                ),

                SizedBox(height: SizeConfig.size18),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                          height: SizeConfig.size40,
                          title: 'Home',
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteHelper.getBottomNavigationBarScreenRoute(),
                              arguments: {ApiKeys.initialIndex: 3},
                              (route) => false,
                            );
                          },
                          borderColor: AppColors.primaryColor,
                          bgColor: AppColors.white,
                          textColor: AppColors.primaryColor),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CustomBtn(
                          height: SizeConfig.size40,
                          title: 'Connect',
                          onTap: () {
                            // Navigator.pushNamedAndRemoveUntil(
                            //   context,
                            //   RouteHelper.getBottomNavigationBarScreenRoute(),
                            //   arguments: {ApiKeys.initialIndex: 1},
                            //       (route) => false,
                            // );
                          },
                          borderColor: AppColors.primaryColor,
                          bgColor: AppColors.primaryColor,
                          textColor: AppColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
