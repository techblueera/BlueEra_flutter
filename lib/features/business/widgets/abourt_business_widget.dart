import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AboutBusinessWidget extends StatefulWidget {
  final String businessDescription;
  final List<String> livePhotos;

  const AboutBusinessWidget({
    super.key,
    required this.businessDescription,
    required this.livePhotos,
  });

  @override
  State<AboutBusinessWidget> createState() => _AboutBusinessWidgetState();
}

class _AboutBusinessWidgetState extends State<AboutBusinessWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String displayText = widget.businessDescription.isNotEmpty
        ? widget.businessDescription
        : "No business description available.";

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              "About Our Business",
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return _isExpanded
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      displayText,
                      style: const TextStyle(fontSize: 14)
                  ),
                  if (displayText.length > 100)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      child: Text(
                        ' read less',
                        style: const TextStyle(
                          color: Color(0xFF2399F5),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              )
                  : Text.rich(
                TextSpan(
                  text: displayText.length > 100
                      ? "${displayText.substring(0, 100)}... "
                      : displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: displayText.length > 100 ? [
                    TextSpan(
                      text: 'read more',
                      style: const TextStyle(
                        color: Color(0xFF2399F5),
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            _isExpanded = true;
                          });
                        },
                    ),
                  ] : [],
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Container(
            color: AppColors.white0D,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                child: Row(
                  children: widget.livePhotos.isNotEmpty
                      ? widget.livePhotos.map((photoUrl) {
                    return Padding(

                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          photoUrl,
                          width: 100,
                          height: 130,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 130,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 130,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList()
                      : [
                    Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text(
                        'No Photos\nAvailable',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}