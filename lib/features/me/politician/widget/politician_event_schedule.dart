import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/new_common_date_selection_dropdown.dart';

class PoliticianEventSchedule extends StatefulWidget {
  const PoliticianEventSchedule({super.key});

  @override
  State<PoliticianEventSchedule> createState() => _PoliticianEventScheduleState();
}

class _PoliticianEventScheduleState extends State<PoliticianEventSchedule> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  String? startDay, startMonth, startYear;
  String? endDay, endMonth, endYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(
        title: "Events / Schedule",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text("Event Title"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            hintText: "E.g. Virendra Kishor",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),
                        CustomText("Start Date"),
                        SizedBox(height: SizeConfig.size8),
                        NewDatePicker(
                          selectedDay:1,
                          selectedMonth: 11,
                          selectedYear: 2000,
                          onDayChanged: (val) => val,
                          onMonthChanged: (val) => val,
                          onYearChanged: (val) => val,
                        ),
                        const SizedBox(height: 16),
                        CustomText("End Date"),
                        SizedBox(height: SizeConfig.size8),
                        NewDatePicker(
                          selectedDay:1,
                          selectedMonth: 11,
                          selectedYear: 2000,
                          onDayChanged: (val) => val,
                          onMonthChanged: (val) => val,
                          onYearChanged: (val) => val,
                        ),
                        const SizedBox(height: 16),
                        /// Time
                        const CustomText("Time"),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: "From - 12:00",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: "To - 12:00",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// Venue
                        const Text("Venue"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: venueController,
                          decoration: const InputDecoration(
                            hintText: "E.g. Virendra Kishor",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Event Type
                        const Text("Event Type"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: typeController,
                          decoration: const InputDecoration(
                            hintText: "E.g. Meeting / Show / Live..",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Registration Link
                        const Text("Registration Link"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: linkController,
                          decoration: const InputDecoration(
                            hintText: "E.g. https://registrationlink..",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 30),
                        CustomBtn(onTap: (){}, title: "Save",isValidate: true,),
                        const SizedBox(height: 15),
                      ],
                    ),
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
