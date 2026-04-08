import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/add_message_symbol.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/bottom_caption_field.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/symbol_upload_widget.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/top_left_options.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../widgets/commom_textfield.dart';
import '../../auth/controller/add_chat_symbol_controller.dart';

class AddChatSymbolScreen extends StatefulWidget {
  AddChatSymbolScreen(
      {super.key, this.message, this.sharedText, this.sharedFiles});

  final message;
  final String? sharedText;
  final List<SharedAttachment?>? sharedFiles;

  @override
  State<AddChatSymbolScreen> createState() => _AddChatSymbolScreenState();
}

class _AddChatSymbolScreenState extends State<AddChatSymbolScreen>
    with SingleTickerProviderStateMixin {
  final controller = Get.put(AddChatSymbolController());
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    controller.clearData();
    super.initState();
    _prefillSharedData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _prefillSharedData() {
    if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      final text = widget.sharedText!;
      final isLink = Uri.tryParse(text)?.hasScheme ?? false;
      if (isLink) {
        controller.choosePostType(PostType.link);
      } else {
        controller.choosePostType(PostType.text);
      }
      controller.linkTextSymbolController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF2D3142)),
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: CustomText(
          AppStrings.createSymbol,
          color: const Color(0xFF2D3142),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          Obx(() {
            if (controller.selectedPostType.value == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: Color(0xFF2D3142)),
                ),
                onPressed: () {
                  controller.clearData();
                },
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final canPost = controller.itTextOrLinkPost()
            ? true
            : controller.imagesList.length >= 1;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: AnimatedOpacity(
              opacity: canPost ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: canPost && !controller.isPosting.value
                    ? () => controller.createSymbol()
                    : null,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: canPost
                        ? const LinearGradient(
                            colors: [Color(0xFF0086FF), Color(0xFF5BA3F5)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: canPost ? null : const Color(0xFFBCC4D4),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canPost
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0086FF).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: controller.isPosting.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              CustomText(
                                AppStrings.postSymbolBtn.tr,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Obx(() {
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  if (controller.selectedPostType.value != null) ...[
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                  ],

                  // Type selector / Upload widget
                  _buildSection(
                    child: SymbolUploadWidget(),
                  ),

                  // Text/Link editor
                  if (controller.selectedPostType.value != null &&
                      controller.itTextOrLinkPost()) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      child: CreateMessagePostScreen(),
                    ),
                  ],

                  // Caption + Options
                  if (controller.selectedPostType.value != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!controller.itTextOrLinkPost()) ...[
                            CustomText(
                              AppStrings.captionLabel.tr,
                              color: const Color(0xFF2D3142),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 10),
                            CommonTextField(
                              validator: (val) => null,
                              textEditController: controller.captionController,
                              title: "",
                              hintText: AppStrings.writeSymbolHint.tr,
                              inputLength: 300,
                              maxLine: 3,
                              onChange: (v) {},
                            ),
                            const SizedBox(height: 8),
                          ],
                          TopLeftOptions(),
                          BottomCaptionField(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3142).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStepIndicator() {
    final type = controller.selectedPostType.value;
    final String label = type == PostType.image
        ? AppStrings.photoSymbol.tr
        : type == PostType.video
            ? AppStrings.videoSymbol.tr
            : type == PostType.text
                ? AppStrings.textSymbol.tr
                : AppStrings.linkSymbol.tr;
    final icon = type == PostType.image
        ? Icons.photo_rounded
        : type == PostType.video
            ? Icons.videocam_rounded
            : type == PostType.text
                ? Icons.text_fields_rounded
                : Icons.link_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0086FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF0086FF).withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0086FF)),
          const SizedBox(width: 6),
          CustomText(
            label,
            color: const Color(0xFF0086FF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
