import 'dart:convert';
LanguageResModel languageResModelFromJson(String str) => LanguageResModel.fromJson(json.decode(str));
String languageResModelToJson(LanguageResModel data) => json.encode(data.toJson());
class LanguageResModel {
  LanguageResModel({
      this.languageCode, 
      this.languageName, 
      this.signUpText, 
      this.mobileNumText, 
      this.getOtp, 
      this.enterOtp, 
      this.chooseAccountType, 
      this.uploadYourPhotoLogo, 
      this.individualAccount, 
      this.businessListing, 
      this.takeFromCamera, 
      this.selectFromGallery, 
      this.yourName, 
      this.dateOfBirth, 
      this.selectGender, 
      this.selectYourProfession, 
      this.designation, 
      this.haveAReferralCode, 
      this.doYouHaveAGstNumber, 
      this.enterGstNumber, 
      this.requestOtp, 
      this.skip, 
      this.didntGetTheOtpCode, 
      this.resendCode, 
      this.location, 
      this.email, 
      this.highestEducation, 
      this.aboutMeBioSeeSample, 
      this.profilePicture, 
      this.fullName, 
      this.gender, 
      this.currentOrganization, 
      this.skills, 
      this.overview, 
      this.projectTitle, 
      this.writeProjectDescription, 
      this.companyName, 
      this.rolesResponsibilities, 
      this.emailOptional, 
      this.politicalPartyOrganizationTrustName, 
      this.addYourBusiness, 
      this.businessName, 
      this.dateOfIncorporation, 
      this.typeOfTheBusiness, 
      this.shopStore, 
      this.provideServices, 
      this.both, 
      this.natureOfTheBusiness, 
      this.categoryOfBusiness, 
      this.comments, 
      this.writeComment, 
      this.search, 
      this.allPosts, 
      this.videos, 
      this.shorts, 
      this.learning, 
      this.saved, 
      this.chooseYourCard, 
      this.changeBackground, 
      this.fontStyle, 
      this.textColor, 
      this.descriptionOfMessage, 
      this.addLinkReferenceWebsite, 
      this.addTagPeopleOrganization, 
      this.natureOfPost, 
      this.postNow, 
      this.tagPeople, 
      this.taggedPeople, 
      this.yourQuestion, 
      this.option1, 
      this.option2, 
      this.addMoreOption, 
      this.addCommentOrDescriptionOptional, 
      this.uploadPhotos, 
      this.addMore, 
      this.natureOfPostOptional, 
      this.uploadedPhotos, 
      this.camera, 
      this.videoPreview, 
      this.createShortVideo, 
      this.addCover, 
      this.description, 
      this.tagPeopleOptional, 
      this.addLocationOptional, 
      this.addSongOptional, 
      this.addLongVideoLinkOptional, 
      this.selectCategory, 
      this.addKeywords, 
      this.isThisVideoContent18, 
      this.showComments, 
      this.howToEarnWithBlueEra, 
      this.acceptBookingsOrEnquiries, 
      this.enableGifts, 
      this.longVideoTitle, 
      this.videoSubtitle, 
      this.videoDescription, 
      this.searching, 
      this.discover, 
      this.favorites, 
      this.searchMusic, 
      this.addSong, 
      this.jobPostImage, 
      this.jobTitleDesignation, 
      this.department, 
      this.jobType, 
      this.workMode, 
      this.whatIsThePayType, 
      this.selectSalary, 
      this.doYouOfferAnyAdditionalPerks, 
      this.addOtherPerks, 
      this.jobHighlights, 
      this.typeYourJobDescription, 
      this.qualifications, 
      this.selectLanguages, 
      this.totalExperienceRequired, 
      this.genderOptional, 
      this.isThisAWalkInInterview, 
      this.communicationPreferences, 
      this.walkInInterviewAddress, 
      this.walkInStartDate, 
      this.walkInEndDate, 
      this.walkInTimings, 
      this.otherInstructions, 
      this.howShouldCandidatesContactYouAfterApplying, 
      this.askTheQuestionsToTheCandidates, 
      this.areYouWillingToRelocateYourself, 
      this.whatIsYourNoticePeriod, 
      this.addMoreQuestions, 
      this.searchHere, 
      this.useCurrentLocation, 
      this.selectCategoryNonCommercialOnly, 
      this.placeNameOnlyPublicPlaces, 
      this.addPhotosOfThePlaceMax5Images, 
      this.addressOrLandmark, 
      this.iConfirmThisIsNotABusinessOrCommercialPlace, 
      this.shortDescriptionOptional, 
      this.landlinePhoneNumberOptional, 
      this.enterEmail, 
      this.letOthersKnowWhenThisPlaceIsOpenToThePublic, 
      this.underReview, 
      this.bookAppointment, 
      this.masteringPhotoshopIn30MinutesFullTutorial, 
      this.channelLogo, 
      this.channelName, 
      this.userName, 
      this.channelBioInfo, 
      this.websiteOptional, 
      this.otherSocialMediaLinksOptional, 
      this.role, 
      this.company, 
      this.emailAddress, 
      this.address, 
      this.phoneNumber, 
      this.resume, 
      this.confirmYourAvailability, 
      this.updateAt, 
      this.price, 
      this.type, 
      this.applicationSend, 
      this.shortedList, 
      this.congrats, 
      this.businessLogo, 
      this.officeMobNoOfficeLandline, 
      this.city, 
      this.fullBusinessAddress, 
      this.subCategory, 
      this.businessDescription, 
      this.yourRoleInTheBusiness, 
      this.writeAFeedbackOptional, 
      this.chooseWhatYouWantToVerify, 
      this.chooseDocumentType, 
      this.uploadDocument, 
      this.bio, 
      this.highestQualification, 
      this.schoolCollageName, 
      this.boardName, 
      this.passingYear, 
      this.performanceScore, 
      this.enterYourGrossSalaryMonthly, 
      this.totalMonthlyDeduction, 
      this.earningViaPartTimeJobMonthly, 
      this.earningViaFreelancingJobMonthly, 
      this.totalEarningMonthly, 
      this.yourAnnualPackageIs, 
      this.yourExperience, 
      this.jobMode, 
      this.currentCompanyName, 
      this.currentYouAreWorkingHere, 
      this.workType, 
      this.startDate, 
      this.previousCompanyName, 
      this.endDate, 
      this.portfolioWorkSamples, 
      this.languagesThatYouSpeakUnderstand, 
      this.languagesThatYouCanWrite, 
      this.careerObjective, 
      this.whoAwardedYouOrganizationName, 
      this.nameOfTheAward, 
      this.awardedDate, 
      this.uploadAttachmentOptional, 
      this.dateAwarded, 
      this.certificateName, 
      this.certificateIssuedByOrganizationName, 
      this.certifiedDate, 
      this.certifications, 
      this.url, 
      this.publishedDate, 
      this.additionalInformation, 
      this.patentIssuedDate, 
      this.uploadPatentCertificate, 
      this.describeYourPatent, 
      this.startFrom, 
      this.startJourneyVia, 
      this.addStoppage, 
      this.enterPlace, 
      this.exactTransportationInformation, 
      this.chooseStoppage, 
      this.tartJourneyVia, 
      this.xactTransportationInformation, 
      this.ddMedia, 
      this.escription, 
      this.tayInformation, 
      this.oodInformation, 
      this.ddLinks, 
      this.nterAmount, 
      this.hoosePaymentMethod, 
      this.piId, 
      this.ostYourVideo, 
      this.choseVideoType, 
      this.name, 
      this.mobileNumber, 
      this.emailId, 
      this.appointmentType, 
      this.bookingFor, 
      this.newKey, 
      this.anotherKey, 
      this.selected,});

