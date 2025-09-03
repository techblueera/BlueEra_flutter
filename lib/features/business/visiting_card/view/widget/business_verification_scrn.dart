import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controller/view_business_details_controller.dart';
import '../../../business_verification/view/ownership_verification_screen.dart';
import 'business_verfication.dart';
import 'custom_verification_card.dart';

class BusinessVerificationScrn extends StatefulWidget {
  const BusinessVerificationScrn({super.key});

  @override
  State<BusinessVerificationScrn> createState() => _BusinessVerificationScrnState();
}

class _BusinessVerificationScrnState extends State<BusinessVerificationScrn> {

  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();
  final List<Map<String, dynamic>> verificationOptions = [
    {
      "title": "Business Verification",
      "description": "Verify your business details using GST or business documents.",
      "bulletPoints": [
        "Confirms your business is registered",
        "Required: GST or license/certificate"
      ]
    },
    {
      "title": "Ownership Verification",
      "description": "Verify that you are the owner of the business.",
      "bulletPoints": [
        "Confirms your identity as the business owner",
        "Required: Aadhaar, Voter ID, or similar"
      ]
    }
  ];
  @override
  void initState() {
    // TODO: implement initState
    viewBusinessDetailsController.getBusinessVerification();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CommonBackAppBar(

        title: "Business Verification",
      ),

      body:Padding(
        padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size20,vertical:  SizeConfig.size20,),
        child:
        Container(
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
          ),

          padding: EdgeInsets.all( SizeConfig.size18,),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            // spacing: SizeConfig.size10,
            children: [
              SizedBox(
                height: SizeConfig.screenHeight*0.32,
                width: double.infinity,
                child: Center(child: LocalAssets(imagePath: AppImageAssets.businessVerification,height: 200,width: 200,)),
              ),
              CustomText("Choose what you want to verify.",fontWeight: FontWeight.w700,fontSize: SizeConfig.extraLarge,),
              const SizedBox(height: 14,),
              SizedBox(
                height: 270,
                child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: verificationOptions.length,
                    itemBuilder: (context, index){
                      final item = verificationOptions[index];
                      return InkWell(
                        onTap: (){
                          if(index==0){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>BusinessVerification()));
                          }else{
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>OwnershipVerificationScreen()));
                          }
                        },
                        child: CustomVerificationCard(
                          title: item['title'],
                          description: item['description'],
                          bulletPoints: List<String>.from(item['bulletPoints']),
                        ),
                      );
                    }),
              ),
              const SizedBox(height: 14,),
              CustomBtn(
                onTap: (){

                },
                title: 'Verify Now',
                isValidate: true,
              ),

            ],
          ),
        )
      ),
    );
  }
}
