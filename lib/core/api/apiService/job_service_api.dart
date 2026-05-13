/// All `job-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin JobServiceApi {
  //JOB POST
  final String jobPost = "job-service/jobs";
  String jobPostStep2(String jobId) => "job-service/jobs/$jobId/step2";
  String jobPostStep3(String jobId) => "job-service/jobs/$jobId/step3";
  String jobPostStep4(String jobId) => "job-service/jobs/$jobId/step4";
  String publishJob(String jobId) => "job-service/jobs/$jobId/publish";
  String updateJobDetails(String jobId) => "job-service/jobs/$jobId";

  String getJobDetails(String jobId) => "job-service/jobs/$jobId";
  String getResumeById(String resumeId) => "job-service/resumes/$resumeId";
  final String getAllJobs = "job-service/jobs";
  final String getAllResumes = "job-service/resumes";
  final String jobApplication = "job-service/applications";

  ///SAVED,DELETE,GET
  final String savedJob = 'job-service/saved-jobs';
  final String jobServiceFeedback = 'job-service/feedback';
  final String applicationBulkClear = 'job-service/applications/bulk-clear';
  final String applicationJobService = 'job-service/applications/job/';
  final String jobServiceInterviews = 'job-service/interviews/bulk-schedule';
  final String jobServiceInterviewsReschedule =
      'job-service/interviews/bulk-reschedule';
  final String jobApplicationJob = 'job-service/applications/job/';
  final String jobApplicationStatusBulk =
      'job-service/applications/bulk-status';
  final String jobServiceInterviewsFeedback = 'job-service/interviews/';

  // job-service/interviews/bulk-reschedule

  // final String jobServiceInterviews='job-service/interviews';

  final String jobWithScheduleInterview = 'job-service/jobs/with-interviews';
  final String candidateWithScheduleInterview =
      'job-service/interviews/candidate';
  final String jobSearch = 'job-service/feed/search';
}
