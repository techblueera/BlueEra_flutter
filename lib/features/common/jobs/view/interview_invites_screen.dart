import 'package:BlueEra/features/common/jobs/widget/job_application_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_icon_assets.dart';

class InterviewInvitesScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InterviewInvites();
}

class _InterviewInvites extends State<InterviewInvitesScreen> {
  // final scrollController = ScrollController();
  // late final JobBloc bloc;
  //
  // @override
  // void initState() {
  //   bloc = context.read<JobBloc>();
  //   bloc.add(GetInterviewJobEvent(userId: userId));
  //   scrollController.addListener(_onScroll);
  //   super.initState();
  // }
  //
  // void _onScroll() {
  //   if (scrollController.position.pixels >=
  //       scrollController.position.maxScrollExtent - 200) {
  //     if (bloc.state is GetAllJobPostLoaded) {
  //       final state = bloc.state as GetAllJobPostLoaded;
  //       if (!state.hasReachedEnd) {
  //         bloc.add(GetInterviewJobEvent(userId: userId));
  //       }
  //     }
  //   }
  // }
  //
  // @override
  // void dispose() {
  //   scrollController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:CommonBackAppBar(
        title: "InterView Invites",
        isCancelButton: true,
      ),
      body: ListView.builder(
          // controller: scrollController,
          itemBuilder: (context,index){
            return JobApplicationCard(
              jobTitle: "Wordpress Developer",
              companyName: "OMM Digital Solution Opc",
              timeAgo: "4h Ago",
              location: "South Dum Dum, Kolkata/Calcutta",
              salary: "₹ 15,000 - ₹ 25,000 monthly",
              jobType: "Full Time, Onsite",
              verticalLineAsset: AppIconAssets.verticalLineCompIcon,
              isShortlisted: true, companyLogo: '', companyBusinessId: '', jobPostImage: '', jobStatus: '', applicationID: '', jobID: '', feedBackSubmit: () {  }, isFeedBackStatus: false, removeJobCallBack: () {  },
            );
          },
          itemCount: 3
      ),
    );

    // return Scaffold(
    //   appBar: CommonBackAppBar(
    //     title: "InterView Invites",
    //     isCancelButton: true,
    //   ),
    //   body: BlocBuilder<JobBloc, JobState>(
    //     builder: (context, state) {
    //       if(state is InterviewJobPostLoading){
    //         return CircularProgressIndicator();
    //       }
    //
    //       if (state is InterviewJobPostFailure) {
    //         return Center(child: Text('Error: ${state.error}'));
    //       }
    //
    //       List<InterviewScheduled> interviewScheduled= [];
    //       if (state is InterviewJobPostLoaded) {
    //         interviewScheduled =  state.interviewScheduleJobModel;
    //       }
    //
    //       return interviewScheduled.isNotEmpty
    //           ? ListView.builder(
    //           controller: scrollController,
    //           itemCount: interviewScheduled.length,
    //           itemBuilder: (context, index) {
    //             InterviewScheduled item = interviewScheduled[index];
    //             String timeAgo = formatTimeAgo(item.createdAt??DateTime.now().toIso8601String());
    //
    //             return JobApplicationCard(
    //               jobTitle: item.title ?? "-",
    //               companyName: item.author?.company?.companyName ?? "",
    //               timeAgo: timeAgo,
    //               location: item.location??"-",
    //               salary: "₹ ${item.minSalary} - ₹ ${item.maxSalary} monthly",
    //               jobType: item.type??"-",
    //               verticalLineAsset: AppIconAssets.verticalLineCompIcon,
    //               isShortlisted: true,
    //             );
    //           },
    //       )
    //       : EmptyStateWidget(message: "No Applied Job");
    //     },
    //   ),
    // );
  }

}