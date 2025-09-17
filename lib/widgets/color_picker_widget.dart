import 'package:flutter/material.dart';


class ColorPickerWidget extends StatefulWidget {
  final Function(Color) onColorSelected;

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
  double canvasX = 0.8;
  double canvasY = 0.2;

  @override
  void initState() {
    super.initState();
    selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 20),

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
                              saturation = 1.0 - canvasX;
                              brightness = 1.0 - canvasY;
                              selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
                            });
                          },
                          onTapDown: (details) {
                            setState(() {
                              canvasX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                              canvasY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                              saturation = 1.0 - canvasX;
                              brightness = 1.0 - canvasY;
                              selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
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
              height: 30,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        hue = (details.localPosition.dx / constraints.maxWidth * 360).clamp(0.0, 360.0);
                        selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
                      });
                    },
                    onTapDown: (details) {
                      setState(() {
                        hue = (details.localPosition.dx / constraints.maxWidth * 360).clamp(0.0, 360.0);
                        selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
                      });
                    },
                    child: Stack(
                      children: [
                        Positioned(
                          left: ((hue / 360) * (constraints.maxWidth - 20)).clamp(0.0, constraints.maxWidth - 20),
                          top: 5,
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

            // Selected Color Preview
            Row(
              children: [
                Text(
                  'Selected Color:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Add Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.blue,
              ),
              child: TextButton(
                onPressed: () => widget.onColorSelected(selectedColor),
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}