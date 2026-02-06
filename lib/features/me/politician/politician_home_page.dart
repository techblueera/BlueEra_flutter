import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/politician/politician_home_card.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';

import '../widget/no_product_profile.dart';

class PoliticianHomePage extends StatefulWidget {
  const PoliticianHomePage({super.key});

  @override
  State<PoliticianHomePage> createState() => _PoliticianHomePageState();
}
class _PoliticianHomePageState extends State<PoliticianHomePage>with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.size12,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0,vertical: 10),
                child: Row(
                  children: [
                  CustomText("Politician",fontSize: 16,fontWeight: FontWeight.w600,)
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 4,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: "Home"),
                  Tab(text: "Update"),
                  Tab(text: "Statics"),
                ],
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  NoProfileDetailsFound(content: "No OTC Items Found",),
                  PoliticianHomeCard(),
                  NoProfileDetailsFound(content: "No Statics Items Found",),
                ],
              ))
            ],
          ),
        )

    );

  }
}

