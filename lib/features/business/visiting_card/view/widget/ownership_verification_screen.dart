import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

class OwnershipVerificationScreen extends StatefulWidget {
  const OwnershipVerificationScreen({super.key});

  @override
  State<OwnershipVerificationScreen> createState() =>
      _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState
    extends State<OwnershipVerificationScreen> {
  OwnershipDocumentType? _selectedOwnershipDocument;
  bool validate = false;
  String? imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue3F,
      appBar: CommonBackAppBar(
        isLeading: true,
        title: "Ownership Verification",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Upload one document to verify your\nidentity as the business owner.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 2.0,
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                "*The name on the document should match your PAN\nname.",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.white45,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),

              /// Dropdown
              const Text(
                "Choose Document Type",
                style: TextStyle(fontSize: 12, color: AppColors.white),
              ),
              const SizedBox(height: 10),
              CommonDropdown<OwnershipDocumentType>(
                items: OwnershipDocumentType.values,
                selectedValue: _selectedOwnershipDocument,
                hintText: "Select a documemt type",
                displayValue: (type) => type.displayName,
                onChanged: (value) {
                  setState(() {
                    _selectedOwnershipDocument = value;
                    validateForm();
                  });
                },
              ),
              const SizedBox(height: 15),

             /// Upload Document Area
InkWell(
  onTap: () => pickImage(),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration: BoxDecoration(
      color: AppColors.black28,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(AppIconAssets.uploadIcon, height: 18),
        const SizedBox(width: 6),
        const Text(
          "Upload Document",
          style: TextStyle(color: AppColors.white, fontSize: 13),
        ),
        const SizedBox(width: 4),
        const Text(
          "/",
          style: TextStyle(color: AppColors.white, fontSize: 13),
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(AppIconAssets.cameraWhiteIcon, height: 18),
        const SizedBox(width: 6),
        const Text(
          "Take Photo",
          style: TextStyle(color: AppColors.white, fontSize: 13),
        ),
      ],
    ),
  ),
),


              if (imagePath != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.black28,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(AppIconAssets.image,
                          height: 16.67),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Text(
                              imagePath!.split('/').last,
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            imagePath = null;
                            validateForm();
                          });
                        },
                        child: SvgPicture.asset(
                          AppIconAssets.cross,
                          height: 8.0,
                        )
                      )
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              /// Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: validate
                        ? AppColors
                        .primaryColor // Blue when enabled (matches screenshot)
                        : AppColors.grey83, // Grey when disabled
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:() {

                  },
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final validDoc = _selectedOwnershipDocument != null;
    final validImage = imagePath != null && imagePath!.isNotEmpty;
    setState(() {
      validate = validDoc && validImage;
    });
  }

  Future<void> pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        imagePath = image.path;
        validateForm();
      });
    }
  }
}