  LanguageResModel.fromJson(dynamic json) {
    languageCode = json['languageCode'];
    languageName = json['languageName'];
    signUpText = json['signUpText'];
    mobileNumText = json['mobileNumText'];
    getOtp = json['getOtp'];
    enterOtp = json['enterOtp'];
    chooseAccountType = json['chooseAccountType'];
    uploadYourPhotoLogo = json['uploadYourPhotoLogo'];
    individualAccount = json['individualAccount'];
    businessListing = json['businessListing'];
    takeFromCamera = json['takeFromCamera'];
    selectFromGallery = json['selectFromGallery'];
    yourName = json['yourName'];
    dateOfBirth = json['dateOfBirth'];
    selectGender = json['selectGender'];
    selectYourProfession = json['selectYourProfession'];
    designation = json['designation'];
    haveAReferralCode = json['haveAReferralCode'];
    doYouHaveAGstNumber = json['doYouHaveAGstNumber'];
    enterGstNumber = json['enterGstNumber'];
    requestOtp = json['requestOtp'];
    skip = json['skip'];
    didntGetTheOtpCode = json['didntGetTheOtpCode'];
    resendCode = json['resendCode'];
    location = json['location'];
    email = json['email'];
    highestEducation = json['highestEducation'];
    aboutMeBioSeeSample = json['aboutMeBioSeeSample'];
    profilePicture = json['profilePicture'];
    fullName = json['fullName'];
    gender = json['gender'];
    currentOrganization = json['currentOrganization'];
    skills = json['skills'];
    overview = json['overview'];
    projectTitle = json['projectTitle'];
    writeProjectDescription = json['writeProjectDescription'];
    companyName = json['companyName'];
    rolesResponsibilities = json['rolesResponsibilities'];
    emailOptional = json['emailOptional'];
    politicalPartyOrganizationTrustName = json['politicalPartyOrganizationTrustName'];
    addYourBusiness = json['addYourBusiness'];
    businessName = json['businessName'];
    dateOfIncorporation = json['dateOfIncorporation'];
    typeOfTheBusiness = json['typeOfTheBusiness'];
    shopStore = json['shopStore'];
    provideServices = json['provideServices'];
    both = json['both'];
    natureOfTheBusiness = json['natureOfTheBusiness'];
    categoryOfBusiness = json['categoryOfBusiness'];
    comments = json['comments'];
    writeComment = json['writeComment'];
    search = json['search'];
    allPosts = json['allPosts'];
    videos = json['videos'];
    shorts = json['shorts'];
    learning = json['learning'];
    saved = json['saved'];
    chooseYourCard = json['chooseYourCard'];
    changeBackground = json['changeBackground'];
    fontStyle = json['fontStyle'];
    textColor = json['textColor'];
    descriptionOfMessage = json['descriptionOfMessage'];
    addLinkReferenceWebsite = json['addLinkReferenceWebsite'];
    addTagPeopleOrganization = json['addTagPeopleOrganization'];
    natureOfPost = json['natureOfPost'];
    postNow = json['postNow'];
    tagPeople = json['tagPeople'];
    taggedPeople = json['taggedPeople'];
    yourQuestion = json['yourQuestion'];
    option1 = json['option1'];
    option2 = json['option2'];
    addMoreOption = json['addMoreOption'];
    addCommentOrDescriptionOptional = json['addCommentOrDescriptionOptional'];
    uploadPhotos = json['uploadPhotos'];
    addMore = json['addMore'];
    natureOfPostOptional = json['natureOfPostOptional'];
    uploadedPhotos = json['uploadedPhotos'];
    camera = json['camera'];
    videoPreview = json['videoPreview'];
    createShortVideo = json['createShortVideo'];
    addCover = json['addCover'];
    description = json['description'];
    tagPeopleOptional = json['tagPeopleOptional'];
    addLocationOptional = json['addLocationOptional'];
    addSongOptional = json['addSongOptional'];
    addLongVideoLinkOptional = json['addLongVideoLinkOptional'];
    selectCategory = json['selectCategory'];
    addKeywords = json['addKeywords'];
    isThisVideoContent18 = json['isThisVideoContent18'];
    showComments = json['showComments'];
    howToEarnWithBlueEra = json['howToEarnWithBlueEra'];
    acceptBookingsOrEnquiries = json['acceptBookingsOrEnquiries'];
    enableGifts = json['enableGifts'];
    longVideoTitle = json['longVideoTitle'];
    videoSubtitle = json['videoSubtitle'];
    videoDescription = json['videoDescription'];
    searching = json['searching'];
    discover = json['discover'];
    favorites = json['favorites'];
    searchMusic = json['searchMusic'];
    addSong = json['addSong'];
    jobPostImage = json['jobPostImage'];
    jobTitleDesignation = json['jobTitleDesignation'];
    department = json['department'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    whatIsThePayType = json['whatIsThePayType'];
    selectSalary = json['selectSalary'];
    doYouOfferAnyAdditionalPerks = json['doYouOfferAnyAdditionalPerks'];
    addOtherPerks = json['addOtherPerks'];
    jobHighlights = json['jobHighlights'];
    typeYourJobDescription = json['typeYourJobDescription'];
    qualifications = json['qualifications'];
    selectLanguages = json['selectLanguages'];
    totalExperienceRequired = json['totalExperienceRequired'];
    genderOptional = json['genderOptional'];
    isThisAWalkInInterview = json['isThisAWalkInInterview'];
    communicationPreferences = json['communicationPreferences'];
    walkInInterviewAddress = json['walkInInterviewAddress'];
    walkInStartDate = json['walkInStartDate'];
    walkInEndDate = json['walkInEndDate'];
    walkInTimings = json['walkInTimings'];
    otherInstructions = json['otherInstructions'];
    howShouldCandidatesContactYouAfterApplying = json['howShouldCandidatesContactYouAfterApplying'];
    askTheQuestionsToTheCandidates = json['askTheQuestionsToTheCandidates'];
    areYouWillingToRelocateYourself = json['areYouWillingToRelocateYourself'];
    whatIsYourNoticePeriod = json['whatIsYourNoticePeriod'];
    addMoreQuestions = json['addMoreQuestions'];
    searchHere = json['searchHere'];
    useCurrentLocation = json['useCurrentLocation'];
    selectCategoryNonCommercialOnly = json['selectCategoryNonCommercialOnly'];
    placeNameOnlyPublicPlaces = json['placeNameOnlyPublicPlaces'];
    addPhotosOfThePlaceMax5Images = json['addPhotosOfThePlaceMax5Images'];
    addressOrLandmark = json['addressOrLandmark'];
    iConfirmThisIsNotABusinessOrCommercialPlace = json['iConfirmThisIsNotABusinessOrCommercialPlace'];
    shortDescriptionOptional = json['shortDescriptionOptional'];
    landlinePhoneNumberOptional = json['landlinePhoneNumberOptional'];
    enterEmail = json['enterEmail'];
    letOthersKnowWhenThisPlaceIsOpenToThePublic = json['letOthersKnowWhenThisPlaceIsOpenToThePublic'];
    underReview = json['underReview'];
    bookAppointment = json['bookAppointment'];
    masteringPhotoshopIn30MinutesFullTutorial = json['masteringPhotoshopIn30MinutesFullTutorial'];
    channelLogo = json['channelLogo'];
    channelName = json['channelName'];
    userName = json['userName'];
    channelBioInfo = json['channelBioInfo'];
    websiteOptional = json['websiteOptional'];
    otherSocialMediaLinksOptional = json['otherSocialMediaLinksOptional'];
    role = json['role'];
    company = json['company'];
    emailAddress = json['emailAddress'];
    address = json['address'];
    phoneNumber = json['phoneNumber'];
    resume = json['resume'];
    confirmYourAvailability = json['confirmYourAvailability'];
    updateAt = json['updateAt'];
    price = json['price'];
    type = json['type'];
    applicationSend = json['applicationSend'];
    shortedList = json['shortedList'];
    congrats = json['congrats'];
    businessLogo = json['businessLogo'];
    officeMobNoOfficeLandline = json['officeMobNoOfficeLandline'];
    city = json['city'];
    fullBusinessAddress = json['fullBusinessAddress'];
    subCategory = json['subCategory'];
    businessDescription = json['businessDescription'];
    yourRoleInTheBusiness = json['yourRoleInTheBusiness'];
    writeAFeedbackOptional = json['writeAFeedbackOptional'];
    chooseWhatYouWantToVerify = json['chooseWhatYouWantToVerify'];
    chooseDocumentType = json['chooseDocumentType'];
    uploadDocument = json['uploadDocument'];
    bio = json['bio'];
    highestQualification = json['highestQualification'];
    schoolCollageName = json['schoolCollageName'];
    boardName = json['boardName'];
    passingYear = json['passingYear'];
    performanceScore = json['performanceScore'];
    enterYourGrossSalaryMonthly = json['enterYourGrossSalaryMonthly'];
    totalMonthlyDeduction = json['totalMonthlyDeduction'];
    earningViaPartTimeJobMonthly = json['earningViaPartTimeJobMonthly'];
    earningViaFreelancingJobMonthly = json['earningViaFreelancingJobMonthly'];
    totalEarningMonthly = json['totalEarningMonthly'];
    yourAnnualPackageIs = json['yourAnnualPackageIs'];
    yourExperience = json['yourExperience'];
    jobMode = json['jobMode'];
    currentCompanyName = json['currentCompanyName'];
    currentYouAreWorkingHere = json['currentYouAreWorkingHere'];
    workType = json['workType'];
    startDate = json['startDate'];
    previousCompanyName = json['previousCompanyName'];
    endDate = json['endDate'];
    portfolioWorkSamples = json['portfolioWorkSamples'];
    languagesThatYouSpeakUnderstand = json['languagesThatYouSpeakUnderstand'];
    languagesThatYouCanWrite = json['languagesThatYouCanWrite'];
    careerObjective = json['careerObjective'];
    whoAwardedYouOrganizationName = json['whoAwardedYouOrganizationName'];
    nameOfTheAward = json['nameOfTheAward'];
    awardedDate = json['awardedDate'];
    uploadAttachmentOptional = json['uploadAttachmentOptional'];
    dateAwarded = json['dateAwarded'];
    certificateName = json['certificateName'];
    certificateIssuedByOrganizationName = json['certificateIssuedByOrganizationName'];
    certifiedDate = json['certifiedDate'];
    certifications = json['certifications'];
    url = json['url'];
    publishedDate = json['publishedDate'];
    additionalInformation = json['additionalInformation'];
    patentIssuedDate = json['patentIssuedDate'];
    uploadPatentCertificate = json['uploadPatentCertificate'];
    describeYourPatent = json['describeYourPatent'];
    startFrom = json['startFrom'];
    startJourneyVia = json['startJourneyVia'];
    addStoppage = json['addStoppage'];
    enterPlace = json['enterPlace'];
    exactTransportationInformation = json['exactTransportationInformation'];
    chooseStoppage = json['chooseStoppage'];
    tartJourneyVia = json['tartJourneyVia'];
    xactTransportationInformation = json['xactTransportationInformation'];
    ddMedia = json['ddMedia'];
    escription = json['escription'];
    tayInformation = json['tayInformation'];
    oodInformation = json['oodInformation'];
    ddLinks = json['ddLinks'];
    nterAmount = json['nterAmount'];
    hoosePaymentMethod = json['hoosePaymentMethod'];
    piId = json['piId'];
    ostYourVideo = json['ostYourVideo'];
    choseVideoType = json['choseVideoType'];
    name = json['name'];
    mobileNumber = json['mobileNumber'];
    emailId = json['emailId'];
    appointmentType = json['appointmentType'];
    bookingFor = json['bookingFor'];
    newKey = json['newKey'];
    anotherKey = json['anotherKey'];
    selected = json['selected'];
  }
  String? languageCode;
  String? languageName;
  String? signUpText;
  String? mobileNumText;
  String? getOtp;
  String? enterOtp;
  String? chooseAccountType;
  String? uploadYourPhotoLogo;
  String? individualAccount;
  String? businessListing;
  String? takeFromCamera;
  String? selectFromGallery;
  String? yourName;
  String? dateOfBirth;
  String? selectGender;
  String? selectYourProfession;
  String? designation;
  String? haveAReferralCode;
  String? doYouHaveAGstNumber;
  String? enterGstNumber;
  String? requestOtp;
  String? skip;
  String? didntGetTheOtpCode;
  String? resendCode;
  String? location;
  String? email;
  String? highestEducation;
  String? aboutMeBioSeeSample;
  String? profilePicture;
  String? fullName;
  String? gender;
  String? currentOrganization;
  String? skills;
  String? overview;
  String? projectTitle;
  String? writeProjectDescription;
  String? companyName;
  String? rolesResponsibilities;
  String? emailOptional;
  String? politicalPartyOrganizationTrustName;
  String? addYourBusiness;
  String? businessName;
  String? dateOfIncorporation;
  String? typeOfTheBusiness;
  String? shopStore;
  String? provideServices;
  String? both;
  String? natureOfTheBusiness;
  String? categoryOfBusiness;
  String? comments;
  String? writeComment;
  String? search;
  String? allPosts;
  String? videos;
  String? shorts;
  String? learning;
  String? saved;
  String? chooseYourCard;
  String? changeBackground;
  String? fontStyle;
  String? textColor;
  String? descriptionOfMessage;
  String? addLinkReferenceWebsite;
  String? addTagPeopleOrganization;
  String? natureOfPost;
  String? postNow;
  String? tagPeople;
  String? taggedPeople;
  String? yourQuestion;
  String? option1;
  String? option2;
  String? addMoreOption;
  String? addCommentOrDescriptionOptional;
  String? uploadPhotos;
  String? addMore;
  String? natureOfPostOptional;
  String? uploadedPhotos;
  String? camera;
  String? videoPreview;
  String? createShortVideo;
  String? addCover;
  String? description;
  String? tagPeopleOptional;
  String? addLocationOptional;
  String? addSongOptional;
  String? addLongVideoLinkOptional;
  String? selectCategory;
  String? addKeywords;
  String? isThisVideoContent18;
  String? showComments;
  String? howToEarnWithBlueEra;
  String? acceptBookingsOrEnquiries;
  String? enableGifts;
  String? longVideoTitle;
  String? videoSubtitle;
  String? videoDescription;
  String? searching;
  String? discover;
  String? favorites;
  String? searchMusic;
  String? addSong;
  String? jobPostImage;
  String? jobTitleDesignation;
  String? department;
  String? jobType;
  String? workMode;
  String? whatIsThePayType;
  String? selectSalary;
  String? doYouOfferAnyAdditionalPerks;
  String? addOtherPerks;
  String? jobHighlights;
  String? typeYourJobDescription;
  String? qualifications;
  String? selectLanguages;
  String? totalExperienceRequired;
  String? genderOptional;
  String? isThisAWalkInInterview;
  String? communicationPreferences;
  String? walkInInterviewAddress;
  String? walkInStartDate;
  String? walkInEndDate;
  String? walkInTimings;
  String? otherInstructions;
  String? howShouldCandidatesContactYouAfterApplying;
  String? askTheQuestionsToTheCandidates;
  String? areYouWillingToRelocateYourself;
  String? whatIsYourNoticePeriod;
  String? addMoreQuestions;
  String? searchHere;
  String? useCurrentLocation;
  String? selectCategoryNonCommercialOnly;
  String? placeNameOnlyPublicPlaces;
  String? addPhotosOfThePlaceMax5Images;
  String? addressOrLandmark;
  String? iConfirmThisIsNotABusinessOrCommercialPlace;
  String? shortDescriptionOptional;
  String? landlinePhoneNumberOptional;
  String? enterEmail;
  String? letOthersKnowWhenThisPlaceIsOpenToThePublic;
  String? underReview;
  String? bookAppointment;
  String? masteringPhotoshopIn30MinutesFullTutorial;
  String? channelLogo;
  String? channelName;
  String? userName;
  String? channelBioInfo;
  String? websiteOptional;
  String? otherSocialMediaLinksOptional;
  String? role;
  String? company;
  String? emailAddress;
  String? address;
  String? phoneNumber;
  String? resume;
  String? confirmYourAvailability;
  String? updateAt;
  String? price;
  String? type;
  String? applicationSend;
  String? shortedList;
  String? congrats;
  String? businessLogo;
  String? officeMobNoOfficeLandline;
  String? city;
  String? fullBusinessAddress;
  String? subCategory;
  String? businessDescription;
  String? yourRoleInTheBusiness;
  String? writeAFeedbackOptional;
  String? chooseWhatYouWantToVerify;
  String? chooseDocumentType;
  String? uploadDocument;
  String? bio;
  String? highestQualification;
  String? schoolCollageName;
  String? boardName;
  String? passingYear;
  String? performanceScore;
  String? enterYourGrossSalaryMonthly;
  String? totalMonthlyDeduction;
  String? earningViaPartTimeJobMonthly;
  String? earningViaFreelancingJobMonthly;
  String? totalEarningMonthly;
  String? yourAnnualPackageIs;
  String? yourExperience;
  String? jobMode;
  String? currentCompanyName;
  String? currentYouAreWorkingHere;
  String? workType;
  String? startDate;
  String? previousCompanyName;
  String? endDate;
  String? portfolioWorkSamples;
  String? languagesThatYouSpeakUnderstand;
  String? languagesThatYouCanWrite;
  String? careerObjective;
  String? whoAwardedYouOrganizationName;
  String? nameOfTheAward;
  String? awardedDate;
  String? uploadAttachmentOptional;
  String? dateAwarded;
  String? certificateName;
  String? certificateIssuedByOrganizationName;
  String? certifiedDate;
  String? certifications;
  String? url;
  String? publishedDate;
  String? additionalInformation;
  String? patentIssuedDate;
  String? uploadPatentCertificate;
  String? describeYourPatent;
  String? startFrom;
  String? startJourneyVia;
  String? addStoppage;
  String? enterPlace;
  String? exactTransportationInformation;
  String? chooseStoppage;
  String? tartJourneyVia;
  String? xactTransportationInformation;
  String? ddMedia;
  String? escription;
  String? tayInformation;
  String? oodInformation;
  String? ddLinks;
  String? nterAmount;
  String? hoosePaymentMethod;
  String? piId;
  String? ostYourVideo;
  String? choseVideoType;
  String? name;
  String? mobileNumber;
  String? emailId;
  String? appointmentType;
  String? bookingFor;
  String? newKey;
  String? anotherKey;
  bool? selected;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['languageCode'] = languageCode;
    map['languageName'] = languageName;
    map['signUpText'] = signUpText;
    map['mobileNumText'] = mobileNumText;
    map['getOtp'] = getOtp;
    map['enterOtp'] = enterOtp;
    map['chooseAccountType'] = chooseAccountType;
    map['uploadYourPhotoLogo'] = uploadYourPhotoLogo;
    map['individualAccount'] = individualAccount;
    map['businessListing'] = businessListing;
    map['takeFromCamera'] = takeFromCamera;
    map['selectFromGallery'] = selectFromGallery;
    map['yourName'] = yourName;
    map['dateOfBirth'] = dateOfBirth;
    map['selectGender'] = selectGender;
    map['selectYourProfession'] = selectYourProfession;
    map['designation'] = designation;
    map['haveAReferralCode'] = haveAReferralCode;
    map['doYouHaveAGstNumber'] = doYouHaveAGstNumber;
    map['enterGstNumber'] = enterGstNumber;
    map['requestOtp'] = requestOtp;
    map['skip'] = skip;
    map['didntGetTheOtpCode'] = didntGetTheOtpCode;
    map['resendCode'] = resendCode;
    map['location'] = location;
    map['email'] = email;
    map['highestEducation'] = highestEducation;
    map['aboutMeBioSeeSample'] = aboutMeBioSeeSample;
    map['profilePicture'] = profilePicture;
    map['fullName'] = fullName;
    map['gender'] = gender;
    map['currentOrganization'] = currentOrganization;
    map['skills'] = skills;
    map['overview'] = overview;
    map['projectTitle'] = projectTitle;
    map['writeProjectDescription'] = writeProjectDescription;
    map['companyName'] = companyName;
    map['rolesResponsibilities'] = rolesResponsibilities;
    map['emailOptional'] = emailOptional;
    map['politicalPartyOrganizationTrustName'] = politicalPartyOrganizationTrustName;
    map['addYourBusiness'] = addYourBusiness;
    map['businessName'] = businessName;
    map['dateOfIncorporation'] = dateOfIncorporation;
    map['typeOfTheBusiness'] = typeOfTheBusiness;
    map['shopStore'] = shopStore;
    map['provideServices'] = provideServices;
    map['both'] = both;
    map['natureOfTheBusiness'] = natureOfTheBusiness;
    map['categoryOfBusiness'] = categoryOfBusiness;
    map['comments'] = comments;
    map['writeComment'] = writeComment;
    map['search'] = search;
    map['allPosts'] = allPosts;
    map['videos'] = videos;
    map['shorts'] = shorts;
    map['learning'] = learning;
    map['saved'] = saved;
    map['chooseYourCard'] = chooseYourCard;
    map['changeBackground'] = changeBackground;
    map['fontStyle'] = fontStyle;
    map['textColor'] = textColor;
    map['descriptionOfMessage'] = descriptionOfMessage;
    map['addLinkReferenceWebsite'] = addLinkReferenceWebsite;
    map['addTagPeopleOrganization'] = addTagPeopleOrganization;
    map['natureOfPost'] = natureOfPost;
    map['postNow'] = postNow;
    map['tagPeople'] = tagPeople;
    map['taggedPeople'] = taggedPeople;
    map['yourQuestion'] = yourQuestion;
    map['option1'] = option1;
    map['option2'] = option2;
    map['addMoreOption'] = addMoreOption;
    map['addCommentOrDescriptionOptional'] = addCommentOrDescriptionOptional;
    map['uploadPhotos'] = uploadPhotos;
    map['addMore'] = addMore;
    map['natureOfPostOptional'] = natureOfPostOptional;
    map['uploadedPhotos'] = uploadedPhotos;
    map['camera'] = camera;
    map['videoPreview'] = videoPreview;
    map['createShortVideo'] = createShortVideo;
    map['addCover'] = addCover;
    map['description'] = description;
    map['tagPeopleOptional'] = tagPeopleOptional;
    map['addLocationOptional'] = addLocationOptional;
    map['addSongOptional'] = addSongOptional;
    map['addLongVideoLinkOptional'] = addLongVideoLinkOptional;
    map['selectCategory'] = selectCategory;
    map['addKeywords'] = addKeywords;
    map['isThisVideoContent18'] = isThisVideoContent18;
    map['showComments'] = showComments;
    map['howToEarnWithBlueEra'] = howToEarnWithBlueEra;
    map['acceptBookingsOrEnquiries'] = acceptBookingsOrEnquiries;
    map['enableGifts'] = enableGifts;
    map['longVideoTitle'] = longVideoTitle;
    map['videoSubtitle'] = videoSubtitle;
    map['videoDescription'] = videoDescription;
    map['searching'] = searching;
    map['discover'] = discover;
    map['favorites'] = favorites;
    map['searchMusic'] = searchMusic;
    map['addSong'] = addSong;
    map['jobPostImage'] = jobPostImage;
    map['jobTitleDesignation'] = jobTitleDesignation;
    map['department'] = department;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['whatIsThePayType'] = whatIsThePayType;
    map['selectSalary'] = selectSalary;
    map['doYouOfferAnyAdditionalPerks'] = doYouOfferAnyAdditionalPerks;
    map['addOtherPerks'] = addOtherPerks;
    map['jobHighlights'] = jobHighlights;
    map['typeYourJobDescription'] = typeYourJobDescription;
    map['qualifications'] = qualifications;
    map['selectLanguages'] = selectLanguages;
    map['totalExperienceRequired'] = totalExperienceRequired;
    map['genderOptional'] = genderOptional;
    map['isThisAWalkInInterview'] = isThisAWalkInInterview;
    map['communicationPreferences'] = communicationPreferences;
    map['walkInInterviewAddress'] = walkInInterviewAddress;
    map['walkInStartDate'] = walkInStartDate;
    map['walkInEndDate'] = walkInEndDate;
    map['walkInTimings'] = walkInTimings;
    map['otherInstructions'] = otherInstructions;
    map['howShouldCandidatesContactYouAfterApplying'] = howShouldCandidatesContactYouAfterApplying;
    map['askTheQuestionsToTheCandidates'] = askTheQuestionsToTheCandidates;
    map['areYouWillingToRelocateYourself'] = areYouWillingToRelocateYourself;
    map['whatIsYourNoticePeriod'] = whatIsYourNoticePeriod;
    map['addMoreQuestions'] = addMoreQuestions;
    map['searchHere'] = searchHere;
    map['useCurrentLocation'] = useCurrentLocation;
    map['selectCategoryNonCommercialOnly'] = selectCategoryNonCommercialOnly;
    map['placeNameOnlyPublicPlaces'] = placeNameOnlyPublicPlaces;
    map['addPhotosOfThePlaceMax5Images'] = addPhotosOfThePlaceMax5Images;
    map['addressOrLandmark'] = addressOrLandmark;
    map['iConfirmThisIsNotABusinessOrCommercialPlace'] = iConfirmThisIsNotABusinessOrCommercialPlace;
    map['shortDescriptionOptional'] = shortDescriptionOptional;
    map['landlinePhoneNumberOptional'] = landlinePhoneNumberOptional;
    map['enterEmail'] = enterEmail;
    map['letOthersKnowWhenThisPlaceIsOpenToThePublic'] = letOthersKnowWhenThisPlaceIsOpenToThePublic;
    map['underReview'] = underReview;
    map['bookAppointment'] = bookAppointment;
    map['masteringPhotoshopIn30MinutesFullTutorial'] = masteringPhotoshopIn30MinutesFullTutorial;
    map['channelLogo'] = channelLogo;
    map['channelName'] = channelName;
    map['userName'] = userName;
    map['channelBioInfo'] = channelBioInfo;
    map['websiteOptional'] = websiteOptional;
    map['otherSocialMediaLinksOptional'] = otherSocialMediaLinksOptional;
    map['role'] = role;
    map['company'] = company;
    map['emailAddress'] = emailAddress;
    map['address'] = address;
    map['phoneNumber'] = phoneNumber;
    map['resume'] = resume;
    map['confirmYourAvailability'] = confirmYourAvailability;
    map['updateAt'] = updateAt;
    map['price'] = price;
    map['type'] = type;
    map['applicationSend'] = applicationSend;
    map['shortedList'] = shortedList;
    map['congrats'] = congrats;
    map['businessLogo'] = businessLogo;
    map['officeMobNoOfficeLandline'] = officeMobNoOfficeLandline;
    map['city'] = city;
    map['fullBusinessAddress'] = fullBusinessAddress;
    map['subCategory'] = subCategory;
    map['businessDescription'] = businessDescription;
    map['yourRoleInTheBusiness'] = yourRoleInTheBusiness;
    map['writeAFeedbackOptional'] = writeAFeedbackOptional;
    map['chooseWhatYouWantToVerify'] = chooseWhatYouWantToVerify;
    map['chooseDocumentType'] = chooseDocumentType;
    map['uploadDocument'] = uploadDocument;
    map['bio'] = bio;
    map['highestQualification'] = highestQualification;
    map['schoolCollageName'] = schoolCollageName;
    map['boardName'] = boardName;
    map['passingYear'] = passingYear;
    map['performanceScore'] = performanceScore;
    map['enterYourGrossSalaryMonthly'] = enterYourGrossSalaryMonthly;
    map['totalMonthlyDeduction'] = totalMonthlyDeduction;
    map['earningViaPartTimeJobMonthly'] = earningViaPartTimeJobMonthly;
    map['earningViaFreelancingJobMonthly'] = earningViaFreelancingJobMonthly;
    map['totalEarningMonthly'] = totalEarningMonthly;
    map['yourAnnualPackageIs'] = yourAnnualPackageIs;
    map['yourExperience'] = yourExperience;
    map['jobMode'] = jobMode;
    map['currentCompanyName'] = currentCompanyName;
    map['currentYouAreWorkingHere'] = currentYouAreWorkingHere;
    map['workType'] = workType;
    map['startDate'] = startDate;
    map['previousCompanyName'] = previousCompanyName;
    map['endDate'] = endDate;
    map['portfolioWorkSamples'] = portfolioWorkSamples;
    map['languagesThatYouSpeakUnderstand'] = languagesThatYouSpeakUnderstand;
    map['languagesThatYouCanWrite'] = languagesThatYouCanWrite;
    map['careerObjective'] = careerObjective;
    map['whoAwardedYouOrganizationName'] = whoAwardedYouOrganizationName;
    map['nameOfTheAward'] = nameOfTheAward;
    map['awardedDate'] = awardedDate;
    map['uploadAttachmentOptional'] = uploadAttachmentOptional;
    map['dateAwarded'] = dateAwarded;
    map['certificateName'] = certificateName;
    map['certificateIssuedByOrganizationName'] = certificateIssuedByOrganizationName;
    map['certifiedDate'] = certifiedDate;
    map['certifications'] = certifications;
    map['url'] = url;
    map['publishedDate'] = publishedDate;
    map['additionalInformation'] = additionalInformation;
    map['patentIssuedDate'] = patentIssuedDate;
    map['uploadPatentCertificate'] = uploadPatentCertificate;
    map['describeYourPatent'] = describeYourPatent;
    map['startFrom'] = startFrom;
    map['startJourneyVia'] = startJourneyVia;
    map['addStoppage'] = addStoppage;
    map['enterPlace'] = enterPlace;
    map['exactTransportationInformation'] = exactTransportationInformation;
    map['chooseStoppage'] = chooseStoppage;
    map['tartJourneyVia'] = tartJourneyVia;
    map['xactTransportationInformation'] = xactTransportationInformation;
    map['ddMedia'] = ddMedia;
    map['escription'] = escription;
    map['tayInformation'] = tayInformation;
    map['oodInformation'] = oodInformation;
    map['ddLinks'] = ddLinks;
    map['nterAmount'] = nterAmount;
    map['hoosePaymentMethod'] = hoosePaymentMethod;
    map['piId'] = piId;
    map['ostYourVideo'] = ostYourVideo;
    map['choseVideoType'] = choseVideoType;
    map['name'] = name;
    map['mobileNumber'] = mobileNumber;
    map['emailId'] = emailId;
    map['appointmentType'] = appointmentType;
    map['bookingFor'] = bookingFor;
    map['newKey'] = newKey;
    map['anotherKey'] = anotherKey;
    map['selected'] = selected;
    return map;
  }

}