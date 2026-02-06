import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
class PoliticianProfileIdentity extends StatefulWidget {
  const PoliticianProfileIdentity({super.key});

  @override
  State<PoliticianProfileIdentity> createState() => _PoliticianProfileIdentityState();
}

class _PoliticianProfileIdentityState extends State<PoliticianProfileIdentity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Profile Identity",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white
          ),
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              CommonTextField(
                title: "Short Bio",
                maxLine: 4,
                hintText: "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
              ),
              SizedBox(height: SizeConfig.size16,),
              CommonTextField(
                title: "Your Journey",
                maxLine: 4,
                hintText: "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
              ),
              SizedBox(height: SizeConfig.size16,),
              CommonTextField(
                title: "Location ",
                hintText: "E.g. Lucknow Utter Prade...",
              ),
              SizedBox(height: SizeConfig.size16,),
              Row(
                children: [
                  Icon(Icons.add,color: AppColors.primaryColor,),
                  CustomText("Add Family Background",fontSize: 16,color: AppColors.primaryColor,)
                ],
              ),
              SizedBox(height: SizeConfig.size30,),
              CustomBtn(
                isValidate: true,
                onTap: (){

                },
                title: "Save",
              )
            ],
          ),
        ),
      ),
    );
  }
}
