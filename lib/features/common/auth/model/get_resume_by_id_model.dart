class GetResumeById {
  String? message;
  Resume? resume;

  GetResumeById({this.message, this.resume});

  GetResumeById.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    resume =
    json['resume'] != null ? new Resume.fromJson(json['resume']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.resume != null) {
      data['resume'] = this.resume!.toJson();
    }
    return data;
  }
}

class Resume {
  List<Education>? education;
  List<dynamic>? fullTimeExperience;
  List<dynamic>? partTimeExperience;
  List<dynamic>? skills;
  List<dynamic>? languages;
  List<dynamic>? portfolios;
  List<dynamic>? awards;
  List<dynamic>? achievements;
  List<dynamic>? certifications;
  List<dynamic>? publications;
  List<dynamic>? hobbies;
  List<dynamic>? additionalInformation;
  List<dynamic>? patents;
  List<dynamic>? ngoOrStudentOrgs;
  String? id;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? location;
  String? profilePicture;
  String? bio;
  SalaryDetails? salaryDetails;
  CurrentJob? currentJob;
  String? careerObjective;
  String? createdAt;
  String? updatedAt;

  Resume(
      {this.education,
        this.fullTimeExperience,
        this.partTimeExperience,
        this.skills,
        this.languages,
        this.portfolios,
        this.awards,
        this.achievements,
        this.certifications,
        this.publications,
        this.hobbies,
        this.additionalInformation,
        this.patents,
        this.ngoOrStudentOrgs,
        this.id,
        this.userId,
        this.name,
        this.email,
        this.phone,
        this.location,
        this.profilePicture,
        this.bio,
        this.salaryDetails,
        this.currentJob,
        this.careerObjective,
        this.createdAt,
        this.updatedAt});

