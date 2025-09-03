import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class CommentShimmerUi extends StatelessWidget {
  const CommentShimmerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmer,
      highlightColor: AppColors.white,
      child: ListView.builder(
        itemCount: 15,
        padding: EdgeInsets.only(top: 15, left: 15, right: 15),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 45,
                width: 45,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
              ),
              SizedBox(width: SizeConfig.size10,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 25,
                      width: 200,
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(5)),
                    ),
                    Container(
                      height: 70,
                      width: Get.width,
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
