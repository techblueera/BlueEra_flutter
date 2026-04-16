import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../auth/controller/add_chat_symbol_controller.dart';

class CreateMessagePostScreen extends StatefulWidget {
  const CreateMessagePostScreen({super.key});

  @override
  State<CreateMessagePostScreen> createState() =>
      _CreateMessagePostScreenState();
}

class _CreateMessagePostScreenState extends State<CreateMessagePostScreen> {
  final previewContainerKey = GlobalKey();
  final controller = Get.put(AddChatSymbolController());

  final List<Color> colorOptions = [
    Colors.black,
    const Color(0xFF26C2DC),
    AppColors.primaryColor,
    const Color(0xFF7ACAA5),
    const Color(0xFF55C265),
    const Color(0xFF8FA842),
    const Color(0xFFB6B326),
    const Color(0xFFF1B32D),
    const Color(0xFFC1A03F),
    const Color(0xFFFE8A8B),
  ];

  @override
  void initState() {
    controller.selectedBgColor.value = colorOptions.first;
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<MessagePostController>();
    deleteIfRegistered<TagUserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0086FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.palette_rounded,
                  size: 16, color: Color(0xFF0086FF)),
            ),
            const SizedBox(width: 10),
            CustomText(
              AppStrings.designYourCard.tr,
              color: const Color(0xFF2D3142),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Card Preview
        Obx(() => RepaintBoundary(
              key: previewContainerKey,
              child: Container(
                decoration: BoxDecoration(
                  color: controller.selectedBgColor.value,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          controller.selectedBgColor.value.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                child: controller.selectedPostType.value == PostType.link
                    ? _buildLinkStickerPreview()
                    : _buildTextMessageEditor(),
              ),
            )),

        if (controller.selectedPostType.value == PostType.link) ...[
          const SizedBox(height: 16),
          _buildLinkInputRow(),
        ],

        const SizedBox(height: 22),

        // Color picker
        CustomText(
          AppStrings.backgroundLabel.tr,
          color: const Color(0xFF2D3142),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colorOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final color = colorOptions[index];
              return GestureDetector(
                onTap: () => controller.selectedBgColor.value = color,
                child: Obx(() {
                  final isSelected = controller.selectedBgColor.value == color;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                          )
                        : null,
                  );
                }),
              );
            },
          ),
        ),

        // Font customization (only for text posts)
        if (controller.selectedPostType.value != PostType.link) ...[
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 20),

          // Font Family
          _buildOptionRow(
            label: AppStrings.fontStyleLabel.tr,
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.fontStyles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final style = controller.fontStyles[index];
                  return Obx(() {
                    final isSelected =
                        controller.selectedFontFamily.value == style['family'];
                    return GestureDetector(
                      onTap: () =>
                          controller.changeFontFamily(style['family']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0086FF)
                              : const Color(0xFFF3F4F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          style['name']!,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3142),
                          fontWeight: FontWeight.w500,
                          fontFamily: style['family'],
                          fontSize: 13,
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Font Size
          _buildOptionRow(
            label: AppStrings.sizeLabel.tr,
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.fontSizeList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final size = controller.fontSizeList[index];
                  return Obx(() {
                    final isSelected =
                        controller.selectedFontSize.value == size;
                    return GestureDetector(
                      onTap: () => controller.changeFontSize(size),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0086FF)
                              : const Color(0xFFF3F4F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          "${size.toInt()}",
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3142),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Font Weight
          _buildOptionRow(
            label: AppStrings.weightLabel.tr,
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.fontWeightList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final weight = controller.fontWeightList[index];
                  return Obx(() {
                    final isSelected =
                        controller.selectedFontWeight.value == weight;
                    return GestureDetector(
                      onTap: () => controller.changeFontWeight(weight),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0086FF)
                              : const Color(0xFFF3F4F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          weight,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3142),
                          fontWeight: controller.getFontWeight(weight),
                          fontSize: 13,
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextMessageEditor() {
    return TextField(
      controller: controller.linkTextSymbolController,
      inputFormatters: [
        LengthLimitingTextInputFormatter(140),
      ],
      showCursor: true,
      cursorColor: Colors.white.withOpacity(0.7),
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      maxLines: null,
      expands: true,
      style: TextStyle(
        color: Colors.white,
        fontSize: controller.selectedFontSize.value,
        fontWeight:
            controller.getFontWeight(controller.selectedFontWeight.value),
        fontFamily: controller.selectedFontFamily.value,
        height: 1.3,
      ),
      onChanged: (val) {
        setState(() {});
      },
      decoration: InputDecoration(
        filled: false,
        isCollapsed: true,
        hintText: AppStrings.typeYourMessageHere.tr,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: controller.selectedFontSize.value,
          fontWeight:
              controller.getFontWeight(controller.selectedFontWeight.value),
          fontFamily: controller.selectedFontFamily.value,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
    );
  }

  Widget _buildLinkStickerPreview() {
    final link = controller.linkTextSymbolController.text.trim();
    final hasLink = link.isNotEmpty;
    
    // Extract domain for display
    String displayLink = "Link";
    try {
      if (hasLink) {
        final uri = Uri.parse(link.startsWith('http') ? link : 'https://$link');
        displayLink = uri.host.replaceAll('www.', '').toUpperCase();
        if (displayLink.isEmpty) displayLink = "LINK";
      }
    } catch (_) {}

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, 
                color: controller.selectedBgColor.value, 
                size: 20
              ),
              const SizedBox(width: 8),
              Flexible(
                child: CustomText(
                  displayLink,
                  color: controller.selectedBgColor.value,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_outward_rounded, 
                color: controller.selectedBgColor.value, 
                size: 14
              ),
            ],
          ),
        ),
        if (!hasLink) ...[
          const SizedBox(height: 14),
          CustomText(
            "Enter URL below to see preview",
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ],
      ],
    );
  }

  Widget _buildLinkInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.linkTextSymbolController,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: "https://example.com",
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          TextButton(
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                controller.linkTextSymbolController.text = data!.text!;
                setState(() {});
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const CustomText(
              "PASTE",
              color: Color(0xFF0086FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          color: const Color(0xFF2D3142),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF2D3142).withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
