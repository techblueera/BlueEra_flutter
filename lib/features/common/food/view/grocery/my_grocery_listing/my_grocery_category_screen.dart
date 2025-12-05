import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/grocery_category_card.dart';
import 'package:flutter/material.dart';

class MyGroceryCategoryScreen extends StatelessWidget {
  const MyGroceryCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 10,
        padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size15,
            bottom: SizeConfig.size15 + kBottomNavigationBarHeight
        ),
        itemBuilder: (BuildContext context, int index) {
          return GroceryCategoryCard(

          );
        },
      )
    );
  }
}



