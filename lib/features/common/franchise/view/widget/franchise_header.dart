
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_image_assets.dart';


class FranchiseHeader extends StatefulWidget {

  const FranchiseHeader({
    super.key,
  });


  @override
  State<FranchiseHeader> createState() => _FranchiseHeaderState();
}

class _FranchiseHeaderState extends State<FranchiseHeader> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isBanner) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBanner) {
        } else {
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CommonCardWidget(
      padding: 0,
      cardMargin: 10,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                GestureDetector(
                  onTap: () => null,
                  // onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.17,
                    decoration: BoxDecoration(
                        color: Colors.blueGrey[100],
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        image:
                        DecorationImage(
                            image: AssetImage(AppImageAssets.franchise_home),
                            fit: BoxFit.fill)
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 10,
                  child: InkWell(
                    onTap: () => _pickImage(true),
                    child: Container(
                        width: 30,
                        height: 30,
                        child: LocalAssets(
                          imagePath: AppIconAssets.edit_banner_icon,
                        )),
                  ),
                ),

                // Logo Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 10)
                          ],
                          image:

                          DecorationImage(
                              image: AssetImage(AppImageAssets.franchise_logo),
                              fit: BoxFit.cover)

                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- FORM SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(
                    "Franchise Name",
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.whiteE5
                        )
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 2),
                      child: Center(
                        child: CustomText("Pin - 711711",color: AppColors.grayText,),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(Icons.star,color: AppColors.yellow,),
                    CustomText("4.8",color:AppColors.yellow,),
                    CustomText(" (48 reviews)"),
                    SizedBox(width: 6,),
                    LocalAssets(imagePath: AppIconAssets.location_new),
                    CustomText(" 2.7 Km"),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.location_new
                      , height: 16, width: 16,),
                    SizedBox(
                      width: SizeConfig.size6,
                    ),
                    Expanded(child:
                    CustomText(
                      "Forem ipsum dolor sit amet, consectetur....",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    )),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
