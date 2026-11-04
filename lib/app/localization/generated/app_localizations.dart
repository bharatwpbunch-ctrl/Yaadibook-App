import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
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
/// import 'generated/app_localizations.dart';
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
    Locale('gu'),
    Locale('hi'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Yaadibook'**
  String get appName;

  /// Tagline of Yaadibook
  ///
  /// In en, this message translates to:
  /// **'Smart Business Assistant for Service Pros'**
  String get appTagline;

  /// Bottom nav tab for Today / Dashboard
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Bottom nav tab for Customers
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// Bottom nav center action for Quick Add
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get navQuickAdd;

  /// Bottom nav tab for Reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// Bottom nav tab for More / Settings
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get actionViewAll;

  /// No description provided for @actionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get actionCall;

  /// No description provided for @actionWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get actionWhatsApp;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search customers, services...'**
  String get searchPlaceholder;

  /// No description provided for @selectDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDatePlaceholder;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get noDataFound;

  /// No description provided for @noDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your first entry.'**
  String get noDataSubtitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @confirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmDialogTitle;

  /// No description provided for @confirmDialogDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to proceed with this action?'**
  String get confirmDialogDefaultMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી (Gujarati)'**
  String get languageGujarati;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get settingsBusinessProfile;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Yaadibook'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Overview'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get dashboardWelcome;

  /// No description provided for @dashboardPendingFollowups.
  ///
  /// In en, this message translates to:
  /// **'Pending Follow-ups'**
  String get dashboardPendingFollowups;

  /// No description provided for @dashboardUpcomingServices.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Services'**
  String get dashboardUpcomingServices;

  /// No description provided for @dashboardAmcRenewals.
  ///
  /// In en, this message translates to:
  /// **'AMC Renewals'**
  String get dashboardAmcRenewals;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your customer list and history'**
  String get customersSubtitle;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service dues, AMC renewals & follow-ups'**
  String get remindersSubtitle;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAddTitle;

  /// No description provided for @quickAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a customer, new service record or reminder'**
  String get quickAddSubtitle;

  /// No description provided for @sampleCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Rameshbhai Patel'**
  String get sampleCustomerName;

  /// No description provided for @sampleCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'+91 98250 12345'**
  String get sampleCustomerPhone;

  /// No description provided for @sampleCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Near S.G. Highway, Ahmedabad'**
  String get sampleCustomerAddress;

  /// No description provided for @sampleServiceName.
  ///
  /// In en, this message translates to:
  /// **'AC Master Servicing & Gas Refill'**
  String get sampleServiceName;

  /// No description provided for @sampleReminderNote.
  ///
  /// In en, this message translates to:
  /// **'AMC 1st Service Due this week'**
  String get sampleReminderNote;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your business, the simpler way.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your customers, services and important follow-ups organised in one place.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeAlreadyHaveAccount;

  /// No description provided for @welcomeSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get welcomeSelectLanguage;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. business@gmail.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rajesh Patel'**
  String get authFullNameHint;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegister;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address and we will send you a password reset link.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authResetLinkSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authResetLinkSentTitle;

  /// No description provided for @authResetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset link to your email. Click the link in the email to set a new password.'**
  String get authResetLinkSentMessage;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Log In'**
  String get authBackToLogin;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get authDontHaveAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get authHaveAccount;

  /// No description provided for @authTermsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to Yaadibook\'s Terms & Privacy Policy.'**
  String get authTermsAgreement;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter and confirm your new password.'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authSetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get authSetNewPassword;

  /// No description provided for @authPasswordUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Updated'**
  String get authPasswordUpdatedTitle;

  /// No description provided for @authPasswordUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully. You can now log in.'**
  String get authPasswordUpdatedMessage;

  /// No description provided for @valRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get valRequired;

  /// No description provided for @valInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get valInvalidEmail;

  /// No description provided for @valPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get valPasswordMinLength;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get valPasswordMismatch;

  /// No description provided for @valInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get valInvalidPhone;

  /// No description provided for @valInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit PIN code'**
  String get valInvalidPin;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please log in.'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorEmailUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address before logging in.'**
  String get authErrorEmailUnconfirmed;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Setup'**
  String get onboardingTitle;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your service business'**
  String get onboardingStep1Subtitle;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Where is your business located?'**
  String get onboardingStep2Subtitle;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how your app should work'**
  String get onboardingStep3Subtitle;

  /// No description provided for @onboardingBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get onboardingBusinessName;

  /// No description provided for @onboardingBusinessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Patel Security Solutions'**
  String get onboardingBusinessNameHint;

  /// No description provided for @onboardingCategory.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get onboardingCategory;

  /// No description provided for @onboardingCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select your primary service'**
  String get onboardingCategoryHint;

  /// No description provided for @onboardingCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Custom Category Name'**
  String get onboardingCategoryOther;

  /// No description provided for @onboardingCategoryOtherHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Solar Panel Services'**
  String get onboardingCategoryOtherHint;

  /// No description provided for @onboardingPhone.
  ///
  /// In en, this message translates to:
  /// **'Business Phone / WhatsApp'**
  String get onboardingPhone;

  /// No description provided for @onboardingPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get onboardingPhoneHint;

  /// No description provided for @onboardingEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email (Optional)'**
  String get onboardingEmail;

  /// No description provided for @onboardingEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. contact@patelsecurity.com'**
  String get onboardingEmailHint;

  /// No description provided for @onboardingAddress1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get onboardingAddress1;

  /// No description provided for @onboardingAddress1Hint.
  ///
  /// In en, this message translates to:
  /// **'Shop/Office number, building name'**
  String get onboardingAddress1Hint;

  /// No description provided for @onboardingAddress2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 / Area (Optional)'**
  String get onboardingAddress2;

  /// No description provided for @onboardingAddress2Hint.
  ///
  /// In en, this message translates to:
  /// **'Road, landmark, area'**
  String get onboardingAddress2Hint;

  /// No description provided for @onboardingCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get onboardingCity;

  /// No description provided for @onboardingCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmedabad, Surat, Rajkot'**
  String get onboardingCityHint;

  /// No description provided for @onboardingState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get onboardingState;

  /// No description provided for @onboardingPinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get onboardingPinCode;

  /// No description provided for @onboardingPinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN code'**
  String get onboardingPinCodeHint;

  /// No description provided for @onboardingCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get onboardingCountry;

  /// No description provided for @onboardingAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get onboardingAppLanguage;

  /// No description provided for @onboardingDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get onboardingDateFormat;

  /// No description provided for @onboardingTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get onboardingTimeFormat;

  /// No description provided for @onboardingTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get onboardingTimezone;

  /// No description provided for @onboardingCreateBusiness.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get onboardingCreateBusiness;

  /// No description provided for @onboardingCreating.
  ///
  /// In en, this message translates to:
  /// **'Setting up your workspace...'**
  String get onboardingCreating;

  /// No description provided for @onboardingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Workspace ready!'**
  String get onboardingSuccess;

  /// Onboarding step progress
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @categoryCctv.
  ///
  /// In en, this message translates to:
  /// **'CCTV & Security Systems'**
  String get categoryCctv;

  /// No description provided for @categoryHvac.
  ///
  /// In en, this message translates to:
  /// **'AC & HVAC Services'**
  String get categoryHvac;

  /// No description provided for @categoryRo.
  ///
  /// In en, this message translates to:
  /// **'RO & Water Purifier'**
  String get categoryRo;

  /// No description provided for @categoryAppliance.
  ///
  /// In en, this message translates to:
  /// **'Appliance Repair'**
  String get categoryAppliance;

  /// No description provided for @categoryElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical Services'**
  String get categoryElectrical;

  /// No description provided for @categoryPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing Services'**
  String get categoryPlumbing;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Maintenance'**
  String get categoryGeneral;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other Service'**
  String get categoryOther;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
