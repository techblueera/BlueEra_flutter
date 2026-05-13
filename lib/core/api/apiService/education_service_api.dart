/// All `education-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin EducationServiceApi {
  final String aiCreateSchool = 'education-service/ai/create-school';
  final String schoolAboutUs = 'education-service/about/school';
  final String schoolAboutUsUpdate = 'education-service/about/';
  final String educationUploadInit = "education-service/upload/init";
  final String schoolAboutAdd = 'education-service/about';
  final String schoolContact = 'education-service/contact/school';
  final String schoolUser = 'education-service/schools/user';
  final String schoolContactUpdate = 'education-service/contact/';
  final String schoolNotices = 'education-service/notices/school/';
  final String schoolNoticesAddDelete = 'education-service/notices';
  final String educationDepartments = 'education-service/departments';
  final String educationCourses = 'education-service/courses';
  final String educationServiceContact = 'education-service/contact';
  final String educationServiceAcademics = 'education-service/academics';
  final String educationServiceStudentCorner =
      'education-service/student-corner';
  final String educationServiceFaculty = 'education-service/faculty';
  final String campusLifeCategories =
      'education-service/campus-life-categories';
  final String campusLife = 'education-service/campus-life';
  final String schoolUserID = 'education-service/schools/';
}
