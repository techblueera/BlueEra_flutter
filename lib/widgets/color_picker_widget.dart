import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ColorPickerWidget extends StatefulWidget {
  final Function(Color, String) onColorSelected; // Updated to include color name

  const ColorPickerWidget({Key? key, required this.onColorSelected}) : super(key: key);

  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  Color selectedColor = Colors.blue;
  double hue = 240.0; // Start with blue hue
  double saturation = 1.0;
  double brightness = 1.0;

  // Position variables for the color canvas selector
  double canvasX = 0.0; // Changed from 0.8 to 0.0 for accurate initial position
  double canvasY = 0.0; // Changed from 0.2 to 0.0 for accurate initial position

  // Text controller for color name
  final TextEditingController colorNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final FocusNode textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with correct saturation and brightness based on canvas position
    saturation = canvasX; // Fixed: saturation increases left to right
    brightness = 1.0 - canvasY; // brightness decreases top to bottom
    selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();

    // Listen to focus changes to scroll to text field
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        _scrollToTextField();
      }
    });
  }

  @override
  void dispose() {
    colorNameController.dispose();
    scrollController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  void _scrollToTextField() {
    // Add a small delay to ensure keyboard animation is complete
    Future.delayed(Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void updateColor() {
    setState(() {
      selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
    });
  }

  // Calculate the exact color at the canvas position considering all gradients
  Color getCanvasColorAtPosition() {
    // Start with the base hue color
    Color baseColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // Apply white gradient (saturation effect)
    double whiteAmount = 1.0 - canvasX; // More white towards left (low saturation)
    Color withWhite = Color.lerp(baseColor, Colors.white, whiteAmount)!;

    // Apply black gradient (brightness effect)
    double blackAmount = canvasY; // More black towards bottom (low brightness)
    Color finalColor = Color.lerp(withWhite, Colors.black, blackAmount)!;

    return finalColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom, // Add keyboard padding
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Colors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 16),

                // Color Canvas
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Base color background
                        Container(
                          decoration: BoxDecoration(
                            color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                          ),
                        ),
                        // White to transparent gradient (saturation)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.white, Colors.transparent],
                            ),
                          ),
                        ),
                        // Transparent to black gradient (brightness)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                            ),
                          ),
                        ),
                        // Touch detection
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  canvasX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                  canvasY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                                  saturation = canvasX; // Fixed: saturation increases left to right
                                  brightness = 1.0 - canvasY; // brightness decreases top to bottom
                                  updateColor();
                                });
                              },
                              onTapDown: (details) {
                                setState(() {
                                  canvasX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                  canvasY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                                  saturation = canvasX; // Fixed: saturation increases left to right
                                  brightness = 1.0 - canvasY; // brightness decreases top to bottom
                                  updateColor();
                                });
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                  // Color selector circle
                                  Positioned(
                                    left: (canvasX * (constraints.maxWidth - 20)).clamp(0.0, constraints.maxWidth - 20),
                                    top: (canvasY * (constraints.maxHeight - 20)).clamp(0.0, constraints.maxHeight - 20),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: getCanvasColorAtPosition(), // Show exact canvas color at this position
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Hue Slider
                Container(
                  height: SizeConfig.size26,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Color(0xFFFF00FF), // Magenta
                        Colors.red,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            hue = (details.localPosition.dx / constraints.maxWidth * 360).clamp(0.0, 360.0);
                            updateColor();
                          });
                        },
                        onTapDown: (details) {
                          setState(() {
                            hue = (details.localPosition.dx / constraints.maxWidth * 360).clamp(0.0, 360.0);
                            updateColor();
                          });
                        },
                        child: Stack(
                          children: [
                            Positioned(
                              left: ((hue / 360) * (constraints.maxWidth - 20)).clamp(0.0, constraints.maxWidth - 20),
                              top: 3,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16),

                // Selected Color Preview with Hex Value
                Row(
                  children: [
                    CustomText(
                      'Selected Color:',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: SizeConfig.size30,
                      height: SizeConfig.size30,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Color Name Input Field
                CommonTextField(
                  textEditController: colorNameController,
                  focusNode: textFieldFocusNode,
                  title: 'Color Name',
                  hintText: 'Enter a name for this color',
                  isValidate: true,
                  validator: (value){
                    if (value == null || value.isEmpty) return 'Color name is required';
                    return null;
                  },
                ),

                SizedBox(height: 20),

                // Add Button
                CustomBtn(
                  onTap: () {
                    if(formKey.currentState!.validate()){
                      String colorName = colorNameController.text.trim();
                      widget.onColorSelected(selectedColor, colorName);
                    }
                  },
                  title: 'Add',
                  bgColor: AppColors.primaryColor,
                ),

                SizedBox(height: 10)
              ],
            ),
          ),
        ),
      ),
    );
  }
}