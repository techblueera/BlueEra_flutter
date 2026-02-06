
import 'package:BlueEra/features/me/politician/widget/politician_achivements_page.dart';
import 'package:BlueEra/features/me/politician/widget/politician_activity_feed.dart';
import 'package:BlueEra/features/me/politician/widget/politician_event_schedule.dart';
import 'package:BlueEra/features/me/politician/widget/politician_profile_identity.dart';
import 'package:BlueEra/features/me/politician/widget/social_activity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../core/constants/size_config.dart';
import '../laboratory/view/widgets/me_menu_card_design.dart';
class PoliticianHomeCard extends StatefulWidget {
  const PoliticianHomeCard({super.key});

  @override
  State<PoliticianHomeCard> createState() => _PoliticianHomeCardState();
}

class _PoliticianHomeCardState extends State<PoliticianHomeCard> {
  List<String> nameList=[
    "Profile Identity",
    "Activity Feed",
    "Events / Schedule",
    "Achievements",
    "Vision & Mission",
    "Social Activity",
    "Job Portfolio/ Resume",
    "Contact",
  ];
  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          ...nameList.map((title) {
            return InkWell(
              onTap: () {
                if(title=='Profile Identity'){
                  Get.to(()=>PoliticianProfileIdentity());

                }else if(title=='Activity Feed'){
                  Get.to(()=>PoliticianActivityFeed());
                }else if(title=='Events / Schedule'){
                  Get.to(()=>PoliticianEventSchedule());
                }else if(title=='Achievements'){
                  Get.to(()=>PoliticianAchievementsPage());
                }else if(title=='Social Activity'){
                  Get.to(()=>SocialActivityListPage());
                }
              },
              child: MeMenuCardDesign(
                title: title,
                icon: '',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size100),

        ],
      ),
    );
  }
}
