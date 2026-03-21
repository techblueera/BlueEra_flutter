import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/features/common/comment/widget/comment_type_chip_selector_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// NOTE: Emotion selection removed permanently from AI comment flow

class PostAiCommentScreen extends StatefulWidget {
  PostAiCommentScreen(
      {super.key, required this.dataId, required this.commentType});

  final String dataId;
  final String commentType;

  @override
  State<PostAiCommentScreen> createState() => _PostAiCommentScreenState();
}

class _PostAiCommentScreenState extends State<PostAiCommentScreen> {
  final ctrl = Get.find<CommentController>();

  late final List<Worker> _workers;

  @override
  void initState() {
    ctrl.expandedTileIndex.value = -1;
    // Watch all 3 selections — re-enable Generate if user changes after generate
    _workers = [
      ever(ctrl.selectedLanguage, (_) => _onSelectionChanged()),
      ever(ctrl.selectedCommentType, (_) => _onSelectionChanged()),
    ];
    super.initState();
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.dispose();
  }

  /// Re-enable generate button when any selection changes after generation
  void _onSelectionChanged() {
    if (ctrl.isGenerated.value) {
      ctrl.isGenerated.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.aiGenerativeComment,
        onBackTap: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Obx(() {
          final hasSuggestions = ctrl.suggestions.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepIndicator(),
                      SizedBox(height: SizeConfig.size20),

                      // Step 1: Language (Dropdown)
                      _buildSectionCard(
                        stepNumber: '1',
                        title: AppStrings.selectLanguage,
                        isCompleted: ctrl.selectedLanguage.value.isNotEmpty,
                        child: CommonDropdownDialog<String>(
                          title: AppStrings.selectLanguage,
                          items: SUPPORTED_LANGUAGES,
                          selectedValue: ctrl.selectedLanguage.value.isEmpty
                              ? null
                              : ctrl.selectedLanguage.value,
                          hintText: 'Select Language',
                          displayValue: (lang) => lang,
                          onChanged: (val) {
                            if (val != null) {
                              ctrl.selectedLanguage.value = val;
                              _onSelectionChanged();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.size12),

                      // Step 2: Comment Type (Chips)
                      _buildSectionCard(
                        stepNumber: '2',
                        title: AppStrings.selectCommentType,
                        isCompleted: ctrl.selectedCommentType.value.isNotEmpty,
                        child: CommentTypeChipSelector(
                          items: commentTypes,
                          selectedType: ctrl.selectedCommentType,
                        ),
                      ),
                      SizedBox(height: SizeConfig.size20),

                      // Validation hint
                      if (!ctrl.isFormValid && !hasSuggestions)
                        _buildValidationHint(),

                      // Suggestions
                      if (hasSuggestions) ...[
                        _buildSuggestionsSection(),
                        SizedBox(height: SizeConfig.size16),
                      ],

                      SizedBox(height: SizeConfig.size20),
                    ],
                  ),
                ),
              ),

              _buildBottomBar(hasSuggestions),
            ],
          );
        }),
      ),
    );
  }


  // ─────────────────────────────────────────────
  // STEP INDICATOR
  // ─────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Obx(() {
      final step1 = ctrl.selectedLanguage.value.isNotEmpty;
      final step2 = ctrl.selectedCommentType.value.isNotEmpty;

      return Row(
        children: [
          _stepDot(completed: step1, label: 'Language'),
          _stepLine(completed: step1),
          _stepDot(completed: step2, label: 'Type'),
        ],
      );
    });
  }

  Widget _stepDot({required bool completed, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? AppColors.primaryColor : Colors.grey.shade200,
              border: Border.all(
                color: completed ? AppColors.primaryColor : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: completed
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          SizedBox(height: 4),
          CustomText(
            label,
            fontSize: 10,
            color: completed ? AppColors.primaryColor : AppColors.secondaryTextColor,
            fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget _stepLine({required bool completed}) {
    return Container(
      height: 2,
      width: 30,
      margin: EdgeInsets.only(bottom: 16),
      color: completed ? AppColors.primaryColor : Colors.grey.shade300,
    );
  }

  // ─────────────────────────────────────────────
  // SECTION CARD
  // ─────────────────────────────────────────────
  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required bool isCompleted,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primaryColor : Colors.grey.shade100,
                ),
                alignment: Alignment.center,
                child: CustomText(
                  stepNumber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.white : AppColors.secondaryTextColor,
                ),
              ),
              SizedBox(width: 8),
              CustomText(
                title,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              Spacer(),
              if (isCompleted)
                Icon(Icons.check_circle, color: AppColors.green00, size: 20),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VALIDATION HINT
  // ─────────────────────────────────────────────
  Widget _buildValidationHint() {
    final missing = <String>[];
    if (ctrl.selectedLanguage.value.isEmpty) missing.add('Language');
    if (ctrl.selectedCommentType.value.isEmpty) missing.add('Comment Type');

    if (missing.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: CustomText(
              'Please select: ${missing.join(', ')}',
              fontSize: 12,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUGGESTIONS
  // ─────────────────────────────────────────────
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.grey.shade200),
        SizedBox(height: SizeConfig.size12),
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryColor, size: 20),
            SizedBox(width: 6),
            CustomText(
              '${AppStrings.suggestions.tr}',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        ...ctrl.suggestions.map((sugg) {
          final isSelected = ctrl.selectedSuggestion.value == sugg;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                ctrl.selectedSuggestion.value = sugg;
                ctrl.sendMessageController.text = sugg;
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        sugg,
                        fontSize: 13,
                        color: AppColors.mainTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR — "Post your reply" input (ss13.png)
  // ─────────────────────────────────────────────
  Widget _buildBottomBar(bool hasSuggestions) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.isFormValid
                    ? () async {
                        if (widget.commentType == "comment") {
                          await ctrl.generateAiPostCommentController(
                              postID: widget.dataId);
                        } else if (widget.commentType == "comment_reply") {
                          await ctrl.generateAiPostCommentReplyController(
                              commentID: widget.dataId);
                        }
                      }
                    : null,
                icon: Icon(Icons.auto_awesome, size: 20),
                label: CustomText(
                  hasSuggestions ? 'Regenerate' : 'Generate',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ctrl.isFormValid ? Colors.white : AppColors.secondaryTextColor,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.secondaryTextColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            // Reply input + send
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl.sendMessageController,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppConstants.OpenSans,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Post your reply',
                      hintStyle: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.primaryColor),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final text = ctrl.sendMessageController.text.trim();
                    if (text.isNotEmpty) {
                      ctrl.sendMessageController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                      Get.back();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