  Resume.fromJson(Map<String, dynamic> json) {
    if (json['education'] != null) {
      education = <Education>[];
      json['education'].forEach((v) {
        education!.add(new Education.fromJson(v));
      });
    }
    if (json['fullTimeExperience'] != null) {
      fullTimeExperience = json['fullTimeExperience'] as List<dynamic>;
    }
    if (json['partTimeExperience'] != null) {
      partTimeExperience = json['partTimeExperience'] as List<dynamic>;
    }
    if (json['skills'] != null) {
      skills = json['skills'] as List<dynamic>;
    }
    if (json['languages'] != null) {
      languages = json['languages'] as List<dynamic>;
    }
    if (json['portfolios'] != null) {
      portfolios = json['portfolios'] as List<dynamic>;
    }
    if (json['awards'] != null) {
      awards = json['awards'] as List<dynamic>;
    }
    if (json['achievements'] != null) {
      achievements = json['achievements'] as List<dynamic>;
    }
    if (json['certifications'] != null) {
      certifications = json['certifications'] as List<dynamic>;
    }
    if (json['publications'] != null) {
      publications = json['publications'] as List<dynamic>;
    }
    if (json['hobbies'] != null) {
      hobbies = json['hobbies'] as List<dynamic>;
    }
    if (json['additionalInformation'] != null) {
      additionalInformation = json['additionalInformation'] as List<dynamic>;
    }
    if (json['patents'] != null) {
      patents = json['patents'] as List<dynamic>;
    }
    if (json['ngoOrStudentOrgs'] != null) {
      ngoOrStudentOrgs = json['ngoOrStudentOrgs'] as List<dynamic>;
    }
    id = json['id'];
    userId = json['userId'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    location = json['location'];
    profilePicture = json['profilePicture'];
    bio = json['bio'];
    salaryDetails = json['salaryDetails'] != null
        ? new SalaryDetails.fromJson(json['salaryDetails'])
        : null;
    currentJob = json['currentJob'] != null
        ? new CurrentJob.fromJson(json['currentJob'])
        : null;
    careerObjective = json['careerObjective'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.education != null) {
      data['education'] = this.education!.map((v) => v.toJson()).toList();
    }
    if (this.fullTimeExperience != null) {
      data['fullTimeExperience'] = this.fullTimeExperience!;
    }
    if (this.partTimeExperience != null) {
      data['partTimeExperience'] = this.partTimeExperience!;
    }
    if (this.skills != null) {
      data['skills'] = this.skills!;
    }
    if (this.languages != null) {
      data['languages'] = this.languages!;
    }
    if (this.portfolios != null) {
      data['portfolios'] = this.portfolios!;
    }
    if (this.awards != null) {
      data['awards'] = this.awards!;
    }
    if (this.achievements != null) {
      data['achievements'] = this.achievements!;
    }
    if (this.certifications != null) {
      data['certifications'] = this.certifications!;
    }
    if (this.publications != null) {
      data['publications'] = this.publications!;
    }
    if (this.hobbies != null) {
      data['hobbies'] = this.hobbies!;
    }
    if (this.additionalInformation != null) {
      data['additionalInformation'] = this.additionalInformation!;
    }
    if (this.patents != null) {
      data['patents'] = this.patents!;
    }
    if (this.ngoOrStudentOrgs != null) {
      data['ngoOrStudentOrgs'] = this.ngoOrStudentOrgs!;
    }
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['name'] = this.name;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['location'] = this.location;
    data['profilePicture'] = this.profilePicture;
    data['bio'] = this.bio;
    if (this.salaryDetails != null) {
      data['salaryDetails'] = this.salaryDetails!.toJson();
    }
    if (this.currentJob != null) {
      data['currentJob'] = this.currentJob!.toJson();
    }
    data['careerObjective'] = this.careerObjective;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class Education {
  String? highestQualification;
  String? schoolOrCollegeName;
  String? boardName;
  int? passingYear;
  String? percentage;

  Education(
      {this.highestQualification,
        this.schoolOrCollegeName,
        this.boardName,
        this.passingYear,
        this.percentage});

  Education.fromJson(Map<String, dynamic> json) {
    highestQualification = json['highestQualification'];
    schoolOrCollegeName = json['schoolOrCollegeName'];
    boardName = json['boardName'];
    passingYear = json['passingYear'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['highestQualification'] = this.highestQualification;
    data['schoolOrCollegeName'] = this.schoolOrCollegeName;
    data['boardName'] = this.boardName;
    data['passingYear'] = this.passingYear;
    data['percentage'] = this.percentage;
    return data;
  }
}

class SalaryDetails {
  int? grossSalary;
  int? monthlyDeduction;
  int? monthlyEarningViaPartTime;
  int? monthlyEarningViaFreelancing;
  int? monthlyTotalEarning;
  int? annualPackage;

  SalaryDetails(
      {this.grossSalary,
        this.monthlyDeduction,
        this.monthlyEarningViaPartTime,
        this.monthlyEarningViaFreelancing,
        this.monthlyTotalEarning,
        this.annualPackage});

  SalaryDetails.fromJson(Map<String, dynamic> json) {
    grossSalary = json['grossSalary'];
    monthlyDeduction = json['monthlyDeduction'];
    monthlyEarningViaPartTime = json['monthlyEarningViaPartTime'];
    monthlyEarningViaFreelancing = json['monthlyEarningViaFreelancing'];
    monthlyTotalEarning = json['monthlyTotalEarning'];
    annualPackage = json['annualPackage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['grossSalary'] = this.grossSalary;
    data['monthlyDeduction'] = this.monthlyDeduction;
    data['monthlyEarningViaPartTime'] = this.monthlyEarningViaPartTime;
    data['monthlyEarningViaFreelancing'] = this.monthlyEarningViaFreelancing;
    data['monthlyTotalEarning'] = this.monthlyTotalEarning;
    data['annualPackage'] = this.annualPackage;
    return data;
  }
}

class CurrentJob {
  bool? isExperienced;
  String? experience;
  String? jobType;
  String? currentCompanyName;
  bool? currentlyWorkingHere;
  String? designation;
  String? workMode;
  String? location;
  String? startDate;
  String? endDate;
  String? description;

  CurrentJob(
      {this.isExperienced,
        this.experience,
        this.jobType,
        this.currentCompanyName,
        this.currentlyWorkingHere,
        this.designation,
        this.workMode,
        this.location,
        this.startDate,
        this.endDate,
        this.description});

  CurrentJob.fromJson(Map<String, dynamic> json) {
    isExperienced = json['isExperienced'];
    experience = json['experience'];
    jobType = json['jobType'];
    currentCompanyName = json['currentCompanyName'];
    currentlyWorkingHere = json['currentlyWorkingHere'];
    designation = json['designation'];
    workMode = json['workMode'];
    location = json['location'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isExperienced'] = this.isExperienced;
    data['experience'] = this.experience;
    data['jobType'] = this.jobType;
    data['currentCompanyName'] = this.currentCompanyName;
    data['currentlyWorkingHere'] = this.currentlyWorkingHere;
    data['designation'] = this.designation;
    data['workMode'] = this.workMode;
    data['location'] = this.location;
    data['startDate'] = this.startDate;
    data['endDate'] = this.endDate;
    data['description'] = this.description;
    return data;
  }
}
