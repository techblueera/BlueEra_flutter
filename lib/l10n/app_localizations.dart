import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @signUpText.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign up'**
  String get signUpText;

  /// No description provided for @mobileNumText.
  ///
  /// In en, this message translates to:
  /// **'Mobile number / Whatsapp number'**
  String get mobileNumText;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @oneTimePassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the One Time Password sent to'**
  String get oneTimePassword;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @enterSixDigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Six Digit OTP'**
  String get enterSixDigitOtp;

  /// No description provided for @enterBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Basic Details'**
  String get enterBasicDetails;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'LogOut'**
  String get logOut;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @registrationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Registration incomplete. Some features are restricted. '**
  String get registrationIncomplete;

  /// No description provided for @completeBasicDetailsLisintg.
  ///
  /// In en, this message translates to:
  /// **'Please complete the basic details before proceeding with the listing'**
  String get completeBasicDetailsLisintg;

  /// No description provided for @startListing.
  ///
  /// In en, this message translates to:
  /// **'Start Listing'**
  String get startListing;

  /// No description provided for @enterLandLineNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Landline Number'**
  String get enterLandLineNo;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number here'**
  String get enterMobileNumber;

  /// No description provided for @invalidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid Mobile Number'**
  String get invalidMobileNumber;

  /// No description provided for @iAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'I agree to'**
  String get iAgreeTo;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @checkMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Check Mobile Number'**
  String get checkMobileNumber;

  /// No description provided for @inText.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inText;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit the app'**
  String get pressBackAgainToExit;

  /// No description provided for @thisFieldCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get thisFieldCannotBeEmpty;

  /// No description provided for @spacesNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Spaces are not allowed'**
  String get spacesNotAllowed;

  /// No description provided for @onlyAlphanumericAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only alphanumeric characters are allowed'**
  String get onlyAlphanumericAllowed;

  /// No description provided for @mustContainOneNumeric.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one numeric character'**
  String get mustContainOneNumeric;

  /// No description provided for @oneLastStep.
  ///
  /// In en, this message translates to:
  /// **'One last step'**
  String get oneLastStep;

  /// No description provided for @addUsername.
  ///
  /// In en, this message translates to:
  /// **'Add Username'**
  String get addUsername;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUsername;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @suggestedUsernames.
  ///
  /// In en, this message translates to:
  /// **'Suggested Usernames'**
  String get suggestedUsernames;

  /// No description provided for @referCode.
  ///
  /// In en, this message translates to:
  /// **'Refer Code'**
  String get referCode;

  /// No description provided for @enterReferCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Refer Code'**
  String get enterReferCode;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Username'**
  String get pleaseEnterUsername;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @photoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get photoLibrary;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose Account Type'**
  String get chooseAccountType;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @pleaseAuthenticateToAccessTheAppSeamlessly.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to access the app seamlessly'**
  String get pleaseAuthenticateToAccessTheAppSeamlessly;

  /// No description provided for @pleaseEnterYourDevicePasswordToAccessTheAppSeamlessly.
  ///
  /// In en, this message translates to:
  /// **'Please enter your device password to access the app seamlessly'**
  String get pleaseEnterYourDevicePasswordToAccessTheAppSeamlessly;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @userCompanyJob.
  ///
  /// In en, this message translates to:
  /// **'User, Company, Job ...'**
  String get userCompanyJob;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No Results found'**
  String get noResultsFound;

  /// No description provided for @newPostsAvailable.
  ///
  /// In en, this message translates to:
  /// **'New posts available'**
  String get newPostsAvailable;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @youRepostedThis.
  ///
  /// In en, this message translates to:
  /// **'You Reposted this'**
  String get youRepostedThis;

  /// No description provided for @currentJob.
  ///
  /// In en, this message translates to:
  /// **'Current Job'**
  String get currentJob;

  /// No description provided for @subCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub-Category'**
  String get subCategory;

  /// No description provided for @deleteThisPost.
  ///
  /// In en, this message translates to:
  /// **'Delete this post'**
  String get deleteThisPost;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @translateToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Translate to English'**
  String get translateToEnglish;

  /// No description provided for @seeOriginal.
  ///
  /// In en, this message translates to:
  /// **'See Original'**
  String get seeOriginal;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get seeLess;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @youHaveAppliedToThisJob.
  ///
  /// In en, this message translates to:
  /// **'You have applied to this job'**
  String get youHaveAppliedToThisJob;

  /// No description provided for @applyForAJob.
  ///
  /// In en, this message translates to:
  /// **'Apply for a job'**
  String get applyForAJob;

  /// No description provided for @viewApplicants.
  ///
  /// In en, this message translates to:
  /// **'View Applicants'**
  String get viewApplicants;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @downloadResume.
  ///
  /// In en, this message translates to:
  /// **'Download Resume'**
  String get downloadResume;

  /// No description provided for @designationCompany.
  ///
  /// In en, this message translates to:
  /// **'Designation, Company'**
  String get designationCompany;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @resumeSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Resume saved to'**
  String get resumeSavedTo;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @tagWith.
  ///
  /// In en, this message translates to:
  /// **'Tag with'**
  String get tagWith;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @imageViewer.
  ///
  /// In en, this message translates to:
  /// **'Image Viewer'**
  String get imageViewer;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @reposts.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get reposts;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @andSymbol.
  ///
  /// In en, this message translates to:
  /// **'&'**
  String get andSymbol;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @youHaveNoNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet'**
  String get youHaveNoNotificationsYet;

  /// No description provided for @goToPost.
  ///
  /// In en, this message translates to:
  /// **'Go to Post'**
  String get goToPost;

  /// No description provided for @goToRequests.
  ///
  /// In en, this message translates to:
  /// **'Go to Requests'**
  String get goToRequests;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @aMessage.
  ///
  /// In en, this message translates to:
  /// **'a message'**
  String get aMessage;

  /// No description provided for @choosePostType.
  ///
  /// In en, this message translates to:
  /// **'Choose post type'**
  String get choosePostType;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJob;

  /// No description provided for @postAMessage.
  ///
  /// In en, this message translates to:
  /// **'Post a message'**
  String get postAMessage;

  /// No description provided for @askAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askAQuestion;

  /// No description provided for @youCanOnlyUpload.
  ///
  /// In en, this message translates to:
  /// **'You can only upload'**
  String get youCanOnlyUpload;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'files.'**
  String get files;

  /// No description provided for @fileSizeShouldNotExceed.
  ///
  /// In en, this message translates to:
  /// **'File size should not exceed'**
  String get fileSizeShouldNotExceed;

  /// No description provided for @mb.
  ///
  /// In en, this message translates to:
  /// **'MB.'**
  String get mb;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @egHiringForCarDriver.
  ///
  /// In en, this message translates to:
  /// **'Eg: Hiring for Car driver'**
  String get egHiringForCarDriver;

  /// No description provided for @pleaseEnterJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter Job title'**
  String get pleaseEnterJobTitle;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get jobDescription;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add description'**
  String get addDescription;

  /// No description provided for @pleaseEnterJobDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter job description'**
  String get pleaseEnterJobDescription;

  /// No description provided for @hiringLocation.
  ///
  /// In en, this message translates to:
  /// **'Hiring location'**
  String get hiringLocation;

  /// No description provided for @pleaseEnterJobLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter job Location'**
  String get pleaseEnterJobLocation;

  /// No description provided for @attachMedia.
  ///
  /// In en, this message translates to:
  /// **'Attach media'**
  String get attachMedia;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'(Photo)'**
  String get photo;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get addFile;

  /// No description provided for @youPostedAJob.
  ///
  /// In en, this message translates to:
  /// **'You posted a job!'**
  String get youPostedAJob;

  /// No description provided for @cityCountry.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get cityCountry;

  /// No description provided for @hideThisPost.
  ///
  /// In en, this message translates to:
  /// **'Hide this post'**
  String get hideThisPost;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @addMessage.
  ///
  /// In en, this message translates to:
  /// **'Add message'**
  String get addMessage;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @typeYourQuestionHere.
  ///
  /// In en, this message translates to:
  /// **'Type your question here'**
  String get typeYourQuestionHere;

  /// No description provided for @pleaseEnterYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please enter your question'**
  String get pleaseEnterYourQuestion;

  /// No description provided for @createOptions.
  ///
  /// In en, this message translates to:
  /// **'Create Options'**
  String get createOptions;

  /// No description provided for @typeYourOption1Here.
  ///
  /// In en, this message translates to:
  /// **'Type your option1 here'**
  String get typeYourOption1Here;

  /// No description provided for @typeYourOption2Here.
  ///
  /// In en, this message translates to:
  /// **'Type your option2 here'**
  String get typeYourOption2Here;

  /// No description provided for @typeYourOption3Here.
  ///
  /// In en, this message translates to:
  /// **'Type your option3 here'**
  String get typeYourOption3Here;

  /// No description provided for @typeYourOption4Here.
  ///
  /// In en, this message translates to:
  /// **'Type your option4 here'**
  String get typeYourOption4Here;

  /// No description provided for @pleaseEnterYourOption1.
  ///
  /// In en, this message translates to:
  /// **'Please enter your option1'**
  String get pleaseEnterYourOption1;

  /// No description provided for @pleaseEnterYourOption2.
  ///
  /// In en, this message translates to:
  /// **'Please enter your option2'**
  String get pleaseEnterYourOption2;

  /// No description provided for @pleaseEnterYourOption3.
  ///
  /// In en, this message translates to:
  /// **'Please enter your option3'**
  String get pleaseEnterYourOption3;

  /// No description provided for @pleaseEnterYourOption4.
  ///
  /// In en, this message translates to:
  /// **'Please enter your option4'**
  String get pleaseEnterYourOption4;

  /// No description provided for @pleaseEnterLessThan20Characters.
  ///
  /// In en, this message translates to:
  /// **'Please enter less than 20 characters'**
  String get pleaseEnterLessThan20Characters;

  /// No description provided for @youPostedAQuestion.
  ///
  /// In en, this message translates to:
  /// **'You posted a question!'**
  String get youPostedAQuestion;

  /// No description provided for @youPostedAMessage.
  ///
  /// In en, this message translates to:
  /// **'You posted a message!'**
  String get youPostedAMessage;

  /// No description provided for @photoVideo.
  ///
  /// In en, this message translates to:
  /// **'(Photo & Video)'**
  String get photoVideo;

  /// No description provided for @tagPeople.
  ///
  /// In en, this message translates to:
  /// **'Tag people'**
  String get tagPeople;

  /// No description provided for @tagsStartWithAtEgBlueEra.
  ///
  /// In en, this message translates to:
  /// **'tags start with @ eg:-@BlueEra'**
  String get tagsStartWithAtEgBlueEra;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @celebrate.
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get celebrate;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @insightful.
  ///
  /// In en, this message translates to:
  /// **'Insightful'**
  String get insightful;

  /// No description provided for @seeAllResults.
  ///
  /// In en, this message translates to:
  /// **'See all results'**
  String get seeAllResults;

  /// No description provided for @thisFeatureWillBeUnavailableUntilYouFinishYourRegistration.
  ///
  /// In en, this message translates to:
  /// **'This feature will be unavailable until you finish your registration'**
  String get thisFeatureWillBeUnavailableUntilYouFinishYourRegistration;

  /// No description provided for @startRegistration.
  ///
  /// In en, this message translates to:
  /// **'Start Registration'**
  String get startRegistration;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @noCommentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Comments Available'**
  String get noCommentsAvailable;

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeAComment;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'replies'**
  String get replies;

  /// No description provided for @see.
  ///
  /// In en, this message translates to:
  /// **'See'**
  String get see;

  /// No description provided for @moreReplies.
  ///
  /// In en, this message translates to:
  /// **'more replies'**
  String get moreReplies;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteComment;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPost;

  /// No description provided for @reportComment.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportComment;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @stateReason.
  ///
  /// In en, this message translates to:
  /// **'Please state reason'**
  String get stateReason;

  /// No description provided for @provideDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide additional details'**
  String get provideDetails;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @reportThisPost.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get reportThisPost;

  /// No description provided for @reportThisComment.
  ///
  /// In en, this message translates to:
  /// **'Report this comment'**
  String get reportThisComment;

  /// No description provided for @reportAndBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Report and Block this user'**
  String get reportAndBlockUser;

  /// No description provided for @reportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback. We will review and take necessary actions.'**
  String get reportSuccessMessage;

  /// No description provided for @repliesTo.
  ///
  /// In en, this message translates to:
  /// **'Replies to'**
  String get repliesTo;

  /// No description provided for @commentOnThis.
  ///
  /// In en, this message translates to:
  /// **'comment on this'**
  String get commentOnThis;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @youHaveReportedThisPost.
  ///
  /// In en, this message translates to:
  /// **'You have reported this post'**
  String get youHaveReportedThisPost;

  /// No description provided for @youHaveReportedThisComment.
  ///
  /// In en, this message translates to:
  /// **'You have reported this comment'**
  String get youHaveReportedThisComment;

  /// No description provided for @youHaveReportedThisUser.
  ///
  /// In en, this message translates to:
  /// **'You have reported this user'**
  String get youHaveReportedThisUser;

  /// No description provided for @inappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get inappropriateContent;

  /// No description provided for @promotesHatredViolence.
  ///
  /// In en, this message translates to:
  /// **'Promotes hatred / violence'**
  String get promotesHatredViolence;

  /// No description provided for @fraudOrScam.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get fraudOrScam;

  /// No description provided for @contentIsSpam.
  ///
  /// In en, this message translates to:
  /// **'Content is spam'**
  String get contentIsSpam;

  /// No description provided for @notARealPerson.
  ///
  /// In en, this message translates to:
  /// **'Not a real person'**
  String get notARealPerson;

  /// No description provided for @isAFakeAccount.
  ///
  /// In en, this message translates to:
  /// **'Is a fake account'**
  String get isAFakeAccount;

  /// No description provided for @issueHasBeenReported.
  ///
  /// In en, this message translates to:
  /// **'Issue has been reported'**
  String get issueHasBeenReported;

  /// No description provided for @thankYouForYourFeedbackWeWillReviewAndTakeNecessaryActions.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback. We will review and take necessary actions'**
  String get thankYouForYourFeedbackWeWillReviewAndTakeNecessaryActions;

  /// No description provided for @repost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repost;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
  String get linkCopiedToClipboard;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searchJobs.
  ///
  /// In en, this message translates to:
  /// **'Search Jobs'**
  String get searchJobs;

  /// No description provided for @egBangalore.
  ///
  /// In en, this message translates to:
  /// **'Eg: Bangalore'**
  String get egBangalore;

  /// No description provided for @buildYourNetworkByAddingConnections.
  ///
  /// In en, this message translates to:
  /// **'Build your network\nby adding connections'**
  String get buildYourNetworkByAddingConnections;

  /// No description provided for @startByImportingFromYourContactList.
  ///
  /// In en, this message translates to:
  /// **'Start by importing from your contact list'**
  String get startByImportingFromYourContactList;

  /// No description provided for @importContacts.
  ///
  /// In en, this message translates to:
  /// **'Import Contacts'**
  String get importContacts;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newText;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @noConnectionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Connections Available'**
  String get noConnectionsAvailable;

  /// No description provided for @searchInChats.
  ///
  /// In en, this message translates to:
  /// **'Search in chats'**
  String get searchInChats;

  /// No description provided for @newUnreadMsg.
  ///
  /// In en, this message translates to:
  /// **'New Unread msg'**
  String get newUnreadMsg;

  /// No description provided for @mediaSentOrReceived.
  ///
  /// In en, this message translates to:
  /// **'Media sent or received...'**
  String get mediaSentOrReceived;

  /// No description provided for @sendAMessageToStartAConversation.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start a conversation'**
  String get sendAMessageToStartAConversation;

  /// No description provided for @removeConnection.
  ///
  /// In en, this message translates to:
  /// **'Remove Connection'**
  String get removeConnection;

  /// No description provided for @doYouWishToProceedWithRemovingThisConnectionFromYourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Do you wish to proceed with removing this connection from your network?'**
  String get doYouWishToProceedWithRemovingThisConnectionFromYourNetwork;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @youHaveNoNewContactsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no new contacts yet'**
  String get youHaveNoNewContactsYet;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found '**
  String get found;

  /// No description provided for @peopleInYourContactList.
  ///
  /// In en, this message translates to:
  /// **'people in your contact list'**
  String get peopleInYourContactList;

  /// No description provided for @connectToAll.
  ///
  /// In en, this message translates to:
  /// **'Connect to all'**
  String get connectToAll;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please Try Again Later'**
  String get pleaseTryAgainLater;

  /// No description provided for @sendConnectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Send connection request'**
  String get sendConnectionRequest;

  /// No description provided for @pleaseSelectTheUsersYouWishToSendAConnectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Please select the users you wish to send a connection request'**
  String get pleaseSelectTheUsersYouWishToSendAConnectionRequest;

  /// No description provided for @sendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// No description provided for @currentOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Current Organisation'**
  String get currentOrganisation;

  /// No description provided for @itSeemsYouHaveNoContacts.
  ///
  /// In en, this message translates to:
  /// **'It seems you have no contacts'**
  String get itSeemsYouHaveNoContacts;

  /// No description provided for @searchInContacts.
  ///
  /// In en, this message translates to:
  /// **'Search in contacts'**
  String get searchInContacts;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invitationSent;

  /// No description provided for @sendInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Send Invite Link'**
  String get sendInviteLink;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m using BlueEra and would love for you to join me there. I\'m sending you an invite—download the app, and let\'s connect! at https://bluecs.in/app'**
  String get inviteMessage;

  /// No description provided for @checkThisOut.
  ///
  /// In en, this message translates to:
  /// **'Check this out!'**
  String get checkThisOut;

  /// No description provided for @loadMoreContacts.
  ///
  /// In en, this message translates to:
  /// **'Load More Contacts'**
  String get loadMoreContacts;

  /// No description provided for @pleaseSelectTheUsersYouWishToSendAnInvitation.
  ///
  /// In en, this message translates to:
  /// **'Please select the users you wish to send an Invitation'**
  String get pleaseSelectTheUsersYouWishToSendAnInvitation;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @youHaveNoInvitationsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no invitations yet'**
  String get youHaveNoInvitationsYet;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get rejectRequest;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectAndBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Reject & block user'**
  String get rejectAndBlockUser;

  /// No description provided for @partiallyBlockedUserCanSeeYourProfileAndPostsButCannotConnectOrSendYouMessagesOnBlueEra.
  ///
  /// In en, this message translates to:
  /// **'Partially blocked user can see your profile and posts, but cannot connect or send you messages on BlueEra'**
  String
      get partiallyBlockedUserCanSeeYourProfileAndPostsButCannotConnectOrSendYouMessagesOnBlueEra;

  /// No description provided for @fullyBlockedUserCannotSeeYourProfileOrPostsOnBlueEra.
  ///
  /// In en, this message translates to:
  /// **'Fully blocked user cannot see your profile or posts on BlueEra'**
  String get fullyBlockedUserCannotSeeYourProfileOrPostsOnBlueEra;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @youHaveNoBlockedConnections.
  ///
  /// In en, this message translates to:
  /// **'You have no blocked connections'**
  String get youHaveNoBlockedConnections;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @invitePeopleFromYourContacts.
  ///
  /// In en, this message translates to:
  /// **'Invite people from your contacts'**
  String get invitePeopleFromYourContacts;

  /// No description provided for @inviteAll.
  ///
  /// In en, this message translates to:
  /// **'Invite all'**
  String get inviteAll;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @partiallyBlockThisUser.
  ///
  /// In en, this message translates to:
  /// **'Partially block this user'**
  String get partiallyBlockThisUser;

  /// No description provided for @fullyBlockThisUser.
  ///
  /// In en, this message translates to:
  /// **'Fully block this user'**
  String get fullyBlockThisUser;

  /// No description provided for @areYouSureYouWantToBlockThisUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user?'**
  String get areYouSureYouWantToBlockThisUser;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @sayHiToStartAConversation.
  ///
  /// In en, this message translates to:
  /// **'Say hi to start a\nconversation!'**
  String get sayHiToStartAConversation;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @someImagesExceedTheMaximumSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Some images exceed the maximum size limit of 5MB. Please select smaller files.'**
  String get someImagesExceedTheMaximumSizeLimit;

  /// No description provided for @someVideosExceedTheMaximumSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Some videos exceed the maximum size limit of 50MB. Please select smaller files.'**
  String get someVideosExceedTheMaximumSizeLimit;

  /// No description provided for @videosMustBe30SecondsOrShorter.
  ///
  /// In en, this message translates to:
  /// **'Videos must be 30 seconds or shorter. Please select shorter videos.'**
  String get videosMustBe30SecondsOrShorter;

  /// No description provided for @someDocumentsExceedTheMaximumSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Some documents exceed the maximum size limit of 10MB. Please select smaller files.'**
  String get someDocumentsExceedTheMaximumSizeLimit;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @translateToHindi.
  ///
  /// In en, this message translates to:
  /// **'Translate to Hindi'**
  String get translateToHindi;

  /// No description provided for @enterOrganizationName.
  ///
  /// In en, this message translates to:
  /// **'Enter Organization Name'**
  String get enterOrganizationName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Name'**
  String get enterName;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @allPosts.
  ///
  /// In en, this message translates to:
  /// **'All posts'**
  String get allPosts;

  /// No description provided for @jobPosts.
  ///
  /// In en, this message translates to:
  /// **'Job posts'**
  String get jobPosts;

  /// No description provided for @editVisitingCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Visiting Card'**
  String get editVisitingCard;

  /// No description provided for @shareVisitingCard.
  ///
  /// In en, this message translates to:
  /// **'Share Visiting Card'**
  String get shareVisitingCard;

  /// No description provided for @doi.
  ///
  /// In en, this message translates to:
  /// **'D-O-I'**
  String get doi;

  /// No description provided for @wholesaler.
  ///
  /// In en, this message translates to:
  /// **'Wholesaler'**
  String get wholesaler;

  /// No description provided for @retailer.
  ///
  /// In en, this message translates to:
  /// **'Retailer'**
  String get retailer;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @profileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile views'**
  String get profileViews;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @joinedBlueEra.
  ///
  /// In en, this message translates to:
  /// **'Joined BlueEra'**
  String get joinedBlueEra;

  /// No description provided for @latestPost.
  ///
  /// In en, this message translates to:
  /// **'Latest Post'**
  String get latestPost;

  /// No description provided for @editBasicDetail.
  ///
  /// In en, this message translates to:
  /// **'Edit Basic Detail'**
  String get editBasicDetail;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @oneDocumentIsRequiredSoCanNotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'One Document is required so can not be deleted'**
  String get oneDocumentIsRequiredSoCanNotBeDeleted;

  /// No description provided for @chooseTheBusinessTypes.
  ///
  /// In en, this message translates to:
  /// **'Choose the Business Type'**
  String get chooseTheBusinessTypes;

  /// No description provided for @uploadYourBusinessServicesPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Business/Services Photo'**
  String get uploadYourBusinessServicesPhoto;

  /// No description provided for @saveAndNext.
  ///
  /// In en, this message translates to:
  /// **'Save & Next'**
  String get saveAndNext;

  /// No description provided for @medicalShop.
  ///
  /// In en, this message translates to:
  /// **'Medical Shop'**
  String get medicalShop;

  /// No description provided for @kiranaShop.
  ///
  /// In en, this message translates to:
  /// **'Kirana Shop'**
  String get kiranaShop;

  /// No description provided for @stationeryShop.
  ///
  /// In en, this message translates to:
  /// **'Stationery Shop'**
  String get stationeryShop;

  /// No description provided for @groceryStore.
  ///
  /// In en, this message translates to:
  /// **'Grocery Store'**
  String get groceryStore;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @mechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get mechanic;

  /// No description provided for @vehicleShowroom.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Showroom'**
  String get vehicleShowroom;

  /// No description provided for @coachingClasses.
  ///
  /// In en, this message translates to:
  /// **'Coaching Classes'**
  String get coachingClasses;

  /// No description provided for @workshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get workshop;

  /// No description provided for @productSale.
  ///
  /// In en, this message translates to:
  /// **'Product Sale'**
  String get productSale;

  /// No description provided for @onlyProvideServices.
  ///
  /// In en, this message translates to:
  /// **'Only provide Services'**
  String get onlyProvideServices;

  /// No description provided for @bothSalesAndServices.
  ///
  /// In en, this message translates to:
  /// **'Both Sales & Services'**
  String get bothSalesAndServices;

  /// No description provided for @detailsFor.
  ///
  /// In en, this message translates to:
  /// **'Details for'**
  String get detailsFor;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ifItsNotListedYouCanCreateOne.
  ///
  /// In en, this message translates to:
  /// **'If it\'s not listed, you can create one'**
  String get ifItsNotListedYouCanCreateOne;

  /// No description provided for @enterDocName.
  ///
  /// In en, this message translates to:
  /// **'Enter Doc Name'**
  String get enterDocName;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @dontHaveRequiredDocument.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Have Required Document'**
  String get dontHaveRequiredDocument;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @startAddingServiceAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Start Adding Service & Category'**
  String get startAddingServiceAndCategory;

  /// No description provided for @startAddingProductAndServicesAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Start Adding Product and Services & Category'**
  String get startAddingProductAndServicesAndCategory;

  /// No description provided for @listingIsNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Listing is Not Completed'**
  String get listingIsNotCompleted;

  /// No description provided for @startAddingProductAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Start Adding Product & Category'**
  String get startAddingProductAndCategory;

  /// No description provided for @selectProductCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Product Category'**
  String get selectProductCategory;

  /// No description provided for @selectServiceCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Service Category'**
  String get selectServiceCategory;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @noProductAdded.
  ///
  /// In en, this message translates to:
  /// **'No Product Added'**
  String get noProductAdded;

  /// No description provided for @startAddingProduct.
  ///
  /// In en, this message translates to:
  /// **'Start Adding Product'**
  String get startAddingProduct;

  /// No description provided for @bestSellingProduct.
  ///
  /// In en, this message translates to:
  /// **'Best Selling Product'**
  String get bestSellingProduct;

  /// No description provided for @noServiceAdded.
  ///
  /// In en, this message translates to:
  /// **'No Service Added'**
  String get noServiceAdded;

  /// No description provided for @startAddingServices.
  ///
  /// In en, this message translates to:
  /// **'Start Adding Services'**
  String get startAddingServices;

  /// No description provided for @ourServices.
  ///
  /// In en, this message translates to:
  /// **'Our Services'**
  String get ourServices;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @subscriptionExpireOn.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expire on'**
  String get subscriptionExpireOn;

  /// No description provided for @expiryInfo.
  ///
  /// In en, this message translates to:
  /// **'Expiry Info'**
  String get expiryInfo;

  /// No description provided for @rateOurBusiness.
  ///
  /// In en, this message translates to:
  /// **'Rate Our Business'**
  String get rateOurBusiness;

  /// No description provided for @ratedViewRating.
  ///
  /// In en, this message translates to:
  /// **'Rated - View Rating'**
  String get ratedViewRating;

  /// No description provided for @viewRating.
  ///
  /// In en, this message translates to:
  /// **'View Rating'**
  String get viewRating;

  /// No description provided for @businessLocationHere.
  ///
  /// In en, this message translates to:
  /// **'Business Location here'**
  String get businessLocationHere;

  /// No description provided for @bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get bad;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @whyCancelItAutoEndWhenPlanExpired.
  ///
  /// In en, this message translates to:
  /// **'Why cancel, it auto end When plan Expired'**
  String get whyCancelItAutoEndWhenPlanExpired;

  /// No description provided for @whyCancelItAutoEndOn.
  ///
  /// In en, this message translates to:
  /// **'Why cancel, it auto end on'**
  String get whyCancelItAutoEndOn;

  /// No description provided for @yourAccessAllPremiumFeatureEndNow.
  ///
  /// In en, this message translates to:
  /// **'Your access all premium Feature end now'**
  String get yourAccessAllPremiumFeatureEndNow;

  /// No description provided for @cancelSubscriptionNow.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription Now'**
  String get cancelSubscriptionNow;

  /// No description provided for @cancelOnExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Cancel On Expiry-Date'**
  String get cancelOnExpiryDate;

  /// No description provided for @unlimitedAddProductOrServices.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Add product or services'**
  String get unlimitedAddProductOrServices;

  /// No description provided for @yourListVisibleFor1Month.
  ///
  /// In en, this message translates to:
  /// **'Your list visible for 1 month'**
  String get yourListVisibleFor1Month;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @hideFeature.
  ///
  /// In en, this message translates to:
  /// **'Hide Feature'**
  String get hideFeature;

  /// No description provided for @showFeature.
  ///
  /// In en, this message translates to:
  /// **'Show Feature'**
  String get showFeature;

  /// No description provided for @pleaseSelectPlanToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Please select plan to redeem'**
  String get pleaseSelectPlanToRedeem;

  /// No description provided for @enableAutoPay.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Pay'**
  String get enableAutoPay;

  /// No description provided for @verifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Verified successfully'**
  String get verifiedSuccessfully;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @redeemCoin.
  ///
  /// In en, this message translates to:
  /// **'Redeem Coin'**
  String get redeemCoin;

  /// No description provided for @earnCoinByReferToFriend.
  ///
  /// In en, this message translates to:
  /// **'Earn Coin By Refer To Friend'**
  String get earnCoinByReferToFriend;

  /// No description provided for @earningInfo.
  ///
  /// In en, this message translates to:
  /// **'Earning Info'**
  String get earningInfo;

  /// No description provided for @availableCoinAndValue.
  ///
  /// In en, this message translates to:
  /// **'Available coin & Value'**
  String get availableCoinAndValue;

  /// No description provided for @chooseThePaymentTypeToRedeemCoin.
  ///
  /// In en, this message translates to:
  /// **'Choose the Payment Type To Redeem Coin'**
  String get chooseThePaymentTypeToRedeemCoin;

  /// No description provided for @finalAmountToPay.
  ///
  /// In en, this message translates to:
  /// **'Final Amount To Pay'**
  String get finalAmountToPay;

  /// No description provided for @pleasePayThrough.
  ///
  /// In en, this message translates to:
  /// **'Please Pay through'**
  String get pleasePayThrough;

  /// No description provided for @toRedeemCoins.
  ///
  /// In en, this message translates to:
  /// **'to redeem Coins'**
  String get toRedeemCoins;

  /// No description provided for @selectCoinToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Select Coin to Redeem'**
  String get selectCoinToRedeem;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @allPostsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found!'**
  String get allPostsNotFound;

  /// No description provided for @areYouSureYouWantToDeleteThisPost.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get areYouSureYouWantToDeleteThisPost;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post Deleted'**
  String get postDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @jobPostsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job posts not found!'**
  String get jobPostsNotFound;

  /// No description provided for @noActivityFound.
  ///
  /// In en, this message translates to:
  /// **'No activity found!'**
  String get noActivityFound;

  /// No description provided for @youLikedThisPost.
  ///
  /// In en, this message translates to:
  /// **'You Liked this Post'**
  String get youLikedThisPost;

  /// No description provided for @youCommentedOnThisJob.
  ///
  /// In en, this message translates to:
  /// **'You Commented on this job'**
  String get youCommentedOnThisJob;

  /// No description provided for @youAppliedToThisJob.
  ///
  /// In en, this message translates to:
  /// **'You Applied to this Job'**
  String get youAppliedToThisJob;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get selectType;

  /// No description provided for @pleaseChooseTypeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please choose type first'**
  String get pleaseChooseTypeFirst;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @mrp.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get mrp;

  /// No description provided for @ourPrice.
  ///
  /// In en, this message translates to:
  /// **'Our Price'**
  String get ourPrice;

  /// No description provided for @serviceDetail.
  ///
  /// In en, this message translates to:
  /// **'Service Detail'**
  String get serviceDetail;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategory;

  /// No description provided for @enterCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Category Title'**
  String get enterCategoryTitle;

  /// No description provided for @allFieldsNeedsToBeFilled.
  ///
  /// In en, this message translates to:
  /// **'All fields need to be filled'**
  String get allFieldsNeedsToBeFilled;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableBiometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometricAuthentication;

  /// No description provided for @useFingerprintOrFaceIdToSecureYourApp.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID to secure your app'**
  String get useFingerprintOrFaceIdToSecureYourApp;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @provideAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide additional details'**
  String get provideAdditionalDetails;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @existingPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Existing phone number'**
  String get existingPhoneNumber;

  /// No description provided for @pleaseEnterCorrectMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter correct mobile number'**
  String get pleaseEnterCorrectMobileNumber;

  /// No description provided for @newPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'New phone number'**
  String get newPhoneNumber;

  /// No description provided for @newPhoneNumberShouldNotBeSameAsExistingPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'New phone number should not be same as existing phone number'**
  String get newPhoneNumberShouldNotBeSameAsExistingPhoneNumber;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @totalEarn.
  ///
  /// In en, this message translates to:
  /// **'Total Earn'**
  String get totalEarn;

  /// No description provided for @coin.
  ///
  /// In en, this message translates to:
  /// **'coin'**
  String get coin;

  /// No description provided for @earnExtraIncomeByReferringYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Earn extra income by referring your friends!'**
  String get earnExtraIncomeByReferringYourFriends;

  /// No description provided for @rs.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get rs;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterTheTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter The Total Amount'**
  String get enterTheTotalAmount;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @purposeOfPayment.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Payment'**
  String get purposeOfPayment;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @monthSubscription.
  ///
  /// In en, this message translates to:
  /// **'Month Subscription'**
  String get monthSubscription;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @officeNumber.
  ///
  /// In en, this message translates to:
  /// **'Office Number'**
  String get officeNumber;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @emailId.
  ///
  /// In en, this message translates to:
  /// **'Email id'**
  String get emailId;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @askQ.
  ///
  /// In en, this message translates to:
  /// **'Ask Q'**
  String get askQ;

  /// No description provided for @requiredDoc.
  ///
  /// In en, this message translates to:
  /// **'Required Doc'**
  String get requiredDoc;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get buy;

  /// No description provided for @moreDetail.
  ///
  /// In en, this message translates to:
  /// **'More Detail'**
  String get moreDetail;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @reportThisUser.
  ///
  /// In en, this message translates to:
  /// **'Report this user'**
  String get reportThisUser;

  /// No description provided for @profileIsNotCompletedYet.
  ///
  /// In en, this message translates to:
  /// **'Profile is not completed yet'**
  String get profileIsNotCompletedYet;

  /// No description provided for @youAreConnectedWith.
  ///
  /// In en, this message translates to:
  /// **'You are connected with'**
  String get youAreConnectedWith;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @addSummary.
  ///
  /// In en, this message translates to:
  /// **'Add Summary'**
  String get addSummary;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// No description provided for @tellUsAboutYourOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your organisation'**
  String get tellUsAboutYourOrganisation;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// No description provided for @aboutUsCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'About Us cannot be empty'**
  String get aboutUsCannotBeEmpty;

  /// No description provided for @aboutMeCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'About Me cannot be empty'**
  String get aboutMeCannotBeEmpty;

  /// No description provided for @aboutUsCannotBeMoreThan200Words.
  ///
  /// In en, this message translates to:
  /// **'About Us cannot be more than 200 words'**
  String get aboutUsCannotBeMoreThan200Words;

  /// No description provided for @aboutMeCannotBeMoreThan200Words.
  ///
  /// In en, this message translates to:
  /// **'About Me cannot be more than 200 words'**
  String get aboutMeCannotBeMoreThan200Words;

  /// No description provided for @addYourWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Add your work Experience'**
  String get addYourWorkExperience;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @addExperience.
  ///
  /// In en, this message translates to:
  /// **'Add Experience'**
  String get addExperience;

  /// No description provided for @workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get workExperience;

  /// No description provided for @enterDesignation.
  ///
  /// In en, this message translates to:
  /// **'Enter Designation'**
  String get enterDesignation;

  /// No description provided for @pleaseEnterYourDesignation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your designation'**
  String get pleaseEnterYourDesignation;

  /// No description provided for @enterOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Enter Organisation'**
  String get enterOrganisation;

  /// No description provided for @pleaseEnterYourOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your organisation'**
  String get pleaseEnterYourOrganisation;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @mm.
  ///
  /// In en, this message translates to:
  /// **'MM'**
  String get mm;

  /// No description provided for @yyyy.
  ///
  /// In en, this message translates to:
  /// **'YYYY'**
  String get yyyy;

  /// No description provided for @iCurrentlyWorkHere.
  ///
  /// In en, this message translates to:
  /// **'I currently work here'**
  String get iCurrentlyWorkHere;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @addYourEducation.
  ///
  /// In en, this message translates to:
  /// **'Add your Education'**
  String get addYourEducation;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add Education'**
  String get addEducation;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @enterCourseName.
  ///
  /// In en, this message translates to:
  /// **'Enter Course Name'**
  String get enterCourseName;

  /// No description provided for @pleaseEnterYourCourseName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Course Name'**
  String get pleaseEnterYourCourseName;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @enterInstitution.
  ///
  /// In en, this message translates to:
  /// **'Enter Institution'**
  String get enterInstitution;

  /// No description provided for @pleaseEnterYourInstitution.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Institution'**
  String get pleaseEnterYourInstitution;

  /// No description provided for @iCurrentlyStudyHere.
  ///
  /// In en, this message translates to:
  /// **'I currently study here'**
  String get iCurrentlyStudyHere;

  /// No description provided for @dOB.
  ///
  /// In en, this message translates to:
  /// **'D-O-B'**
  String get dOB;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @organisation.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get organisation;

  /// No description provided for @editWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Edit Work Experience'**
  String get editWorkExperience;

  /// No description provided for @updateExperience.
  ///
  /// In en, this message translates to:
  /// **'Update Experience'**
  String get updateExperience;

  /// No description provided for @editEducation.
  ///
  /// In en, this message translates to:
  /// **'Edit Education'**
  String get editEducation;

  /// No description provided for @updateEducation.
  ///
  /// In en, this message translates to:
  /// **'Update Education'**
  String get updateEducation;

  /// No description provided for @dd.
  ///
  /// In en, this message translates to:
  /// **'DD'**
  String get dd;

  /// No description provided for @editAboutMe.
  ///
  /// In en, this message translates to:
  /// **'Edit About Me'**
  String get editAboutMe;

  /// No description provided for @invalidForm.
  ///
  /// In en, this message translates to:
  /// **'Invalid Form'**
  String get invalidForm;

  /// No description provided for @pleaseScrollDownAndReviewAllFieldsToEnsureTheyAreFilledOutCorrectlyAndAreNotLeftEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please scroll down and review all fields to ensure they are filled out correctly and are not left empty.'**
  String
      get pleaseScrollDownAndReviewAllFieldsToEnsureTheyAreFilledOutCorrectlyAndAreNotLeftEmpty;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Full Name'**
  String get enterFullName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @jobLocation.
  ///
  /// In en, this message translates to:
  /// **'Job Location'**
  String get jobLocation;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Location'**
  String get enterLocation;

  /// No description provided for @pleaseEnterYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your location'**
  String get pleaseEnterYourLocation;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @egRelianceOrDpsSchool.
  ///
  /// In en, this message translates to:
  /// **'eg: reliance, or DPS school'**
  String get egRelianceOrDpsSchool;

  /// No description provided for @educationTillNow.
  ///
  /// In en, this message translates to:
  /// **'Education till now'**
  String get educationTillNow;

  /// No description provided for @egMaBaBEd.
  ///
  /// In en, this message translates to:
  /// **'eg: MA, BA, B.ED'**
  String get egMaBaBEd;

  /// No description provided for @jobRoleWork.
  ///
  /// In en, this message translates to:
  /// **'Job role/work'**
  String get jobRoleWork;

  /// No description provided for @egSrTeacherDriverOfficeAssistant.
  ///
  /// In en, this message translates to:
  /// **'eg: SR.TEACHER, DRIVER, OFFICE ASSISTANT'**
  String get egSrTeacherDriverOfficeAssistant;

  /// No description provided for @hidePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Hide phone number'**
  String get hidePhoneNumber;

  /// No description provided for @areYouSureYouWantToHideThisField.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide this field?'**
  String get areYouSureYouWantToHideThisField;

  /// No description provided for @areYouSureYouWantToShowThisField.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to show this field?'**
  String get areYouSureYouWantToShowThisField;

  /// No description provided for @yourPhoneNumberWillNotBeVisibleToOthersOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your phone number will not be visible to others on your profile'**
  String get yourPhoneNumberWillNotBeVisibleToOthersOnYourProfile;

  /// No description provided for @yourPhoneNumberWillBeVisibleToOthersOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your phone number will be visible to others on your profile'**
  String get yourPhoneNumberWillBeVisibleToOthersOnYourProfile;

  /// No description provided for @hideThisField.
  ///
  /// In en, this message translates to:
  /// **'Hide this field'**
  String get hideThisField;

  /// No description provided for @showThisField.
  ///
  /// In en, this message translates to:
  /// **'Show this field'**
  String get showThisField;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @yourRoleInOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Your Role in Organisation'**
  String get yourRoleInOrganisation;

  /// No description provided for @yourSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Your Sub-Category'**
  String get yourSubCategory;

  /// No description provided for @dateOfIncorporation.
  ///
  /// In en, this message translates to:
  /// **'Date of Incorporation'**
  String get dateOfIncorporation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @yourAddressMax60Characters.
  ///
  /// In en, this message translates to:
  /// **'Your Address (Max 60 characters)'**
  String get yourAddressMax60Characters;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @yourCity.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get yourCity;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @yourWebsite.
  ///
  /// In en, this message translates to:
  /// **'Your Website'**
  String get yourWebsite;

  /// No description provided for @officeMobNo.
  ///
  /// In en, this message translates to:
  /// **'Office Mob No'**
  String get officeMobNo;

  /// No description provided for @officeLandline.
  ///
  /// In en, this message translates to:
  /// **'Office Landline'**
  String get officeLandline;

  /// No description provided for @enterMobileNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile No'**
  String get enterMobileNo;

  /// No description provided for @enterLandlineCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Landline Code'**
  String get enterLandlineCode;

  /// No description provided for @prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get prefix;

  /// No description provided for @shortDescribeAboutOrganization.
  ///
  /// In en, this message translates to:
  /// **'Short Describe About Organization'**
  String get shortDescribeAboutOrganization;

  /// No description provided for @enterShortDescriptionMax60Characters.
  ///
  /// In en, this message translates to:
  /// **'Enter Short Description (Max 60 characters)'**
  String get enterShortDescriptionMax60Characters;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @youHaveMadeChangesToOneOrMoreFieldsInYourProfile.
  ///
  /// In en, this message translates to:
  /// **'You have made changes to one or more fields in your profile'**
  String get youHaveMadeChangesToOneOrMoreFieldsInYourProfile;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @pleaseEnterCurrentOrganisaition.
  ///
  /// In en, this message translates to:
  /// **'Please enter current organisation'**
  String get pleaseEnterCurrentOrganisaition;

  /// No description provided for @pleaseEnterYourEducationTillNow.
  ///
  /// In en, this message translates to:
  /// **'Please enter your education till now'**
  String get pleaseEnterYourEducationTillNow;

  /// No description provided for @pleaseEnterYourJobRoleWork.
  ///
  /// In en, this message translates to:
  /// **'Please enter your job role/work'**
  String get pleaseEnterYourJobRoleWork;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome Message'**
  String get welcomeMessage;

  /// No description provided for @congratulation.
  ///
  /// In en, this message translates to:
  /// **'CONGRATULATION'**
  String get congratulation;

  /// No description provided for @yourProfileHasBeenSuccessfullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been successfully completed!'**
  String get yourProfileHasBeenSuccessfullyCompleted;

  /// No description provided for @nowItsTimeToFinalizeYourBusinessListingAndShowcaseYourServicesToTheWorld.
  ///
  /// In en, this message translates to:
  /// **'Now, it\'s time to finalize your business listing and showcase your services to the world'**
  String
      get nowItsTimeToFinalizeYourBusinessListingAndShowcaseYourServicesToTheWorld;

  /// No description provided for @welcomePost.
  ///
  /// In en, this message translates to:
  /// **'Welcome Post'**
  String get welcomePost;

  /// No description provided for @forDetailVisitOurProfile.
  ///
  /// In en, this message translates to:
  /// **'For Detail Visit Our Profile'**
  String get forDetailVisitOurProfile;

  /// No description provided for @pleaseEnterSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter sub-category'**
  String get pleaseEnterSubCategory;

  /// No description provided for @pleaseEnterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Address'**
  String get pleaseEnterYourAddress;

  /// No description provided for @pleaseEnterYourCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter your City'**
  String get pleaseEnterYourCity;

  /// No description provided for @enterWebsite.
  ///
  /// In en, this message translates to:
  /// **'Enter Website'**
  String get enterWebsite;

  /// No description provided for @similarService.
  ///
  /// In en, this message translates to:
  /// **'Similar Service'**
  String get similarService;

  /// No description provided for @similarProduct.
  ///
  /// In en, this message translates to:
  /// **'Similar Product'**
  String get similarProduct;

  /// No description provided for @noSimilarProduct.
  ///
  /// In en, this message translates to:
  /// **'No Similar Product'**
  String get noSimilarProduct;

  /// No description provided for @broadcastMessages.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Messages'**
  String get broadcastMessages;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @connectionsList.
  ///
  /// In en, this message translates to:
  /// **'Connections List'**
  String get connectionsList;

  /// No description provided for @postActivity.
  ///
  /// In en, this message translates to:
  /// **'Post Activity'**
  String get postActivity;

  /// No description provided for @selectDocument.
  ///
  /// In en, this message translates to:
  /// **'Select Document'**
  String get selectDocument;

  /// No description provided for @onlyJpgPngPdfFormat.
  ///
  /// In en, this message translates to:
  /// **'Only jpg/png/pdf format'**
  String get onlyJpgPngPdfFormat;

  /// No description provided for @enterYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Question'**
  String get enterYourQuestion;

  /// No description provided for @eGMedicalShopKiranaShop.
  ///
  /// In en, this message translates to:
  /// **'Eg., medical shop, Kirana shop'**
  String get eGMedicalShopKiranaShop;

  /// No description provided for @eGDoctorElectrician.
  ///
  /// In en, this message translates to:
  /// **'Eg., Doctor, Electrician'**
  String get eGDoctorElectrician;

  /// No description provided for @eGVehicleShowroomClasses.
  ///
  /// In en, this message translates to:
  /// **'Eg., Vehicle Showroom, Classes'**
  String get eGVehicleShowroomClasses;

  /// No description provided for @switchBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Switch Business Type'**
  String get switchBusinessType;

  /// No description provided for @switchTo.
  ///
  /// In en, this message translates to:
  /// **'switch to'**
  String get switchTo;

  /// No description provided for @toBeOnTheSafeSideSelectBoth.
  ///
  /// In en, this message translates to:
  /// **'(To be on the safe side, select both.)'**
  String get toBeOnTheSafeSideSelectBoth;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'Votes'**
  String get votes;

  /// No description provided for @areYouSureYouWantToHideThisPost.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide this post?'**
  String get areYouSureYouWantToHideThisPost;

  /// No description provided for @postHidden.
  ///
  /// In en, this message translates to:
  /// **'Post Hidden'**
  String get postHidden;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @viewPost.
  ///
  /// In en, this message translates to:
  /// **'View Post'**
  String get viewPost;

  /// No description provided for @withdrawInvite.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Invite'**
  String get withdrawInvite;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @last_seen_today.
  ///
  /// In en, this message translates to:
  /// **'Last seen today at {time}'**
  String last_seen_today(Object time);

  /// No description provided for @last_seen_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Last seen yesterday at {time}'**
  String last_seen_yesterday(Object time);

  /// No description provided for @last_seen_on_day.
  ///
  /// In en, this message translates to:
  /// **'Last seen {day} at {time}'**
  String last_seen_on_day(Object day, Object time);

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @errorAccessingContacts.
  ///
  /// In en, this message translates to:
  /// **'Error accessing contacts'**
  String get errorAccessingContacts;

  /// No description provided for @contactPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission to access contacts is required'**
  String get contactPermissionRequired;

  /// No description provided for @removeFromSelection.
  ///
  /// In en, this message translates to:
  /// **'Remove from Selection'**
  String get removeFromSelection;

  /// No description provided for @addToSelection.
  ///
  /// In en, this message translates to:
  /// **'Add to Selection'**
  String get addToSelection;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @selectContacts.
  ///
  /// In en, this message translates to:
  /// **'Select Contacts'**
  String get selectContacts;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// No description provided for @contactsSelected.
  ///
  /// In en, this message translates to:
  /// **'contacts selected'**
  String get contactsSelected;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @noContactsMatchingSearch.
  ///
  /// In en, this message translates to:
  /// **'No contacts matching search'**
  String get noContactsMatchingSearch;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contact;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission to access location is required.'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it in settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @errorAccessingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error accessing location.'**
  String get errorAccessingLocation;

  /// No description provided for @newReelAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Reel Available'**
  String get newReelAvailable;

  /// No description provided for @suggestedReels.
  ///
  /// In en, this message translates to:
  /// **'Suggested Reels'**
  String get suggestedReels;

  /// No description provided for @yourStory.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get yourStory;

  /// No description provided for @searchByCategory.
  ///
  /// In en, this message translates to:
  /// **'Search By Category...'**
  String get searchByCategory;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @bookConsultant.
  ///
  /// In en, this message translates to:
  /// **'Book Consultant'**
  String get bookConsultant;

  /// No description provided for @enquireNow.
  ///
  /// In en, this message translates to:
  /// **'Enquire Now'**
  String get enquireNow;

  /// No description provided for @chatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat Now'**
  String get chatNow;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Post now'**
  String get postNow;

  /// No description provided for @postYourVideo.
  ///
  /// In en, this message translates to:
  /// **'Post your video'**
  String get postYourVideo;

  /// No description provided for @uploadYourVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Video'**
  String get uploadYourVideo;

  /// No description provided for @pickThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Pick Thumbnail'**
  String get pickThumbnail;

  /// No description provided for @writeCaption.
  ///
  /// In en, this message translates to:
  /// **'Write Caption...'**
  String get writeCaption;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get chooseCategory;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose Type'**
  String get chooseType;

  /// No description provided for @addCallToActionButton.
  ///
  /// In en, this message translates to:
  /// **'Add Call to action button'**
  String get addCallToActionButton;

  /// No description provided for @editYourVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit your video'**
  String get editYourVideo;

  /// No description provided for @editCaption.
  ///
  /// In en, this message translates to:
  /// **'Edit Caption...'**
  String get editCaption;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirmThisAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm this action?'**
  String get confirmThisAction;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete ?'**
  String get areYouSureDelete;

  /// No description provided for @appointmentBookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Appointment Booked Successfully'**
  String get appointmentBookedSuccessfully;

  /// No description provided for @appointmentBookedSuccessfullyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been booked successfully.\nWe will contact you soon!'**
  String get appointmentBookedSuccessfullyMessage;

  /// No description provided for @appointmentBookingForm.
  ///
  /// In en, this message translates to:
  /// **'Appointment Booking Form'**
  String get appointmentBookingForm;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @appointmentType.
  ///
  /// In en, this message translates to:
  /// **'Appointment Type:'**
  String get appointmentType;

  /// No description provided for @bookingFor.
  ///
  /// In en, this message translates to:
  /// **'Booking For:'**
  String get bookingFor;

  /// No description provided for @purposeOfBooking.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Booking'**
  String get purposeOfBooking;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'mm/dd/yyyy'**
  String get dateFormat;

  /// No description provided for @selectAppointmentType.
  ///
  /// In en, this message translates to:
  /// **'Select appointment type'**
  String get selectAppointmentType;

  /// No description provided for @updateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Update Appointment'**
  String get updateAppointment;

  /// No description provided for @enquiryDetails.
  ///
  /// In en, this message translates to:
  /// **'Enquiry Details'**
  String get enquiryDetails;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @modifyAppointment.
  ///
  /// In en, this message translates to:
  /// **'Modify Appointment'**
  String get modifyAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @typeYourEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Type your Enquiry like (eg: Book an appointment or know the prices...)'**
  String get typeYourEnquiry;

  /// No description provided for @yourEnquirySent.
  ///
  /// In en, this message translates to:
  /// **'Your enquiry sent'**
  String get yourEnquirySent;

  /// No description provided for @yourEnquirySentMessage.
  ///
  /// In en, this message translates to:
  /// **'Your enquiry has been sent successfully.\nWe will contact you soon!'**
  String get yourEnquirySentMessage;

  /// No description provided for @sendEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Send Enquiry'**
  String get sendEnquiry;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @enquiries.
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get enquiries;

  /// No description provided for @bookingsYouHaveSent.
  ///
  /// In en, this message translates to:
  /// **'Bookings you have sent'**
  String get bookingsYouHaveSent;

  /// No description provided for @bookingsYouHaveReceived.
  ///
  /// In en, this message translates to:
  /// **'Bookings you have Received'**
  String get bookingsYouHaveReceived;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No Bookings found'**
  String get noBookingsFound;

  /// No description provided for @enquiriesYouHaveSent.
  ///
  /// In en, this message translates to:
  /// **'Enquiries you have sent'**
  String get enquiriesYouHaveSent;

  /// No description provided for @enquiriesYouHaveReceived.
  ///
  /// In en, this message translates to:
  /// **'Enquiries you have Received'**
  String get enquiriesYouHaveReceived;

  /// No description provided for @noEnquiriesFound.
  ///
  /// In en, this message translates to:
  /// **'No enquiries found'**
  String get noEnquiriesFound;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @reportReel.
  ///
  /// In en, this message translates to:
  /// **'Report Reel'**
  String get reportReel;

  /// No description provided for @reelReported.
  ///
  /// In en, this message translates to:
  /// **'You have reported this reel'**
  String get reelReported;

  /// No description provided for @ageRestriction.
  ///
  /// In en, this message translates to:
  /// **'Age restriction (18+)'**
  String get ageRestriction;

  /// No description provided for @allowComments.
  ///
  /// In en, this message translates to:
  /// **'Allow comments'**
  String get allowComments;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @selectVisibility.
  ///
  /// In en, this message translates to:
  /// **'Select a visibility to your video'**
  String get selectVisibility;

  /// No description provided for @keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get keywords;

  /// No description provided for @addTags.
  ///
  /// In en, this message translates to:
  /// **'Add tags (separated by commas)'**
  String get addTags;

  /// No description provided for @thumbnailOptional.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail (Optional)'**
  String get thumbnailOptional;

  /// No description provided for @addYourVideo.
  ///
  /// In en, this message translates to:
  /// **'Add your video'**
  String get addYourVideo;

  /// No description provided for @recordWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Record with camera'**
  String get recordWithCamera;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get views;

  /// No description provided for @createReelProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your Reel Profile'**
  String get createReelProfile;

  /// No description provided for @uploadBusinessLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Business Logo'**
  String get uploadBusinessLogo;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// No description provided for @yourProfileName.
  ///
  /// In en, this message translates to:
  /// **'Your profile name'**
  String get yourProfileName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @addWebsiteLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Add your website link (optional)'**
  String get addWebsiteLinkOptional;

  /// No description provided for @websiteLinkHere.
  ///
  /// In en, this message translates to:
  /// **'Website link here'**
  String get websiteLinkHere;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @editReelProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Reel Profile'**
  String get editReelProfile;

  /// No description provided for @updateBusinessLogo.
  ///
  /// In en, this message translates to:
  /// **'Update your business logo'**
  String get updateBusinessLogo;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile name is required'**
  String get profileNameRequired;

  /// No description provided for @bioRequired.
  ///
  /// In en, this message translates to:
  /// **'Bio is required'**
  String get bioRequired;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequired;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @messageUs.
  ///
  /// In en, this message translates to:
  /// **'Message Us'**
  String get messageUs;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @noLatestReels.
  ///
  /// In en, this message translates to:
  /// **'No Latest Reels Present'**
  String get noLatestReels;

  /// No description provided for @noPopularReels.
  ///
  /// In en, this message translates to:
  /// **'No Popular Reels Present'**
  String get noPopularReels;

  /// No description provided for @noOldestReels.
  ///
  /// In en, this message translates to:
  /// **'No Oldest Reels Present'**
  String get noOldestReels;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noReelsPresent.
  ///
  /// In en, this message translates to:
  /// **'No Reels Present'**
  String get noReelsPresent;

  /// No description provided for @noSavedItems.
  ///
  /// In en, this message translates to:
  /// **'No Saved Items'**
  String get noSavedItems;

  /// No description provided for @noTaggedPosts.
  ///
  /// In en, this message translates to:
  /// **'No Tagged Posts'**
  String get noTaggedPosts;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @storeListing.
  ///
  /// In en, this message translates to:
  /// **'Store Listing'**
  String get storeListing;

  /// No description provided for @selectedCategory.
  ///
  /// In en, this message translates to:
  /// **'Selected category is {category}'**
  String selectedCategory(Object category);

  /// No description provided for @noStoresFound.
  ///
  /// In en, this message translates to:
  /// **'No stores found'**
  String get noStoresFound;

  /// No description provided for @matching.
  ///
  /// In en, this message translates to:
  /// **'matching \"{searchText}\"'**
  String matching(Object searchText);

  /// No description provided for @inSelectedCategory.
  ///
  /// In en, this message translates to:
  /// **'in the selected category'**
  String get inSelectedCategory;

  /// No description provided for @inThisCategory.
  ///
  /// In en, this message translates to:
  /// **'in this category'**
  String get inThisCategory;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noServicesFound;

  /// No description provided for @writeReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write Review Here...'**
  String get writeReviewHint;

  /// No description provided for @ratingsAndReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsAndReviews;

  /// No description provided for @sellerBy.
  ///
  /// In en, this message translates to:
  /// **'SELLER BY'**
  String get sellerBy;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @priceStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Price start Rs {price} /-'**
  String priceStartFrom(Object price);

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'read less'**
  String get readLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'read more'**
  String get readMore;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search anything...'**
  String get searchHint;

  /// No description provided for @userSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'User Setting'**
  String get userSettingTitle;

  /// No description provided for @recruiterTitle.
  ///
  /// In en, this message translates to:
  /// **'Recruiter'**
  String get recruiterTitle;

  /// No description provided for @myAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccountTitle;

  /// No description provided for @earnPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn & Pay'**
  String get earnPayTitle;

  /// No description provided for @reelTitle.
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get reelTitle;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changeMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Mobile Number'**
  String get changeMobileNumber;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @myJobPosts.
  ///
  /// In en, this message translates to:
  /// **'My Job Posts'**
  String get myJobPosts;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @myServices.
  ///
  /// In en, this message translates to:
  /// **'My Services'**
  String get myServices;

  /// No description provided for @myInventory.
  ///
  /// In en, this message translates to:
  /// **'My Inventory'**
  String get myInventory;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @myEnquiries.
  ///
  /// In en, this message translates to:
  /// **'My Enquiries'**
  String get myEnquiries;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @businessVerification.
  ///
  /// In en, this message translates to:
  /// **'Business Verification'**
  String get businessVerification;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @appliedJob.
  ///
  /// In en, this message translates to:
  /// **'Applied Job'**
  String get appliedJob;

  /// No description provided for @jobPost.
  ///
  /// In en, this message translates to:
  /// **'Job Post'**
  String get jobPost;

  /// No description provided for @myPlanSubscription.
  ///
  /// In en, this message translates to:
  /// **'My plan & Subscription'**
  String get myPlanSubscription;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get requestSent;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @myReels.
  ///
  /// In en, this message translates to:
  /// **'My Reels'**
  String get myReels;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @dontGetOtp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Get the OTP?'**
  String get dontGetOtp;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'BASIC'**
  String get basic;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @ownerAndBusinessVerified.
  ///
  /// In en, this message translates to:
  /// **'Owner & Business Verified'**
  String get ownerAndBusinessVerified;

  /// No description provided for @ownerVerified.
  ///
  /// In en, this message translates to:
  /// **'Owner Verified'**
  String get ownerVerified;

  /// No description provided for @businessVerified.
  ///
  /// In en, this message translates to:
  /// **'Business Verified'**
  String get businessVerified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @searchByList.
  ///
  /// In en, this message translates to:
  /// **'Search By List'**
  String get searchByList;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @getCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get Current Location'**
  String get getCurrentLocation;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @pleaseEnterSomeText.
  ///
  /// In en, this message translates to:
  /// **'Please enter some text'**
  String get pleaseEnterSomeText;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @scanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCodeTitle;

  /// No description provided for @notScannedYet.
  ///
  /// In en, this message translates to:
  /// **'Not Scanned Yet'**
  String get notScannedYet;

  /// No description provided for @placementInstructions.
  ///
  /// In en, this message translates to:
  /// **'Place QR code inside the frame to scan please avoid shake to get results quickly'**
  String get placementInstructions;

  /// No description provided for @scanningCode.
  ///
  /// In en, this message translates to:
  /// **'Scanning Code..'**
  String get scanningCode;

  /// No description provided for @scanButtonText.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanButtonText;

  /// No description provided for @scanningResult.
  ///
  /// In en, this message translates to:
  /// **'Scanning Result'**
  String get scanningResult;

  /// No description provided for @clickButtonText.
  ///
  /// In en, this message translates to:
  /// **'Click'**
  String get clickButtonText;

  /// No description provided for @cameraResumeError.
  ///
  /// In en, this message translates to:
  /// **'Camera resume error: '**
  String get cameraResumeError;

  /// No description provided for @cameraPauseError.
  ///
  /// In en, this message translates to:
  /// **'Camera pause error: '**
  String get cameraPauseError;

  /// No description provided for @accessTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Access Token not found'**
  String get accessTokenNotFound;

  /// No description provided for @hidePreview.
  ///
  /// In en, this message translates to:
  /// **'Hide Preview'**
  String get hidePreview;

  /// No description provided for @showPreview.
  ///
  /// In en, this message translates to:
  /// **'Show Preview'**
  String get showPreview;

  /// No description provided for @solidColors.
  ///
  /// In en, this message translates to:
  /// **'Solid Colors'**
  String get solidColors;

  /// No description provided for @imageWallpapers.
  ///
  /// In en, this message translates to:
  /// **'Image Wallpapers'**
  String get imageWallpapers;

  /// No description provided for @noImageWallpapers.
  ///
  /// In en, this message translates to:
  /// **'No image wallpapers added'**
  String get noImageWallpapers;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @addImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add image wallpaper'**
  String get addImageTooltip;

  /// No description provided for @deleteWallpaperTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallpaper'**
  String get deleteWallpaperTitle;

  /// No description provided for @deleteWallpaperConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wallpaper?'**
  String get deleteWallpaperConfirmation;

  /// No description provided for @errorSavingImage.
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {error}'**
  String errorSavingImage(dynamic error);

  /// No description provided for @newUsers.
  ///
  /// In en, this message translates to:
  /// **'New Users'**
  String get newUsers;

  /// No description provided for @chatWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Chat Wallpaper'**
  String get chatWallpaper;

  /// No description provided for @synchronizedContact.
  ///
  /// In en, this message translates to:
  /// **'Synchronized contact'**
  String get synchronizedContact;

  /// No description provided for @noBusinessConnections.
  ///
  /// In en, this message translates to:
  /// **'No Business Connections.'**
  String get noBusinessConnections;

  /// No description provided for @noPersonalConnections.
  ///
  /// In en, this message translates to:
  /// **'No Personal Connections.'**
  String get noPersonalConnections;

  /// No description provided for @enquiry.
  ///
  /// In en, this message translates to:
  /// **'Enquiry'**
  String get enquiry;

  /// No description provided for @request_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get request_sent;

  /// No description provided for @blocked_users.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blocked_users;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @cancel_plan.
  ///
  /// In en, this message translates to:
  /// **'Cancel Plan'**
  String get cancel_plan;

  /// No description provided for @plan_name.
  ///
  /// In en, this message translates to:
  /// **'Plan Name'**
  String get plan_name;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date;

  /// No description provided for @expire_date.
  ///
  /// In en, this message translates to:
  /// **'Expire Date'**
  String get expire_date;

  /// No description provided for @no_commitment.
  ///
  /// In en, this message translates to:
  /// **'No commitment. Cancel anytime'**
  String get no_commitment;

  /// No description provided for @go_premium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get go_premium;

  /// No description provided for @get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started;

  /// No description provided for @end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get end_date;

  /// No description provided for @enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enter_amount;

  /// No description provided for @add_note.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get add_note;

  /// No description provided for @payment_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason of the payment'**
  String get payment_reason;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @verifyYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Business'**
  String get verifyYourBusiness;

  /// No description provided for @verificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please choose how you\'d like to verify this business.'**
  String get verificationDescription;

  /// No description provided for @verificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification progress'**
  String get verificationProgress;

  /// No description provided for @actionsPending.
  ///
  /// In en, this message translates to:
  /// **'{pending} actions pending'**
  String actionsPending(Object pending);

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'{type} Verified'**
  String verifiedStatus(Object type);

  /// No description provided for @businessVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Verification'**
  String get businessVerificationTitle;

  /// No description provided for @businessVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify the business using official government\ndocuments like GST, Udyam, or Trade License.'**
  String get businessVerificationDesc;

  /// No description provided for @getTagsOnce.
  ///
  /// In en, this message translates to:
  /// **'Get Tags Once Verified'**
  String get getTagsOnce;

  /// No description provided for @businessDocumentsButton.
  ///
  /// In en, this message translates to:
  /// **'Use Business Documents'**
  String get businessDocumentsButton;

  /// No description provided for @ownershipVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Ownership Verification'**
  String get ownershipVerificationTitle;

  /// No description provided for @ownershipVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify using your government ID, selfie with ID,\nor an authorization letter.'**
  String get ownershipVerificationDesc;

  /// No description provided for @verifyOwnerButton.
  ///
  /// In en, this message translates to:
  /// **'Verify as Owner'**
  String get verifyOwnerButton;

  /// No description provided for @documentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Document Already Submitted'**
  String get documentSubmitted;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(Object message);

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted Successfully'**
  String get successTitle;

  /// No description provided for @successSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll verify your document within 24–48 hours. You\'ll be notified once it\'s done.'**
  String get successSubtitle;

  /// No description provided for @headerDescription.
  ///
  /// In en, this message translates to:
  /// **'To complete verification, we need to confirm you are the business owner or an authorized representative.'**
  String get headerDescription;

  /// No description provided for @uploadInstructions.
  ///
  /// In en, this message translates to:
  /// **'Upload any one of the following:'**
  String get uploadInstructions;

  /// No description provided for @governmentIdTitle.
  ///
  /// In en, this message translates to:
  /// **'A valid government ID'**
  String get governmentIdTitle;

  /// No description provided for @governmentIdDescription.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar, PAN, Driving License\nthat matches business records'**
  String get governmentIdDescription;

  /// No description provided for @selfieTitle.
  ///
  /// In en, this message translates to:
  /// **'A selfie with your ID'**
  String get selfieTitle;

  /// No description provided for @selfieDescription.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of you holding\nyour government ID'**
  String get selfieDescription;

  /// No description provided for @authorizationLetterTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorization letter from the owner'**
  String get authorizationLetterTitle;

  /// No description provided for @authorizationLetterDescription.
  ///
  /// In en, this message translates to:
  /// **'Include a signed letter and\nowner\'s ID copy'**
  String get authorizationLetterDescription;

  /// No description provided for @warningMessage.
  ///
  /// In en, this message translates to:
  /// **'Make sure the document clearly\nshows your name and photo.'**
  String get warningMessage;

  /// No description provided for @verifyLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Later'**
  String get verifyLaterButton;

  /// No description provided for @uploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get uploadNow;

  /// No description provided for @confirmBusinessText.
  ///
  /// In en, this message translates to:
  /// **'Help us confirm your business is real. Just upload one document — we\'ll review it quickly.'**
  String get confirmBusinessText;

  /// No description provided for @chooseDocumentTypeText.
  ///
  /// In en, this message translates to:
  /// **'Choose Document Type'**
  String get chooseDocumentTypeText;

  /// No description provided for @selectDocumentTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Document Type'**
  String get selectDocumentTypeHint;

  /// No description provided for @uploadDocumentText.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocumentText;

  /// No description provided for @documentFormatInfo.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG, or PNG (Max 5MB)'**
  String get documentFormatInfo;

  /// No description provided for @documentNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Document No'**
  String get documentNoLabel;

  /// No description provided for @documentNoHint.
  ///
  /// In en, this message translates to:
  /// **'Ex EFS34SDW'**
  String get documentNoHint;

  /// No description provided for @documentNoRequired.
  ///
  /// In en, this message translates to:
  /// **'Document number is required'**
  String get documentNoRequired;

  /// No description provided for @confirmAuthorizationText.
  ///
  /// In en, this message translates to:
  /// **'I confirm I\'m authorized to register this business.'**
  String get confirmAuthorizationText;

  /// No description provided for @submitButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitButtonText;

  /// No description provided for @documentUploadSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification document added successfully'**
  String get documentUploadSuccessMessage;

  /// No description provided for @documentUploadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification document not uploaded, something went wrong'**
  String get documentUploadErrorMessage;

  /// No description provided for @acknowledgementRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please give your acknowledgement.'**
  String get acknowledgementRequiredMessage;

  /// No description provided for @documentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please upload document.'**
  String get documentRequiredMessage;

  /// No description provided for @uploadDifferentDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload a different document'**
  String get uploadDifferentDocument;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document Uploaded'**
  String get documentUploaded;

  /// No description provided for @recruiter.
  ///
  /// In en, this message translates to:
  /// **'Recruiter'**
  String get recruiter;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'logo'**
  String get logo;

  /// No description provided for @chooseYourAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type'**
  String get chooseYourAccountType;

  /// No description provided for @uploadYourPrefix.
  ///
  /// In en, this message translates to:
  /// **'* Upload your'**
  String get uploadYourPrefix;

  /// No description provided for @imageIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Image is required'**
  String get imageIsRequired;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @businessListing.
  ///
  /// In en, this message translates to:
  /// **'Business listing'**
  String get businessListing;

  /// No description provided for @sellOrProvideServices.
  ///
  /// In en, this message translates to:
  /// **'Sell or Provide Services'**
  String get sellOrProvideServices;

  /// No description provided for @increaseCustomerPromoteAndMany.
  ///
  /// In en, this message translates to:
  /// **'Increase Customer / Promote & Many More'**
  String get increaseCustomerPromoteAndMany;

  /// No description provided for @discoverBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Discover Businesses'**
  String get discoverBusinesses;

  /// No description provided for @writeReviews.
  ///
  /// In en, this message translates to:
  /// **'Write Reviews'**
  String get writeReviews;

  /// No description provided for @getOffersUpdates.
  ///
  /// In en, this message translates to:
  /// **'Get Offers & Updates'**
  String get getOffersUpdates;

  /// No description provided for @postJobListings.
  ///
  /// In en, this message translates to:
  /// **'Post Job Listings'**
  String get postJobListings;

  /// No description provided for @hireProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Hire Professionals'**
  String get hireProfessionals;

  /// No description provided for @browseResumes.
  ///
  /// In en, this message translates to:
  /// **'Browse Resumes'**
  String get browseResumes;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @companyOrgName.
  ///
  /// In en, this message translates to:
  /// **'Company / Org Name'**
  String get companyOrgName;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameEx.
  ///
  /// In en, this message translates to:
  /// **'eg. Friends Collections Center...'**
  String get businessNameEx;

  /// No description provided for @youHaveReferCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code?'**
  String get youHaveReferCode;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Eg Vikash kumar'**
  String get nameHint;

  /// No description provided for @companyHint.
  ///
  /// In en, this message translates to:
  /// **'Eg Wipro , PW'**
  String get companyHint;

  /// No description provided for @storeHint.
  ///
  /// In en, this message translates to:
  /// **'Eg Raju Tea Store , DMart'**
  String get storeHint;

  /// No description provided for @enterNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Your {profileType} Name'**
  String enterNameMessage(Object profileType);

  /// No description provided for @currentSalary.
  ///
  /// In en, this message translates to:
  /// **'Current Salary'**
  String get currentSalary;

  /// No description provided for @expectedSalary.
  ///
  /// In en, this message translates to:
  /// **'Expected Salary'**
  String get expectedSalary;

  /// No description provided for @clickHere.
  ///
  /// In en, this message translates to:
  /// **'Click Here'**
  String get clickHere;

  /// No description provided for @setupYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setupYourProfile;

  /// No description provided for @downloadYourResume.
  ///
  /// In en, this message translates to:
  /// **'Download your Resume'**
  String get downloadYourResume;

  /// No description provided for @completeYourProfileToDownloadYourResume.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to download your resume.'**
  String get completeYourProfileToDownloadYourResume;

  /// No description provided for @uploadIntroductionVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Introduction Video'**
  String get uploadIntroductionVideo;

  /// No description provided for @deleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Delete Video'**
  String get deleteVideo;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetails;

  /// No description provided for @jobRole.
  ///
  /// In en, this message translates to:
  /// **'Job Role'**
  String get jobRole;

  /// No description provided for @keySkill.
  ///
  /// In en, this message translates to:
  /// **'Key Skill'**
  String get keySkill;

  /// No description provided for @keySkills.
  ///
  /// In en, this message translates to:
  /// **'Key Skills'**
  String get keySkills;

  /// No description provided for @atLeastOneSkillIsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one skill is required'**
  String get atLeastOneSkillIsRequired;

  /// No description provided for @skillsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Skills updated successfully!'**
  String get skillsUpdatedSuccessfully;

  /// No description provided for @addSkillsThatBestDefineYourExpertise.
  ///
  /// In en, this message translates to:
  /// **'Add skills that best define your expertise, for e.g, Direct Marketing, Java etc.'**
  String get addSkillsThatBestDefineYourExpertise;

  /// No description provided for @skillSoftwareName.
  ///
  /// In en, this message translates to:
  /// **'Skill / Software name*'**
  String get skillSoftwareName;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-Time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part Time'**
  String get partTime;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Correspondence/Distance Learning'**
  String get distance;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @courseType.
  ///
  /// In en, this message translates to:
  /// **'Course Type'**
  String get courseType;

  /// No description provided for @gradingSystem.
  ///
  /// In en, this message translates to:
  /// **'Grading System'**
  String get gradingSystem;

  /// No description provided for @selectGradingSystem.
  ///
  /// In en, this message translates to:
  /// **'Select Grading System'**
  String get selectGradingSystem;

  /// No description provided for @pleaseSelectAGradingSystem.
  ///
  /// In en, this message translates to:
  /// **'Please select a grading system'**
  String get pleaseSelectAGradingSystem;

  /// No description provided for @selectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get selectCompany;

  /// No description provided for @pleaseSelectOrganization.
  ///
  /// In en, this message translates to:
  /// **'Please select organization'**
  String get pleaseSelectOrganization;

  /// No description provided for @sendVerified.
  ///
  /// In en, this message translates to:
  /// **'Send Verified'**
  String get sendVerified;

  /// No description provided for @pleaseSelectAnOrganisationToVerified.
  ///
  /// In en, this message translates to:
  /// **'Please select an organisation to verified.'**
  String get pleaseSelectAnOrganisationToVerified;

  /// No description provided for @sendAVerificationRequestToYourCompanyToConfirmYourEmploymentOnceApprovedByTheRecruiterYouWillReceiveAVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Send a verification request to your company to confirm your employment. Once approved by the recruiter, you will receive a verified badge.'**
  String
      get sendAVerificationRequestToYourCompanyToConfirmYourEmploymentOnceApprovedByTheRecruiterYouWillReceiveAVerifiedBadge;

  /// No description provided for @isThisYourCurrentEmployment.
  ///
  /// In en, this message translates to:
  /// **'Is this your current employment?'**
  String get isThisYourCurrentEmployment;

  /// No description provided for @employmentType.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get employmentType;

  /// No description provided for @internship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get internship;

  /// No description provided for @totalExperience.
  ///
  /// In en, this message translates to:
  /// **'Total experience'**
  String get totalExperience;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @writeYourDesignation.
  ///
  /// In en, this message translates to:
  /// **'Write your designation'**
  String get writeYourDesignation;

  /// No description provided for @skillsUsed.
  ///
  /// In en, this message translates to:
  /// **'Skills Used'**
  String get skillsUsed;

  /// No description provided for @addSkills.
  ///
  /// In en, this message translates to:
  /// **'Add skills'**
  String get addSkills;

  /// No description provided for @pleaseEnterYourSkills.
  ///
  /// In en, this message translates to:
  /// **'Please enter your skills'**
  String get pleaseEnterYourSkills;

  /// No description provided for @noticePeriod.
  ///
  /// In en, this message translates to:
  /// **'Notice period'**
  String get noticePeriod;

  /// No description provided for @selectNoticePeriod.
  ///
  /// In en, this message translates to:
  /// **'Select notice period'**
  String get selectNoticePeriod;

  /// No description provided for @pleaseSelectNoticePeriod.
  ///
  /// In en, this message translates to:
  /// **'Please select notice period'**
  String get pleaseSelectNoticePeriod;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get helpTitle;

  /// No description provided for @withdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Request'**
  String get withdrawRequest;

  /// No description provided for @employmentVerificationRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Your employment verification request has been sent to your company. Once approved by the recruiter, you will receive a verified badge.'**
  String get employmentVerificationRequestMessage;

  /// No description provided for @verificationSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification request has been submitted successfully. Our team is reviewing your details. This process may take up to 24–48 hours.'**
  String get verificationSubmittedMessage;

  /// No description provided for @employmentVerificationSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Employment Verification Sent'**
  String get employmentVerificationSentTitle;

  /// No description provided for @verificationRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Request Pending'**
  String get verificationRequestPending;

  /// No description provided for @clearNotificationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to\n clear notification?'**
  String get clearNotificationConfirmation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @userProfileUpdate.
  ///
  /// In en, this message translates to:
  /// **'User Profile Update'**
  String get userProfileUpdate;

  /// No description provided for @appliedForJob.
  ///
  /// In en, this message translates to:
  /// **'Applied For Job'**
  String get appliedForJob;

  /// No description provided for @commentedOnPost.
  ///
  /// In en, this message translates to:
  /// **'Commented On Post'**
  String get commentedOnPost;

  /// No description provided for @userChat.
  ///
  /// In en, this message translates to:
  /// **'User Chat'**
  String get userChat;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter Message'**
  String get enterMessage;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @joinedAt.
  ///
  /// In en, this message translates to:
  /// **'Joined At'**
  String get joinedAt;

  /// No description provided for @aboutYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'About your business'**
  String get aboutYourBusiness;

  /// No description provided for @yourLiveStorePictures.
  ///
  /// In en, this message translates to:
  /// **'Your live store pictures'**
  String get yourLiveStorePictures;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @reopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get reopened;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @topPerformerExample.
  ///
  /// In en, this message translates to:
  /// **'Eg., Top Performer of the Month'**
  String get topPerformerExample;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get enterTitle;

  /// No description provided for @monthYearExample.
  ///
  /// In en, this message translates to:
  /// **'Eg., March 2024'**
  String get monthYearExample;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get selectDate;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here'**
  String get typeHere;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @certificateName.
  ///
  /// In en, this message translates to:
  /// **'Certificate Name'**
  String get certificateName;

  /// No description provided for @enterCertificateName.
  ///
  /// In en, this message translates to:
  /// **'Please enter certificate name'**
  String get enterCertificateName;

  /// No description provided for @certificateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate name is required'**
  String get certificateNameRequired;

  /// No description provided for @certificateId.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID'**
  String get certificateId;

  /// No description provided for @certificateIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID is required'**
  String get certificateIdRequired;

  /// No description provided for @certificateUrl.
  ///
  /// In en, this message translates to:
  /// **'Certificate URL'**
  String get certificateUrl;

  /// No description provided for @mentionCompletionUrl.
  ///
  /// In en, this message translates to:
  /// **'Please mention completion URL'**
  String get mentionCompletionUrl;

  /// No description provided for @urlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get urlRequired;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get enterValidUrl;

  /// No description provided for @certificationValidity.
  ///
  /// In en, this message translates to:
  /// **'Certification Validity'**
  String get certificationValidity;

  /// No description provided for @certificateNoExpire.
  ///
  /// In en, this message translates to:
  /// **'This certificate does not expire'**
  String get certificateNoExpire;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @atLeastOneLinkRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one link is required'**
  String get atLeastOneLinkRequired;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title required'**
  String get titleRequired;

  /// No description provided for @pasteLinkHere.
  ///
  /// In en, this message translates to:
  /// **'Paste link here'**
  String get pasteLinkHere;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @yourProfileIs100Complete.
  ///
  /// In en, this message translates to:
  /// **'Your Profile is 100% Complete'**
  String get yourProfileIs100Complete;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @visitorSentMessageRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} has sent message request to you'**
  String visitorSentMessageRequest(Object name);

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get myCard;

  /// No description provided for @recruitersVisitedYourProfileThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{dataTotalValue} Recruiters visited your profile this month! 🚀'**
  String recruitersVisitedYourProfileThisMonth(Object dataTotalValue);

  /// No description provided for @yourMonthlyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Your Monthly Performance'**
  String get yourMonthlyPerformance;

  /// No description provided for @keyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Key Metrics'**
  String get keyMetrics;

  /// No description provided for @totalProfileView.
  ///
  /// In en, this message translates to:
  /// **'Total Profile View'**
  String get totalProfileView;

  /// No description provided for @jobApplied.
  ///
  /// In en, this message translates to:
  /// **'Job Applied'**
  String get jobApplied;

  /// No description provided for @interviewScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview Scheduled'**
  String get interviewScheduled;

  /// No description provided for @shortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get shortlisted;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @somethingWentWrongPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong Please Try Again'**
  String get somethingWentWrongPleaseTryAgain;

  /// No description provided for @youGotEnquiriesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'You got {detailsTotalValue} enquiries this month!🚀'**
  String youGotEnquiriesThisMonth(Object detailsTotalValue);

  /// No description provided for @totalProduct.
  ///
  /// In en, this message translates to:
  /// **'Total Product'**
  String get totalProduct;

  /// No description provided for @jobServices.
  ///
  /// In en, this message translates to:
  /// **'Job Services'**
  String get jobServices;

  /// No description provided for @totalProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Total Profile Views'**
  String get totalProfileViews;

  /// No description provided for @totalEnquiries.
  ///
  /// In en, this message translates to:
  /// **'Total Enquiries'**
  String get totalEnquiries;

  /// No description provided for @totalOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Total Order Placed'**
  String get totalOrderPlaced;

  /// No description provided for @totalCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Completed Orders'**
  String get totalCompletedOrders;

  /// No description provided for @jobsApplied.
  ///
  /// In en, this message translates to:
  /// **'Jobs Applied'**
  String get jobsApplied;

  /// No description provided for @interviewsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interviews Scheduled'**
  String get interviewsScheduled;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalServices.
  ///
  /// In en, this message translates to:
  /// **'Total Services'**
  String get totalServices;

  /// No description provided for @enquiriesReceived.
  ///
  /// In en, this message translates to:
  /// **'Enquiries Received'**
  String get enquiriesReceived;

  /// No description provided for @ordersPlaced.
  ///
  /// In en, this message translates to:
  /// **'Orders Placed'**
  String get ordersPlaced;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get completedOrders;

  /// No description provided for @bookingsTotal.
  ///
  /// In en, this message translates to:
  /// **'Bookings(Total)'**
  String get bookingsTotal;

  /// No description provided for @expectedSalaryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Expected salary is required'**
  String get expectedSalaryIsRequired;

  /// No description provided for @currentSalaryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Current salary is required'**
  String get currentSalaryIsRequired;

  /// No description provided for @enterAValidPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive number'**
  String get enterAValidPositiveNumber;

  /// No description provided for @expectedSalaryShouldBeMoreThanCurrentSalary.
  ///
  /// In en, this message translates to:
  /// **'Expected salary should be more than current salary'**
  String get expectedSalaryShouldBeMoreThanCurrentSalary;

  /// No description provided for @pleaseFillYourBirthday.
  ///
  /// In en, this message translates to:
  /// **'Please fill your date of birth'**
  String get pleaseFillYourBirthday;

  /// No description provided for @pleaseSelectYourGender.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get pleaseSelectYourGender;

  /// No description provided for @pleaseEnterYourOrganizationName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your organization name'**
  String get pleaseEnterYourOrganizationName;

  /// No description provided for @pleaseEnterYourJobRole.
  ///
  /// In en, this message translates to:
  /// **'Please enter your job role/work'**
  String get pleaseEnterYourJobRole;

  /// No description provided for @youHaveMoreChangesToOneOrMoreFieldsInYourProfile.
  ///
  /// In en, this message translates to:
  /// **'You have made changes to one or more fields in your profile'**
  String get youHaveMoreChangesToOneOrMoreFieldsInYourProfile;

  /// No description provided for @monetizeYourInfluence.
  ///
  /// In en, this message translates to:
  /// **'Monetize your influence'**
  String get monetizeYourInfluence;

  /// No description provided for @logInSignUp.
  ///
  /// In en, this message translates to:
  /// **'Log In / Sign Up'**
  String get logInSignUp;

  /// No description provided for @requestOTP.
  ///
  /// In en, this message translates to:
  /// **'Request OTP'**
  String get requestOTP;

  /// No description provided for @howWouldYouLikeToGetTheCode.
  ///
  /// In en, this message translates to:
  /// **'How would you like to get the code?'**
  String get howWouldYouLikeToGetTheCode;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @dontGetTheOTP.
  ///
  /// In en, this message translates to:
  /// **'Don’t Get the OTP?'**
  String get dontGetTheOTP;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @createAccountAs.
  ///
  /// In en, this message translates to:
  /// **'Create Account As'**
  String get createAccountAs;

  /// No description provided for @chooseShopSellHire.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to get started, \n whether you\'re here to shop, sell, or hire.'**
  String get chooseShopSellHire;

  /// No description provided for @uploadYourBusinessLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Business Logo'**
  String get uploadYourBusinessLogo;

  /// No description provided for @personalSelfEmployee.
  ///
  /// In en, this message translates to:
  /// **'Personal / Self Employee'**
  String get personalSelfEmployee;

  /// No description provided for @forIndividualsOfferService.
  ///
  /// In en, this message translates to:
  /// **'For individuals to offer services, shop, find jobs, watch reels, and much more.'**
  String get forIndividualsOfferService;

  /// No description provided for @forBusinessToSellOnline.
  ///
  /// In en, this message translates to:
  /// **'For businesses to sell products online, connect with local customers, and grow their reach.'**
  String get forBusinessToSellOnline;

  /// No description provided for @forPostingJobOpeningsAndConnectingWithRightCandidates.
  ///
  /// In en, this message translates to:
  /// **'For posting job openings and connecting with the right candidates.'**
  String get forPostingJobOpeningsAndConnectingWithRightCandidates;

  /// No description provided for @takeOne.
  ///
  /// In en, this message translates to:
  /// **'Take from camera'**
  String get takeOne;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// No description provided for @uploadProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Picture'**
  String get uploadProfilePicture;

  /// No description provided for @uploadCompanyLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Company Logo'**
  String get uploadCompanyLogo;

  /// No description provided for @uploadYourPhotoOrLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload your Photo / Logo'**
  String get uploadYourPhotoOrLogo;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @doYouHaveAGSTNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you have a GST number?'**
  String get doYouHaveAGSTNumberTitle;

  /// No description provided for @doYouHaveAGSTNumberSubTitle.
  ///
  /// In en, this message translates to:
  /// **'If yes, your business will be instantly marked as verified.'**
  String get doYouHaveAGSTNumberSubTitle;

  /// No description provided for @yesIHave.
  ///
  /// In en, this message translates to:
  /// **'Yes, I have'**
  String get yesIHave;

  /// No description provided for @noIDont.
  ///
  /// In en, this message translates to:
  /// **'No, I don’t'**
  String get noIDont;

  /// No description provided for @enterGSTNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter GST Number'**
  String get enterGSTNumber;

  /// No description provided for @addYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Add Your Business'**
  String get addYourBusiness;

  /// No description provided for @enterSizDigitOTPVerify.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit OTP to +91 98765 43210 Please enter it below to verify your number.'**
  String get enterSizDigitOTPVerify;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetails;

  /// No description provided for @egFashionCollections.
  ///
  /// In en, this message translates to:
  /// **'Eg. Fashion Collections'**
  String get egFashionCollections;

  /// No description provided for @natureOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Nature of the Business'**
  String get natureOfTheBusiness;

  /// No description provided for @selectNatureOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select Nature of Business'**
  String get selectNatureOfBusiness;

  /// No description provided for @sizeOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Size of the Business'**
  String get sizeOfTheBusiness;

  /// No description provided for @selectTheSizeOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select the size of the business'**
  String get selectTheSizeOfTheBusiness;

  /// No description provided for @typeOfService.
  ///
  /// In en, this message translates to:
  /// **'Type of Service'**
  String get typeOfService;

  /// No description provided for @doYouHaveReferCode.
  ///
  /// In en, this message translates to:
  /// **'Do you have refer code?'**
  String get doYouHaveReferCode;

  /// No description provided for @recruiterDetails.
  ///
  /// In en, this message translates to:
  /// **'Recruiter Details'**
  String get recruiterDetails;

  /// No description provided for @yourDesignation.
  ///
  /// In en, this message translates to:
  /// **'Your Designation'**
  String get yourDesignation;

  /// No description provided for @madeInIndiaSuperApp.
  ///
  /// In en, this message translates to:
  /// **'Made in India Super App'**
  String get madeInIndiaSuperApp;

  /// No description provided for @noInterNetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInterNetConnection;

  /// No description provided for @createVisitingCard.
  ///
  /// In en, this message translates to:
  /// **'Create Visiting Card'**
  String get createVisitingCard;

  /// No description provided for @businessLogo.
  ///
  /// In en, this message translates to:
  /// **'Business Logo'**
  String get businessLogo;

  /// No description provided for @youCanUpdateYourLogoAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can update your logo anytime.'**
  String get youCanUpdateYourLogoAnytime;

  /// No description provided for @nameOfOrganization.
  ///
  /// In en, this message translates to:
  /// **'Name of Organization'**
  String get nameOfOrganization;

  /// No description provided for @businessCategory.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get businessCategory;

  /// No description provided for @rahulEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Eg., Rahul Enterprise'**
  String get rahulEnterprise;

  /// No description provided for @selectCategoryEgRetailer.
  ///
  /// In en, this message translates to:
  /// **'Select category e.g., Retailer'**
  String get selectCategoryEgRetailer;

  /// No description provided for @businessHighlights.
  ///
  /// In en, this message translates to:
  /// **'Business Highlights'**
  String get businessHighlights;

  /// No description provided for @websiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (Optional)'**
  String get websiteOptional;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your Details'**
  String get yourDetails;

  /// No description provided for @yourRoleInTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your Role in the Business'**
  String get yourRoleInTheBusiness;

  /// No description provided for @coFounderOwner.
  ///
  /// In en, this message translates to:
  /// **'Eg., Co-founder / Owner'**
  String get coFounderOwner;

  /// No description provided for @shopStore.
  ///
  /// In en, this message translates to:
  /// **'Shop/ Store'**
  String get shopStore;

  /// No description provided for @egClothesFood.
  ///
  /// In en, this message translates to:
  /// **'Eg., clothes, electronics, food'**
  String get egClothesFood;

  /// No description provided for @provideServices.
  ///
  /// In en, this message translates to:
  /// **'Provide Services'**
  String get provideServices;

  /// No description provided for @egDoctorTutor.
  ///
  /// In en, this message translates to:
  /// **'Eg., doctor, tutor'**
  String get egDoctorTutor;

  /// No description provided for @bothSaleServices.
  ///
  /// In en, this message translates to:
  /// **'Both Sale & Services'**
  String get bothSaleServices;

  /// No description provided for @egBikeShowroom.
  ///
  /// In en, this message translates to:
  /// **'Eg., bike showroom'**
  String get egBikeShowroom;

  /// No description provided for @selectBusinessCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Business Category'**
  String get selectBusinessCategory;

  /// No description provided for @egOurStore.
  ///
  /// In en, this message translates to:
  /// **'Eg., Visit our store for casual and traditional wear...'**
  String get egOurStore;

  /// No description provided for @businessDescription.
  ///
  /// In en, this message translates to:
  /// **'Business Description'**
  String get businessDescription;

  /// No description provided for @tellCustomersWhatYouOffer.
  ///
  /// In en, this message translates to:
  /// **'Tell customers what you offer.'**
  String get tellCustomersWhatYouOffer;

  /// No description provided for @yourBusinessLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Your business live location'**
  String get yourBusinessLiveLocation;

  /// No description provided for @minThreeImg.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 images'**
  String get minThreeImg;

  /// No description provided for @storeMapLocation.
  ///
  /// In en, this message translates to:
  /// **'Your store’s map location'**
  String get storeMapLocation;

  /// No description provided for @youCanUpdateYourPhotoAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can update your photo anytime.'**
  String get youCanUpdateYourPhotoAnytime;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @searchLocationThreeCharterEnter.
  ///
  /// In en, this message translates to:
  /// **'Search with 3+ characters to get your location'**
  String get searchLocationThreeCharterEnter;

  /// No description provided for @highestEducation.
  ///
  /// In en, this message translates to:
  /// **'Highest Education'**
  String get highestEducation;

  /// No description provided for @completeYourProfileAccessAccount.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Registration For Access Your Account'**
  String get completeYourProfileAccessAccount;

  /// No description provided for @startBySelectingAccountTypes.
  ///
  /// In en, this message translates to:
  /// **'Start By Selecting Account Types'**
  String get startBySelectingAccountTypes;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your mail'**
  String get verifyYourEmail;

  /// No description provided for @verificationLinkText.
  ///
  /// In en, this message translates to:
  /// **'A verification link has been sent to your email'**
  String get verificationLinkText;

  /// No description provided for @clickVerifyYourEmailLink.
  ///
  /// In en, this message translates to:
  /// **'. Click the link to verify your email.'**
  String get clickVerifyYourEmailLink;

  /// No description provided for @goToMail.
  ///
  /// In en, this message translates to:
  /// **'Go to Mail'**
  String get goToMail;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend Link'**
  String get resendLink;

  /// No description provided for @profession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profession;

  /// No description provided for @deleteConformation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conformation'**
  String get deleteConformation;

  /// No description provided for @fresherExperienceDetected.
  ///
  /// In en, this message translates to:
  /// **'Fresher Experience Detected'**
  String get fresherExperienceDetected;

  /// No description provided for @toAddWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'To add work experience, please remove your fresher experience first.'**
  String get toAddWorkExperience;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @tellUsAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell Us About You'**
  String get tellUsAboutYou;

  /// No description provided for @fresher.
  ///
  /// In en, this message translates to:
  /// **'Fresher'**
  String get fresher;

  /// No description provided for @startProfessionalWork.
  ///
  /// In en, this message translates to:
  /// **'Are you a fresher starting your career or an experienced professional?'**
  String get startProfessionalWork;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No record found'**
  String get noDataFound;

  /// No description provided for @supplyChain.
  ///
  /// In en, this message translates to:
  /// **'Supply Chain'**
  String get supplyChain;

  /// No description provided for @fullBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Business Address'**
  String get fullBusinessAddress;

  /// No description provided for @visitingCard.
  ///
  /// In en, this message translates to:
  /// **'Visiting Card'**
  String get visitingCard;

  /// No description provided for @listYourProductServices.
  ///
  /// In en, this message translates to:
  /// **'List Your Product/ Services'**
  String get listYourProductServices;

  /// No description provided for @createStoreSections.
  ///
  /// In en, this message translates to:
  /// **'Create Store Sections'**
  String get createStoreSections;

  /// No description provided for @switchBusinessTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Switch Business Type?'**
  String get switchBusinessTypeQuestion;

  /// No description provided for @confirmSwitchBusinessTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Switching business type will result in the loss of existing form data. Do you want to proceed?'**
  String get confirmSwitchBusinessTypeMessage;

  /// No description provided for @confirmSwitchBusinessTypeYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, Switch'**
  String get confirmSwitchBusinessTypeYes;

  /// No description provided for @chooseWhatYouWantToVerify.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to verify.'**
  String get chooseWhatYouWantToVerify;

  /// No description provided for @verifyYourBusinessDetailsUsingGst.
  ///
  /// In en, this message translates to:
  /// **'Verify your business details using GST or business documents.'**
  String get verifyYourBusinessDetailsUsingGst;

  /// No description provided for @confirmsYourBusinessIsRegistered.
  ///
  /// In en, this message translates to:
  /// **'Confirms your business is registered'**
  String get confirmsYourBusinessIsRegistered;

  /// No description provided for @requiredGstOrLicenseCertificate.
  ///
  /// In en, this message translates to:
  /// **'Required: GST or license/certificate'**
  String get requiredGstOrLicenseCertificate;

  /// No description provided for @ownershipVerification.
  ///
  /// In en, this message translates to:
  /// **'Ownership Verification'**
  String get ownershipVerification;

  /// No description provided for @verifyThatYouAreTheOwnerOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Verify that you are the owner of the business.'**
  String get verifyThatYouAreTheOwnerOfTheBusiness;

  /// No description provided for @confirmsYourIdentityAsTheBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Confirms your identity as the business owner'**
  String get confirmsYourIdentityAsTheBusinessOwner;

  /// No description provided for @requiredAadhaarVoterIdOrSimilar.
  ///
  /// In en, this message translates to:
  /// **'Required: Aadhaar, Voter ID, or similar'**
  String get requiredAadhaarVoterIdOrSimilar;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @chooseDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Choose Document Type'**
  String get chooseDocumentType;

  /// No description provided for @selectADocumentType.
  ///
  /// In en, this message translates to:
  /// **'Select a document type'**
  String get selectADocumentType;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @uploadOneDocumentToVerifyYourIdentityAsTheBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Upload one document to verify your identity as the business owner.'**
  String get uploadOneDocumentToVerifyYourIdentityAsTheBusinessOwner;

  /// No description provided for @theNameOnTheDocumentShouldMatchYourPanName.
  ///
  /// In en, this message translates to:
  /// **'*The name on the document should match your PAN name.'**
  String get theNameOnTheDocumentShouldMatchYourPanName;

  /// No description provided for @uploadYourDocumentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Document Photo'**
  String get uploadYourDocumentPhoto;

  /// No description provided for @nameOfTheDocument.
  ///
  /// In en, this message translates to:
  /// **'Name of the document'**
  String get nameOfTheDocument;

  /// No description provided for @pleaseSpecifyIfOther.
  ///
  /// In en, this message translates to:
  /// **'Please specify (if other)'**
  String get pleaseSpecifyIfOther;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @youCannotRepost.
  ///
  /// In en, this message translates to:
  /// **'You can\'t repost'**
  String get youCannotRepost;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @typeOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Type of Business'**
  String get typeOfBusiness;

  /// No description provided for @selectTypesOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select types of the business'**
  String get selectTypesOfTheBusiness;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Referral Code'**
  String get enterReferralCode;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @categoryOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Category of Business'**
  String get categoryOfBusiness;

  /// No description provided for @selectCategoryOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select Category of the Business'**
  String get selectCategoryOfBusiness;

  /// No description provided for @onBoarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Shop from Verified Local Businesses'**
  String get onBoarding1Title;

  /// No description provided for @onBoarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Monetize your Influence using Chat Feature'**
  String get onBoarding2Title;

  /// No description provided for @onBoarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Find Talent or Your Dream Job in Maps'**
  String get onBoarding3Title;

  /// No description provided for @onBoarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Earn via Reels and Videos'**
  String get onBoarding4Title;

  /// No description provided for @onBoarding1SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore and buy products and services from Verified Local Businesses near you.'**
  String get onBoarding1SubTitle;

  /// No description provided for @onBoarding2SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote businesses and earn from your social reach.'**
  String get onBoarding2SubTitle;

  /// No description provided for @onBoarding3SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Recruiters can post jobs. Job seekers can apply with ease.'**
  String get onBoarding3SubTitle;

  /// No description provided for @onBoarding4SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn using Reels and Videos on your own using BlueEra.'**
  String get onBoarding4SubTitle;

  /// No description provided for @accountType1Title.
  ///
  /// In en, this message translates to:
  /// **'Individual Account'**
  String get accountType1Title;

  /// No description provided for @accountType1SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Self employed, social worker, job seeker'**
  String get accountType1SubTitle;

  /// No description provided for @accountType1Description.
  ///
  /// In en, this message translates to:
  /// **'Build your presence. Connect. Get noticed!'**
  String get accountType1Description;

  /// No description provided for @accountType2Title.
  ///
  /// In en, this message translates to:
  /// **'Business Listing'**
  String get accountType2Title;

  /// No description provided for @accountType2SubTitle.
  ///
  /// In en, this message translates to:
  /// **'Store, Salon, Cafe, Hospitals, Manufacturing'**
  String get accountType2SubTitle;

  /// No description provided for @accountType2Description.
  ///
  /// In en, this message translates to:
  /// **'List your shop, office, or service and get discovered!'**
  String get accountType2Description;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'eg. Neha Singh'**
  String get yourNameHint;

  /// No description provided for @jobTitleOrDesignation.
  ///
  /// In en, this message translates to:
  /// **'Job title / Designation'**
  String get jobTitleOrDesignation;

  /// No description provided for @jobTitleOrDesignationHint.
  ///
  /// In en, this message translates to:
  /// **'Eg., UI/UX Designer'**
  String get jobTitleOrDesignationHint;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @selectGenderHint.
  ///
  /// In en, this message translates to:
  /// **'Eg., Male, Female'**
  String get selectGenderHint;

  /// No description provided for @selectYourProfession.
  ///
  /// In en, this message translates to:
  /// **'Select Your Profession'**
  String get selectYourProfession;

  /// No description provided for @selectYourProfessionHint.
  ///
  /// In en, this message translates to:
  /// **'eg., Private Job...'**
  String get selectYourProfessionHint;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designation;

  /// No description provided for @designationHint.
  ///
  /// In en, this message translates to:
  /// **'Eg., Manager, Instructor...'**
  String get designationHint;

  /// No description provided for @natureOfBusiness.
  ///
  /// In en, this message translates to:
  /// **'Nature of the Business'**
  String get natureOfBusiness;

  /// No description provided for @selectNatureOfTheBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select Nature of the Business'**
  String get selectNatureOfTheBusiness;

  /// No description provided for @didntGetOtp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the OTP?'**
  String get didntGetOtp;

  /// No description provided for @selectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select Account Type'**
  String get selectAccountType;

  /// No description provided for @selectYourEducation.
  ///
  /// In en, this message translates to:
  /// **'select your education'**
  String get selectYourEducation;

  /// No description provided for @selectYourWorkType.
  ///
  /// In en, this message translates to:
  /// **'select your work type'**
  String get selectYourWorkType;

  /// No description provided for @selectYourWorkMode.
  ///
  /// In en, this message translates to:
  /// **'select your work mode'**
  String get selectYourWorkMode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
