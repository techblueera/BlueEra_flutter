import 'dart:async'; // Add this import

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/hobbies_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HobbiesScreen extends StatefulWidget {
  HobbiesScreen({super.key});

  @override
  State<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends State<HobbiesScreen> {
  final HobbiesController controller = Get.put(HobbiesController());
  HobbyType? _selectedHobby;
  final List<HobbyType> selectedHobbies = [];
  bool validate = false;

  // Add StreamSubscription to properly dispose
  StreamSubscription? _hobbiesSubscription;

  @override
  void initState() {
    super.initState();
    selectedHobbies.clear();
    for (var hobby in controller.hobbies) {
      final type = HobbyType.values.firstWhereOrNull(
          (t) => t.label.toLowerCase() == hobby['name']?.toLowerCase());
      if (type != null && !selectedHobbies.contains(type)) {
        selectedHobbies.add(type);
      }
    }
    if (controller.hobbies.isNotEmpty &&
        controller.hobbies[0]['description'] != null) {
      controller.descriptionController.text =
          controller.hobbies[0]['description']!;
    }
    validateForm();
  }

  @override
  void dispose() {
    // Cancel the subscription to prevent setState after dispose
    _hobbiesSubscription?.cancel();
    super.dispose();
  }

  void loadExistingHobbies() {
    // Properly store the subscription so we can cancel it
    _hobbiesSubscription = controller.hobbies.listen((hobbiesList) {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      selectedHobbies.clear();
      for (var hobby in hobbiesList) {
        final hobbyType = HobbyType.values.firstWhereOrNull(
          (type) => type.label.toLowerCase() == hobby['name']?.toLowerCase(),
        );
        if (hobbyType != null && !selectedHobbies.contains(hobbyType)) {
          selectedHobbies.add(hobbyType);
        }
      }

      // Check mounted again before setState
      if (mounted) {
        setState(() {
          validateForm();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);

    return Scaffold(
      appBar: const CommonBackAppBar(title: "Hobbies"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: SingleChildScrollView(
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Add Hobbies",
                    color: AppColors.black1A,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),

                  /// Dropdown
                  CommonDropdown<HobbyType>(
                    // items: HobbyType.values,
                    items: HobbyType.values
                        .where((type) =>
                            !selectedHobbies.contains(type) &&
                            !controller.hobbies.any((hobby) =>
                                hobby['name']?.toLowerCase() ==
                                type.label.toLowerCase()))
                        .toList(),
                    selectedValue: _selectedHobby,
                    hintText: "Select a hobby",
                    displayValue: (hobby) => hobby.label,
                    // onChanged: (value) {
                    //   if (!mounted) return;

                    //   setState(() {
                    //     _selectedHobby = value;
                    //     if (value != null && !selectedHobbies.contains(value)) {
                    //       selectedHobbies.add(value);

                    //       // ✅ Assign the selected label to controller and call addHobby
                    //       controller.hobbyController.text = value.label;
                    //       controller.addHobby();

                    //       _selectedHobby = null;
                    //     }

                    //     validateForm();
                    //   });
                    // },
                    onChanged: (value) {
                      if (!mounted) return;

                      setState(() {
                        _selectedHobby = value;

                        if (value != null && !selectedHobbies.contains(value)) {
                          selectedHobbies.add(value);

                          controller.hobbyController.text = value.label;

                          final desc =
                              controller.descriptionController.text.trim();
                          if (desc.isNotEmpty) {
                            controller.addHobby();
                          }
                        }

                        _selectedHobby = null;
                        validateForm();
                      });
                    },
                  ),

                  SizedBox(height: SizeConfig.size15),

                  /// Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedHobbies.map((hobby) {
                      return CommonChip(
                        label: hobby.label,
                        onDeleted: () {
                          if (!mounted) return; // Safety check

                          setState(() {
                            selectedHobbies.remove(hobby);
                            // Remove from controller's list
                            controller.removeHobbyByName(hobby.label);

                            validateForm();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: SizeConfig.size24),

                  CommonTextField(
                    title: "Description",
                    hintText: "Tell us about how you enjoy your hobbies...",
                    textEditController: controller.descriptionController,
                    maxLine: 4,
                    onChange: (value) {
                      // Update description for all selected hobbies
                      // controller.updateHobbiesDescription(value.trim());
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  CustomBtn(
                    // onTap: validate
                    //     ? () async {
                    //         try {
                    //           await controller.saveHobbies();

                    //           if (mounted) Navigator.pop(context, true);
                    //         } catch (e) {
                    //           if (mounted) {
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               SnackBar(
                    //                   content: Text("Failed to save hobbies")),
                    //             );
                    //           }
                    //         }
                    //       }
                    //     : null,
                    onTap: validate
                        ? () async {
                            if (controller.hobbyController.text.isNotEmpty &&
                                controller
                                    .descriptionController.text.isNotEmpty) {
                              controller.addHobby();
                            }

                            if (controller.hobbies.isEmpty) {
                              commonSnackBar(
                                  message: "Please add at least one hobby.");
                              return;
                            }

                            try {
                              await controller.saveHobbies();
                              if (mounted) Navigator.pop(context, true);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Failed to save hobbies")),
                                );
                              }
                            }
                          }
                        : null,

                    title: "Save",
                    isValidate: validate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final selectedHobbiesNotEmpty = selectedHobbies.isNotEmpty;

    if (!selectedHobbiesNotEmpty) {
      validate = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    validate = true;
    if (mounted) {
      setState(() {});
    }
  }
}
