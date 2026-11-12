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

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get authLogout;

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

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String greetingMorning(String name);

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}!'**
  String greetingAfternoon(String name);

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}!'**
  String greetingEvening(String name);

  /// No description provided for @dashboardAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is what needs your attention today.'**
  String get dashboardAttentionSubtitle;

  /// No description provided for @metricTotalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get metricTotalCustomers;

  /// No description provided for @metricPendingServices.
  ///
  /// In en, this message translates to:
  /// **'Pending Services'**
  String get metricPendingServices;

  /// No description provided for @metricMaintenanceDue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Due'**
  String get metricMaintenanceDue;

  /// No description provided for @metricAmcExpiring.
  ///
  /// In en, this message translates to:
  /// **'AMC Expiring Soon'**
  String get metricAmcExpiring;

  /// No description provided for @todayFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Focus'**
  String get todayFocusTitle;

  /// No description provided for @todayFocusEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get todayFocusEmptyTitle;

  /// No description provided for @todayFocusEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your important tasks will appear here when something needs attention.'**
  String get todayFocusEmptySubtitle;

  /// No description provided for @sourceMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get sourceMaintenance;

  /// No description provided for @sourceAmc.
  ///
  /// In en, this message translates to:
  /// **'AMC'**
  String get sourceAmc;

  /// No description provided for @sourceFollowup.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get sourceFollowup;

  /// No description provided for @sourceService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sourceService;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueOverdue;

  /// No description provided for @quickAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to add?'**
  String get quickAddSheetTitle;

  /// No description provided for @quickAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get quickAddCustomer;

  /// No description provided for @quickAddCustomerDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new customer profile'**
  String get quickAddCustomerDesc;

  /// No description provided for @quickAddService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get quickAddService;

  /// No description provided for @quickAddServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Record a completed or scheduled service'**
  String get quickAddServiceDesc;

  /// No description provided for @quickAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get quickAddReminder;

  /// No description provided for @quickAddReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder or follow-up note'**
  String get quickAddReminderDesc;

  /// No description provided for @quickAddMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Schedule Maintenance'**
  String get quickAddMaintenance;

  /// No description provided for @quickAddMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan a periodic service visit'**
  String get quickAddMaintenanceDesc;

  /// No description provided for @quickAddAmc.
  ///
  /// In en, this message translates to:
  /// **'Create AMC'**
  String get quickAddAmc;

  /// No description provided for @quickAddAmcDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up an annual maintenance contract'**
  String get quickAddAmcDesc;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in the next phase update.'**
  String get comingSoonMessage;

  /// No description provided for @customersPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Directory'**
  String get customersPlaceholderTitle;

  /// No description provided for @customersPlaceholderDesc.
  ///
  /// In en, this message translates to:
  /// **'Your customer database will live here. In the next phase, you will be able to add customers, import phone contacts, and trigger WhatsApp messages.'**
  String get customersPlaceholderDesc;

  /// No description provided for @customersAddCta.
  ///
  /// In en, this message translates to:
  /// **'Add First Customer'**
  String get customersAddCta;

  /// No description provided for @remindersFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get remindersFilterToday;

  /// No description provided for @remindersFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get remindersFilterUpcoming;

  /// No description provided for @remindersFilterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get remindersFilterOverdue;

  /// No description provided for @remindersFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get remindersFilterCompleted;

  /// No description provided for @remindersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get remindersFilterAll;

  /// No description provided for @remindersEmptyToday.
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled for today.'**
  String get remindersEmptyToday;

  /// No description provided for @remindersEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders found.'**
  String get remindersEmptyUpcoming;

  /// No description provided for @remindersEmptyOverdue.
  ///
  /// In en, this message translates to:
  /// **'No overdue tasks. Great job!'**
  String get remindersEmptyOverdue;

  /// No description provided for @remindersEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed reminders yet.'**
  String get remindersEmptyCompleted;

  /// No description provided for @remindersEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No reminders created yet.'**
  String get remindersEmptyAll;

  /// No description provided for @remindersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled follow-ups and due visits will appear here.'**
  String get remindersEmptySubtitle;

  /// No description provided for @moreCategoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business Management'**
  String get moreCategoryBusiness;

  /// No description provided for @moreBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get moreBusinessProfile;

  /// No description provided for @moreAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address & Contact Details'**
  String get moreAddressDetails;

  /// No description provided for @moreOperatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get moreOperatingHours;

  /// No description provided for @moreCategoryCommunication.
  ///
  /// In en, this message translates to:
  /// **'Customer Communication'**
  String get moreCategoryCommunication;

  /// No description provided for @moreWhatsappTemplates.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Message Templates'**
  String get moreWhatsappTemplates;

  /// No description provided for @moreFollowupIntervals.
  ///
  /// In en, this message translates to:
  /// **'Default Follow-up Intervals'**
  String get moreFollowupIntervals;

  /// No description provided for @moreCategoryTools.
  ///
  /// In en, this message translates to:
  /// **'Business Tools'**
  String get moreCategoryTools;

  /// No description provided for @moreMaintenanceIntervals.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Intervals'**
  String get moreMaintenanceIntervals;

  /// No description provided for @moreAmcTemplates.
  ///
  /// In en, this message translates to:
  /// **'AMC Templates'**
  String get moreAmcTemplates;

  /// No description provided for @moreServiceCategories.
  ///
  /// In en, this message translates to:
  /// **'Service Categories'**
  String get moreServiceCategories;

  /// No description provided for @moreCategorySettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get moreCategorySettings;

  /// No description provided for @moreThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Display Theme'**
  String get moreThemeMode;

  /// No description provided for @moreThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get moreThemeLight;

  /// No description provided for @moreNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get moreNotifications;

  /// No description provided for @moreDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get moreDataStorage;

  /// No description provided for @moreLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get moreLogoutConfirmTitle;

  /// No description provided for @moreLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your Yaadibook workspace?'**
  String get moreLogoutConfirmMessage;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date with all your reminders and alerts.'**
  String get notificationsEmptySubtitle;

  /// Total customers count banner
  ///
  /// In en, this message translates to:
  /// **'{count} customers'**
  String customersTotalCount(int count);

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or email...'**
  String get customersSearchHint;

  /// No description provided for @customersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get customersFilterAll;

  /// No description provided for @customersFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersFilterActive;

  /// No description provided for @customersFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get customersFilterArchived;

  /// No description provided for @customersSortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get customersSortRecentlyAdded;

  /// No description provided for @customersSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get customersSortNameAsc;

  /// No description provided for @customersSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z–A)'**
  String get customersSortNameDesc;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your customer list is empty.'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to keep their details and service history organised.'**
  String get customersEmptySubtitle;

  /// No description provided for @customersActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customersActionAdd;

  /// No description provided for @customersActionImport.
  ///
  /// In en, this message translates to:
  /// **'Import from Contacts'**
  String get customersActionImport;

  /// No description provided for @customerCardTagBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get customerCardTagBusiness;

  /// No description provided for @customerCardTagIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get customerCardTagIndividual;

  /// No description provided for @customerActionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get customerActionCall;

  /// No description provided for @customerActionWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get customerActionWhatsApp;

  /// No description provided for @addCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomerTitle;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomerTitle;

  /// No description provided for @customerFullName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name *'**
  String get customerFullName;

  /// No description provided for @customerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Patel'**
  String get customerFullNameHint;

  /// No description provided for @customerPrimaryPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number *'**
  String get customerPrimaryPhone;

  /// No description provided for @customerPrimaryPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get customerPrimaryPhoneHint;

  /// No description provided for @customerAlternatePhone.
  ///
  /// In en, this message translates to:
  /// **'Alternate Mobile (Optional)'**
  String get customerAlternatePhone;

  /// No description provided for @customerAlternatePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 98250 99887'**
  String get customerAlternatePhoneHint;

  /// No description provided for @customerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address (Optional)'**
  String get customerEmail;

  /// No description provided for @customerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ramesh@gmail.com'**
  String get customerEmailHint;

  /// No description provided for @customerType.
  ///
  /// In en, this message translates to:
  /// **'Customer Type'**
  String get customerType;

  /// No description provided for @customerTypeIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get customerTypeIndividual;

  /// No description provided for @customerTypeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get customerTypeBusiness;

  /// No description provided for @customerAddressHeader.
  ///
  /// In en, this message translates to:
  /// **'Address Details (Optional)'**
  String get customerAddressHeader;

  /// No description provided for @customerAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get customerAddressLine1;

  /// No description provided for @customerAddressLine1Hint.
  ///
  /// In en, this message translates to:
  /// **'Shop/Flat no, building name'**
  String get customerAddressLine1Hint;

  /// No description provided for @customerAddressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get customerAddressLine2;

  /// No description provided for @customerAddressLine2Hint.
  ///
  /// In en, this message translates to:
  /// **'Street, landmark'**
  String get customerAddressLine2Hint;

  /// No description provided for @customerArea.
  ///
  /// In en, this message translates to:
  /// **'Area / Locality'**
  String get customerArea;

  /// No description provided for @customerAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Satellite, Navrangpura'**
  String get customerAreaHint;

  /// No description provided for @customerCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get customerCity;

  /// No description provided for @customerCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmedabad, Surat'**
  String get customerCityHint;

  /// No description provided for @customerState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get customerState;

  /// No description provided for @customerPinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get customerPinCode;

  /// No description provided for @customerPinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN code'**
  String get customerPinCodeHint;

  /// No description provided for @customerNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get customerNotes;

  /// No description provided for @customerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Special notes, customer preferences...'**
  String get customerNotesHint;

  /// No description provided for @customerSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer saved successfully!'**
  String get customerSaveSuccess;

  /// No description provided for @customerUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully!'**
  String get customerUpdateSuccess;

  /// No description provided for @customerDuplicateWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Already Exists'**
  String get customerDuplicateWarningTitle;

  /// Warning message when duplicate phone is entered
  ///
  /// In en, this message translates to:
  /// **'A customer with number {phone} already exists ({name}). Would you like to view their profile instead?'**
  String customerDuplicateWarningMessage(String phone, String name);

  /// No description provided for @customerViewExisting.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get customerViewExisting;

  /// No description provided for @customerSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get customerSaveAnyway;

  /// No description provided for @customerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile'**
  String get customerDetailTitle;

  /// No description provided for @customerOverviewHeader.
  ///
  /// In en, this message translates to:
  /// **'Service & Maintenance Overview'**
  String get customerOverviewHeader;

  /// No description provided for @customerOverviewTotalServices.
  ///
  /// In en, this message translates to:
  /// **'Total Services'**
  String get customerOverviewTotalServices;

  /// No description provided for @customerOverviewPendingServices.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customerOverviewPendingServices;

  /// No description provided for @customerOverviewCompletedServices.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get customerOverviewCompletedServices;

  /// No description provided for @customerOverviewReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get customerOverviewReminders;

  /// No description provided for @customerOverviewComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Service records & reminders will connect here in upcoming phases.'**
  String get customerOverviewComingSoon;

  /// No description provided for @customerActivityHeader.
  ///
  /// In en, this message translates to:
  /// **'Activity Timeline'**
  String get customerActivityHeader;

  /// No description provided for @customerActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent activity recorded yet.'**
  String get customerActivityEmpty;

  /// No description provided for @customerNotesHeader.
  ///
  /// In en, this message translates to:
  /// **'Customer Notes'**
  String get customerNotesHeader;

  /// No description provided for @customerNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes added for this customer.'**
  String get customerNotesEmpty;

  /// No description provided for @customerArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Customer?'**
  String get customerArchiveConfirmTitle;

  /// No description provided for @customerArchiveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This customer will be hidden from the active customer list. All past services and history will remain safely preserved.'**
  String get customerArchiveConfirmMessage;

  /// No description provided for @customerActionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive Customer'**
  String get customerActionArchive;

  /// No description provided for @customerActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Customer'**
  String get customerActionRestore;

  /// No description provided for @customerRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer restored to active list.'**
  String get customerRestoredSuccess;

  /// No description provided for @customerArchivedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer archived.'**
  String get customerArchivedSuccess;

  /// No description provided for @contactImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Contacts'**
  String get contactImportTitle;

  /// No description provided for @contactPermissionRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Your Phone Contacts'**
  String get contactPermissionRationaleTitle;

  /// No description provided for @contactPermissionRationaleMessage.
  ///
  /// In en, this message translates to:
  /// **'Yaadibook can help you quickly import customer details from your phone\'s address book. We only import the contacts you specifically choose.'**
  String get contactPermissionRationaleMessage;

  /// No description provided for @contactPermissionGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow Contacts Access'**
  String get contactPermissionGrant;

  /// No description provided for @contactPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is needed to import customer numbers. Please enable access in settings.'**
  String get contactPermissionDeniedMessage;

  /// No description provided for @contactOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get contactOpenSettings;

  /// Selected contacts counter
  ///
  /// In en, this message translates to:
  /// **'{count} contacts selected'**
  String contactSelectCount(int count);

  /// No description provided for @contactActionImportSelected.
  ///
  /// In en, this message translates to:
  /// **'Import Selected'**
  String get contactActionImportSelected;

  /// No description provided for @contactSelectPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Mobile Number'**
  String get contactSelectPhoneTitle;

  /// No description provided for @contactSelectPhoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This contact has multiple phone numbers. Please select the primary number to use:'**
  String get contactSelectPhoneMessage;

  /// Default prefilled greeting message for WhatsApp
  ///
  /// In en, this message translates to:
  /// **'Hello {customerName}, greetings from {businessName}.'**
  String commWhatsAppGreeting(String customerName, String businessName);

  /// No description provided for @commDialerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone dialer on this device.'**
  String get commDialerError;

  /// No description provided for @commWhatsAppError.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp could not be opened. Please ensure WhatsApp is installed.'**
  String get commWhatsAppError;

  /// No description provided for @servicesOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesOverviewTitle;

  /// No description provided for @servicesListTitle.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get servicesListTitle;

  /// No description provided for @addServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addServiceTitle;

  /// No description provided for @editServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editServiceTitle;

  /// No description provided for @serviceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetailTitle;

  /// No description provided for @serviceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Service History'**
  String get serviceHistoryTitle;

  /// No description provided for @serviceQuickAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get serviceQuickAddAction;

  /// No description provided for @serviceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get serviceStatusPending;

  /// No description provided for @serviceStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get serviceStatusInProgress;

  /// No description provided for @serviceStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceStatusCompleted;

  /// No description provided for @serviceStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get serviceStatusCancelled;

  /// No description provided for @serviceTypeInstallation.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get serviceTypeInstallation;

  /// No description provided for @serviceTypeRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get serviceTypeRepair;

  /// No description provided for @serviceTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get serviceTypeMaintenance;

  /// No description provided for @serviceTypeInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get serviceTypeInspection;

  /// No description provided for @serviceTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Service'**
  String get serviceTypeGeneral;

  /// No description provided for @serviceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get serviceTypeOther;

  /// No description provided for @serviceCustomerSection.
  ///
  /// In en, this message translates to:
  /// **'Customer *'**
  String get serviceCustomerSection;

  /// No description provided for @serviceSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get serviceSelectCustomer;

  /// No description provided for @serviceSelectCustomerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing customer for this service'**
  String get serviceSelectCustomerPrompt;

  /// No description provided for @serviceInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Service Information'**
  String get serviceInfoSection;

  /// No description provided for @serviceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Title *'**
  String get serviceTitleLabel;

  /// No description provided for @serviceTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CCTV Camera Installation, AC Repair'**
  String get serviceTitleHint;

  /// No description provided for @serviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Type *'**
  String get serviceTypeLabel;

  /// No description provided for @serviceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Date *'**
  String get serviceDateLabel;

  /// No description provided for @serviceEquipmentSection.
  ///
  /// In en, this message translates to:
  /// **'Customer Equipment (Optional)'**
  String get serviceEquipmentSection;

  /// No description provided for @serviceSelectEquipment.
  ///
  /// In en, this message translates to:
  /// **'Select linked equipment'**
  String get serviceSelectEquipment;

  /// No description provided for @serviceNoEquipmentRegistered.
  ///
  /// In en, this message translates to:
  /// **'No equipment registered for this customer yet.'**
  String get serviceNoEquipmentRegistered;

  /// No description provided for @serviceWorkDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Work Details'**
  String get serviceWorkDetailsSection;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Description (Optional)'**
  String get serviceDescriptionLabel;

  /// No description provided for @serviceDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe customer request or issue...'**
  String get serviceDescriptionHint;

  /// No description provided for @serviceWorkPerformedLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Performed (Optional)'**
  String get serviceWorkPerformedLabel;

  /// No description provided for @serviceWorkPerformedHint.
  ///
  /// In en, this message translates to:
  /// **'What was installed, repaired, or replaced...'**
  String get serviceWorkPerformedHint;

  /// No description provided for @serviceChargesSection.
  ///
  /// In en, this message translates to:
  /// **'Charges (INR)'**
  String get serviceChargesSection;

  /// No description provided for @serviceChargeBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Charge (₹)'**
  String get serviceChargeBaseLabel;

  /// No description provided for @serviceChargeBaseHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get serviceChargeBaseHint;

  /// No description provided for @serviceAdditionalChargesLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Charges (₹)'**
  String get serviceAdditionalChargesLabel;

  /// No description provided for @serviceDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount (₹)'**
  String get serviceDiscountLabel;

  /// No description provided for @serviceTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get serviceTotalAmountLabel;

  /// No description provided for @serviceAttachmentsSection.
  ///
  /// In en, this message translates to:
  /// **'Service Photos & Documents'**
  String get serviceAttachmentsSection;

  /// No description provided for @serviceAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo / Doc'**
  String get serviceAddPhoto;

  /// No description provided for @serviceTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get serviceTakePhoto;

  /// No description provided for @serviceChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get serviceChooseGallery;

  /// No description provided for @serviceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No service records yet.'**
  String get serviceEmptyTitle;

  /// No description provided for @serviceEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your first installation, repair or service visit to keep everything organised.'**
  String get serviceEmptySubtitle;

  /// No description provided for @serviceRecentHeader.
  ///
  /// In en, this message translates to:
  /// **'Recent Services'**
  String get serviceRecentHeader;

  /// No description provided for @servicePendingHeader.
  ///
  /// In en, this message translates to:
  /// **'Pending Services'**
  String get servicePendingHeader;

  /// Total service count
  ///
  /// In en, this message translates to:
  /// **'{count} services'**
  String serviceTotalCount(int count);

  /// No description provided for @serviceSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service entry created successfully!'**
  String get serviceSaveSuccess;

  /// No description provided for @serviceUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service entry updated successfully!'**
  String get serviceUpdateSuccess;

  /// Toast when service status changes
  ///
  /// In en, this message translates to:
  /// **'Service status updated to {status}.'**
  String serviceStatusUpdateSuccess(String status);

  /// No description provided for @serviceMarkCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark Service as Completed'**
  String get serviceMarkCompletedTitle;

  /// No description provided for @serviceMarkCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm that work has been finished for this service?'**
  String get serviceMarkCompletedMessage;

  /// No description provided for @serviceCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Service?'**
  String get serviceCancelTitle;

  /// No description provided for @serviceCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this service entry? Past records will be safely preserved.'**
  String get serviceCancelMessage;

  /// No description provided for @serviceResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Service'**
  String get serviceResumeTitle;

  /// No description provided for @serviceResumeMessage.
  ///
  /// In en, this message translates to:
  /// **'Reopen this cancelled service back to in-progress status?'**
  String get serviceResumeMessage;

  /// No description provided for @serviceActionUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get serviceActionUpdateStatus;

  /// No description provided for @serviceActionMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get serviceActionMarkCompleted;

  /// No description provided for @serviceActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Service'**
  String get serviceActionCancel;

  /// No description provided for @serviceActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Service'**
  String get serviceActionResume;

  /// No description provided for @serviceReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ref #'**
  String get serviceReferenceLabel;

  /// No description provided for @serviceActivityHeader.
  ///
  /// In en, this message translates to:
  /// **'Service Activity Timeline'**
  String get serviceActivityHeader;

  /// No description provided for @serviceFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get serviceFilterAll;

  /// No description provided for @serviceFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get serviceFilterPending;

  /// No description provided for @serviceFilterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get serviceFilterInProgress;

  /// No description provided for @serviceFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceFilterCompleted;

  /// No description provided for @serviceFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get serviceFilterCancelled;

  /// No description provided for @serviceSortRecentlyCreated.
  ///
  /// In en, this message translates to:
  /// **'Recently Created'**
  String get serviceSortRecentlyCreated;

  /// No description provided for @serviceSortNewestDate.
  ///
  /// In en, this message translates to:
  /// **'Newest Service Date'**
  String get serviceSortNewestDate;

  /// No description provided for @serviceSortOldestDate.
  ///
  /// In en, this message translates to:
  /// **'Oldest Service Date'**
  String get serviceSortOldestDate;

  /// No description provided for @serviceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by customer, title, or ref...'**
  String get serviceSearchHint;

  /// No description provided for @serviceViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All Services'**
  String get serviceViewAll;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Overview'**
  String get maintenanceOverview;

  /// No description provided for @maintenancePlans.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Plans'**
  String get maintenancePlans;

  /// No description provided for @maintenanceScheduleVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule Maintenance'**
  String get maintenanceScheduleVisit;

  /// No description provided for @maintenanceAddPlan.
  ///
  /// In en, this message translates to:
  /// **'New Maintenance Plan'**
  String get maintenanceAddPlan;

  /// No description provided for @maintenanceEditPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Maintenance Plan'**
  String get maintenanceEditPlan;

  /// No description provided for @maintenancePlanDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get maintenancePlanDetails;

  /// No description provided for @maintenanceOccurrenceDetails.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Visit'**
  String get maintenanceOccurrenceDetails;

  /// No description provided for @maintenanceDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get maintenanceDueToday;

  /// No description provided for @maintenanceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get maintenanceOverdue;

  /// No description provided for @maintenanceUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get maintenanceUpcoming;

  /// No description provided for @maintenanceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintenanceCompleted;

  /// No description provided for @maintenanceSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get maintenanceSkipped;

  /// No description provided for @maintenanceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get maintenanceCancelled;

  /// No description provided for @maintenanceActivePlans.
  ///
  /// In en, this message translates to:
  /// **'Active Plans'**
  String get maintenanceActivePlans;

  /// No description provided for @maintenancePausedPlans.
  ///
  /// In en, this message translates to:
  /// **'Paused Plans'**
  String get maintenancePausedPlans;

  /// No description provided for @maintenanceTabDue.
  ///
  /// In en, this message translates to:
  /// **'Due & Overdue'**
  String get maintenanceTabDue;

  /// No description provided for @maintenanceTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get maintenanceTabUpcoming;

  /// No description provided for @maintenanceTabHistory.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintenanceTabHistory;

  /// No description provided for @maintenanceTabPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get maintenanceTabPlans;

  /// No description provided for @maintenanceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Type'**
  String get maintenanceTypeLabel;

  /// No description provided for @maintenanceTypeRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get maintenanceTypeRoutine;

  /// No description provided for @maintenanceTypePeriodic.
  ///
  /// In en, this message translates to:
  /// **'Periodic'**
  String get maintenanceTypePeriodic;

  /// No description provided for @maintenanceTypeSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get maintenanceTypeSeasonal;

  /// No description provided for @maintenanceTypeInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get maintenanceTypeInspection;

  /// No description provided for @maintenanceFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get maintenanceFrequencyLabel;

  /// No description provided for @maintenanceFrequencyOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get maintenanceFrequencyOneTime;

  /// No description provided for @maintenanceFrequencyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get maintenanceFrequencyRecurring;

  /// No description provided for @maintenanceIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat Every'**
  String get maintenanceIntervalLabel;

  /// No description provided for @maintenanceIntervalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get maintenanceIntervalMonthly;

  /// No description provided for @maintenanceIntervalQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get maintenanceIntervalQuarterly;

  /// No description provided for @maintenanceIntervalHalfYearly.
  ///
  /// In en, this message translates to:
  /// **'Half-Yearly'**
  String get maintenanceIntervalHalfYearly;

  /// No description provided for @maintenanceIntervalYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get maintenanceIntervalYearly;

  /// No description provided for @maintenanceIntervalCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Interval'**
  String get maintenanceIntervalCustom;

  /// No description provided for @maintenanceIntervalUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get maintenanceIntervalUnitDays;

  /// No description provided for @maintenanceIntervalUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get maintenanceIntervalUnitWeeks;

  /// No description provided for @maintenanceIntervalUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get maintenanceIntervalUnitMonths;

  /// No description provided for @maintenanceIntervalUnitYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get maintenanceIntervalUnitYears;

  /// No description provided for @maintenanceStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'First Due Date'**
  String get maintenanceStartDateLabel;

  /// No description provided for @maintenanceEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get maintenanceEndDateLabel;

  /// No description provided for @maintenanceEndDateHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for indefinitely recurring'**
  String get maintenanceEndDateHint;

  /// No description provided for @maintenanceReminderDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind Days Before'**
  String get maintenanceReminderDaysLabel;

  /// No description provided for @maintenanceNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes & Checklist (Optional)'**
  String get maintenanceNotesLabel;

  /// No description provided for @maintenanceNotesHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Clean filters, inspect wiring, check refrigerant pressure...'**
  String get maintenanceNotesHint;

  /// No description provided for @maintenanceActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get maintenanceActionComplete;

  /// No description provided for @maintenanceActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip Visit'**
  String get maintenanceActionSkip;

  /// No description provided for @maintenanceActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get maintenanceActionReschedule;

  /// No description provided for @maintenanceActionPausePlan.
  ///
  /// In en, this message translates to:
  /// **'Pause Plan'**
  String get maintenanceActionPausePlan;

  /// No description provided for @maintenanceActionResumePlan.
  ///
  /// In en, this message translates to:
  /// **'Resume Plan'**
  String get maintenanceActionResumePlan;

  /// No description provided for @maintenanceActionCancelPlan.
  ///
  /// In en, this message translates to:
  /// **'Cancel Plan'**
  String get maintenanceActionCancelPlan;

  /// No description provided for @maintenanceCompleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Maintenance Visit'**
  String get maintenanceCompleteDialogTitle;

  /// No description provided for @maintenanceCompleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Record visit completion details for this customer.'**
  String get maintenanceCompleteDialogMessage;

  /// No description provided for @maintenanceWorkPerformedLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Done (Optional)'**
  String get maintenanceWorkPerformedLabel;

  /// No description provided for @maintenanceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Charged (₹)'**
  String get maintenanceAmountLabel;

  /// No description provided for @maintenanceSkipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip Maintenance Visit'**
  String get maintenanceSkipDialogTitle;

  /// No description provided for @maintenanceSkipDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to skip this visit? If this is recurring, the next visit will be scheduled automatically.'**
  String get maintenanceSkipDialogMessage;

  /// No description provided for @maintenanceSkipReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Skipping (Optional)'**
  String get maintenanceSkipReasonLabel;

  /// No description provided for @maintenanceSkipReasonHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Customer unavailable, postponed by client...'**
  String get maintenanceSkipReasonHint;

  /// No description provided for @maintenanceRescheduleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Visit'**
  String get maintenanceRescheduleDialogTitle;

  /// No description provided for @maintenanceRescheduleNewDate.
  ///
  /// In en, this message translates to:
  /// **'Select New Due Date'**
  String get maintenanceRescheduleNewDate;

  /// No description provided for @maintenanceCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan created successfully!'**
  String get maintenanceCreateSuccess;

  /// No description provided for @maintenanceUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan updated successfully!'**
  String get maintenanceUpdateSuccess;

  /// No description provided for @maintenanceVisitCompleted.
  ///
  /// In en, this message translates to:
  /// **'Maintenance visit marked as completed!'**
  String get maintenanceVisitCompleted;

  /// No description provided for @maintenanceVisitSkipped.
  ///
  /// In en, this message translates to:
  /// **'Maintenance visit skipped.'**
  String get maintenanceVisitSkipped;

  /// Toast when maintenance visit is rescheduled
  ///
  /// In en, this message translates to:
  /// **'Maintenance visit rescheduled to {date}.'**
  String maintenanceVisitRescheduled(String date);

  /// No description provided for @maintenanceEmptyOccurrences.
  ///
  /// In en, this message translates to:
  /// **'No scheduled maintenance visits found.'**
  String get maintenanceEmptyOccurrences;

  /// No description provided for @maintenanceEmptyPlans.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plans found. Create your first plan to keep track of customer checkups!'**
  String get maintenanceEmptyPlans;

  /// No description provided for @maintenanceScheduleFutureShortcut.
  ///
  /// In en, this message translates to:
  /// **'Schedule Maintenance'**
  String get maintenanceScheduleFutureShortcut;

  /// No description provided for @amcTitle.
  ///
  /// In en, this message translates to:
  /// **'AMC Contracts'**
  String get amcTitle;

  /// No description provided for @amcOverview.
  ///
  /// In en, this message translates to:
  /// **'AMC Management'**
  String get amcOverview;

  /// No description provided for @amcContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get amcContracts;

  /// No description provided for @amcCreateContract.
  ///
  /// In en, this message translates to:
  /// **'New AMC Contract'**
  String get amcCreateContract;

  /// No description provided for @amcEditContract.
  ///
  /// In en, this message translates to:
  /// **'Edit AMC Contract'**
  String get amcEditContract;

  /// No description provided for @amcContractDetails.
  ///
  /// In en, this message translates to:
  /// **'AMC Contract Details'**
  String get amcContractDetails;

  /// No description provided for @amcRenewContract.
  ///
  /// In en, this message translates to:
  /// **'Renew AMC Contract'**
  String get amcRenewContract;

  /// No description provided for @amcTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get amcTabActive;

  /// No description provided for @amcTabExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get amcTabExpiring;

  /// No description provided for @amcTabExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get amcTabExpired;

  /// No description provided for @amcTabAll.
  ///
  /// In en, this message translates to:
  /// **'All Contracts'**
  String get amcTabAll;

  /// No description provided for @amcActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active Contracts'**
  String get amcActiveCount;

  /// No description provided for @amcExpiringCount.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon (30d)'**
  String get amcExpiringCount;

  /// No description provided for @amcExpiredCount.
  ///
  /// In en, this message translates to:
  /// **'Expired Contracts'**
  String get amcExpiredCount;

  /// No description provided for @amcRenewedCount.
  ///
  /// In en, this message translates to:
  /// **'Renewed'**
  String get amcRenewedCount;

  /// No description provided for @amcContractTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Title / Service Name'**
  String get amcContractTitleLabel;

  /// No description provided for @amcContractTitleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Full Year AC Comprehensive AMC, RO Purifier Plan'**
  String get amcContractTitleHint;

  /// No description provided for @amcContractNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract #'**
  String get amcContractNumberLabel;

  /// No description provided for @amcStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Start Date'**
  String get amcStartDateLabel;

  /// No description provided for @amcEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract End Date'**
  String get amcEndDateLabel;

  /// No description provided for @amcContractAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Value (₹)'**
  String get amcContractAmountLabel;

  /// No description provided for @amcNumberOfVisitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Included Visits'**
  String get amcNumberOfVisitsLabel;

  /// No description provided for @amcNumberOfVisitsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. 4 visits per year'**
  String get amcNumberOfVisitsHint;

  /// No description provided for @amcIncludedServicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Included Services & Parts (Optional)'**
  String get amcIncludedServicesLabel;

  /// No description provided for @amcIncludedServicesHint.
  ///
  /// In en, this message translates to:
  /// **'What is covered under this AMC...'**
  String get amcIncludedServicesHint;

  /// No description provided for @amcExcludedServicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Excluded Services & Charges (Optional)'**
  String get amcExcludedServicesLabel;

  /// No description provided for @amcExcludedServicesHint.
  ///
  /// In en, this message translates to:
  /// **'What is NOT covered under this AMC...'**
  String get amcExcludedServicesHint;

  /// No description provided for @amcSpecialTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms & Warranty Conditions (Optional)'**
  String get amcSpecialTermsLabel;

  /// No description provided for @amcRenewalTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Renewal Terms (Optional)'**
  String get amcRenewalTermsLabel;

  /// No description provided for @amcNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes (Optional)'**
  String get amcNotesLabel;

  /// No description provided for @amcActionRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew Contract'**
  String get amcActionRenew;

  /// No description provided for @amcActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Contract'**
  String get amcActionCancel;

  /// No description provided for @amcRenewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew AMC Contract'**
  String get amcRenewDialogTitle;

  /// No description provided for @amcRenewDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create a new renewal contract linked to the previous contract, preserving full history.'**
  String get amcRenewDialogMessage;

  /// No description provided for @amcCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'AMC contract created successfully!'**
  String get amcCreateSuccess;

  /// No description provided for @amcUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'AMC contract updated successfully!'**
  String get amcUpdateSuccess;

  /// No description provided for @amcRenewSuccess.
  ///
  /// In en, this message translates to:
  /// **'AMC contract renewed successfully!'**
  String get amcRenewSuccess;

  /// No description provided for @amcCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel AMC Contract?'**
  String get amcCancelConfirmTitle;

  /// No description provided for @amcCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this AMC contract? Historical records will remain intact.'**
  String get amcCancelConfirmMessage;

  /// No description provided for @amcEmptyContracts.
  ///
  /// In en, this message translates to:
  /// **'No AMC contracts found. Create an AMC to track customer service warranties and annual recurring revenues!'**
  String get amcEmptyContracts;

  /// Days remaining until AMC expires
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String amcDaysRemaining(int days);

  /// Days since AMC expired
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String amcExpiredAgo(int days);

  /// No description provided for @amcExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today!'**
  String get amcExpiresToday;

  /// No description provided for @amcCreateShortcut.
  ///
  /// In en, this message translates to:
  /// **'Create AMC Contract'**
  String get amcCreateShortcut;

  /// No description provided for @remindersOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersOverviewTitle;

  /// No description provided for @remindersDueTodayCount.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get remindersDueTodayCount;

  /// No description provided for @remindersOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get remindersOverdueCount;

  /// No description provided for @remindersUpcomingCount.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get remindersUpcomingCount;

  /// No description provided for @remindersCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get remindersCompletedCount;

  /// No description provided for @remindersSourceAll.
  ///
  /// In en, this message translates to:
  /// **'All Sources'**
  String get remindersSourceAll;

  /// No description provided for @remindersSourceMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get remindersSourceMaintenance;

  /// No description provided for @remindersSourceAmc.
  ///
  /// In en, this message translates to:
  /// **'AMC'**
  String get remindersSourceAmc;

  /// No description provided for @remindersSourceFollowup.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get remindersSourceFollowup;

  /// No description provided for @remindersSourceGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Tasks'**
  String get remindersSourceGeneral;

  /// No description provided for @remindersCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get remindersCreateTitle;

  /// No description provided for @remindersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get remindersEditTitle;

  /// No description provided for @remindersDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get remindersDetailTitle;

  /// No description provided for @remindersTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get remindersTitleLabel;

  /// No description provided for @remindersTitleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Call Rahul about quotation, collect payment'**
  String get remindersTitleHint;

  /// No description provided for @remindersDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description / Notes (Optional)'**
  String get remindersDescriptionLabel;

  /// No description provided for @remindersDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details or instructions...'**
  String get remindersDescriptionHint;

  /// No description provided for @remindersDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get remindersDateLabel;

  /// No description provided for @remindersTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Time (Default 9:00 AM)'**
  String get remindersTimeLabel;

  /// No description provided for @remindersCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer (Optional)'**
  String get remindersCustomerLabel;

  /// No description provided for @remindersCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get remindersCategoryLabel;

  /// No description provided for @remindersPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get remindersPriorityLabel;

  /// No description provided for @remindersPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get remindersPriorityLow;

  /// No description provided for @remindersPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get remindersPriorityNormal;

  /// No description provided for @remindersPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get remindersPriorityHigh;

  /// No description provided for @remindersPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get remindersPriorityUrgent;

  /// No description provided for @remindersCategoryFollowup.
  ///
  /// In en, this message translates to:
  /// **'Customer Follow-up'**
  String get remindersCategoryFollowup;

  /// No description provided for @remindersCategoryCall.
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get remindersCategoryCall;

  /// No description provided for @remindersCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Follow-up'**
  String get remindersCategoryPayment;

  /// No description provided for @remindersCategoryVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit Customer'**
  String get remindersCategoryVisit;

  /// No description provided for @remindersCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Task'**
  String get remindersCategoryGeneral;

  /// No description provided for @remindersCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get remindersCategoryOther;

  /// No description provided for @remindersActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get remindersActionSnooze;

  /// No description provided for @remindersActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get remindersActionComplete;

  /// No description provided for @remindersActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get remindersActionReschedule;

  /// No description provided for @remindersActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Task'**
  String get remindersActionCancel;

  /// No description provided for @remindersSnoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze Reminder'**
  String get remindersSnoozeTitle;

  /// No description provided for @remindersSnoozeLaterToday.
  ///
  /// In en, this message translates to:
  /// **'Later Today (+3 hrs)'**
  String get remindersSnoozeLaterToday;

  /// No description provided for @remindersSnoozeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow (9:00 AM)'**
  String get remindersSnoozeTomorrow;

  /// No description provided for @remindersSnoozeIn3Days.
  ///
  /// In en, this message translates to:
  /// **'In 3 Days'**
  String get remindersSnoozeIn3Days;

  /// No description provided for @remindersSnoozeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get remindersSnoozeNextWeek;

  /// No description provided for @remindersSnoozeCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose Date & Time'**
  String get remindersSnoozeCustom;

  /// No description provided for @remindersCompleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get remindersCompleteDialogTitle;

  /// No description provided for @remindersCompleteNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add completion notes (optional)...'**
  String get remindersCompleteNotesHint;

  /// No description provided for @remindersCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder created successfully!'**
  String get remindersCreateSuccess;

  /// No description provided for @remindersUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated successfully!'**
  String get remindersUpdateSuccess;

  /// No description provided for @remindersSnoozeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed successfully!'**
  String get remindersSnoozeSuccess;

  /// No description provided for @remindersCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder marked as completed!'**
  String get remindersCompleteSuccess;

  /// No description provided for @remindersCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder cancelled.'**
  String get remindersCancelSuccess;

  /// No description provided for @remindersEmptyCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get remindersEmptyCaughtUpTitle;

  /// No description provided for @remindersEmptyCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a reminder or schedule future maintenance to stay on top of your business.'**
  String get remindersEmptyCaughtUpSubtitle;

  /// No description provided for @remindersCreateShortcut.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get remindersCreateShortcut;

  /// No description provided for @remindersCreateFollowupShortcut.
  ///
  /// In en, this message translates to:
  /// **'Create Follow-up'**
  String get remindersCreateFollowupShortcut;

  /// No description provided for @remindersSourceRecordLink.
  ///
  /// In en, this message translates to:
  /// **'View Linked Source Record'**
  String get remindersSourceRecordLink;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferencesTitle;

  /// No description provided for @notificationPreferencesPushEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationPreferencesPushEnabled;

  /// No description provided for @notificationPreferencesPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications even when the app is closed'**
  String get notificationPreferencesPushSubtitle;

  /// No description provided for @notificationPreferencesCategoriesHeader.
  ///
  /// In en, this message translates to:
  /// **'Reminder Categories'**
  String get notificationPreferencesCategoriesHeader;

  /// No description provided for @notificationPreferencesMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Notifications'**
  String get notificationPreferencesMaintenance;

  /// No description provided for @notificationPreferencesAmc.
  ///
  /// In en, this message translates to:
  /// **'AMC Expiry & Renewal Alerts'**
  String get notificationPreferencesAmc;

  /// No description provided for @notificationPreferencesFollowups.
  ///
  /// In en, this message translates to:
  /// **'Customer Follow-up Reminders'**
  String get notificationPreferencesFollowups;

  /// No description provided for @notificationPreferencesGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Task Reminders'**
  String get notificationPreferencesGeneral;

  /// No description provided for @notificationPreferencesQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notificationPreferencesQuietHours;

  /// No description provided for @notificationPreferencesQuietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pause notifications during night hours (Asia/Kolkata)'**
  String get notificationPreferencesQuietHoursSubtitle;

  /// No description provided for @notificationPreferencesQuietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours Start'**
  String get notificationPreferencesQuietHoursStart;

  /// No description provided for @notificationPreferencesQuietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours End'**
  String get notificationPreferencesQuietHoursEnd;

  /// No description provided for @notificationPreferencesPreferredTime.
  ///
  /// In en, this message translates to:
  /// **'Default Reminder Time'**
  String get notificationPreferencesPreferredTime;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get notificationsMarkRead;

  /// Unread notification count
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnreadCount(int count);

  /// No description provided for @notificationsAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'No new notifications.'**
  String get notificationsAllCaughtUp;

  /// No description provided for @commOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Communications'**
  String get commOverviewTitle;

  /// No description provided for @commUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage & Costs'**
  String get commUsageTitle;

  /// No description provided for @commSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Settings'**
  String get commSettingsTitle;

  /// No description provided for @commComposeAction.
  ///
  /// In en, this message translates to:
  /// **'Compose Message'**
  String get commComposeAction;

  /// No description provided for @commRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get commRecentActivityTitle;

  /// No description provided for @commLogsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get commLogsEmptyTitle;

  /// No description provided for @commLogsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages and customer notifications will appear here.'**
  String get commLogsEmptySubtitle;

  /// No description provided for @commStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commStatTotal;

  /// No description provided for @commStatOpened.
  ///
  /// In en, this message translates to:
  /// **'In-App Opened'**
  String get commStatOpened;

  /// No description provided for @commTemplatesNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Templates'**
  String get commTemplatesNavTitle;

  /// No description provided for @commTemplatesNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multilingual reusable templates'**
  String get commTemplatesNavSubtitle;

  /// No description provided for @commCampaignsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Campaigns'**
  String get commCampaignsNavTitle;

  /// No description provided for @commCampaignsNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Audience filtering & broadcasts'**
  String get commCampaignsNavSubtitle;

  /// No description provided for @commStatusOpenedInApp.
  ///
  /// In en, this message translates to:
  /// **'Opened in App'**
  String get commStatusOpenedInApp;

  /// No description provided for @commStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get commStatusSubmitted;

  /// No description provided for @commStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get commStatusDelivered;

  /// No description provided for @commStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get commStatusRead;

  /// No description provided for @commStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get commStatusFailed;

  /// No description provided for @commActionOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open in WhatsApp'**
  String get commActionOpenWhatsApp;

  /// No description provided for @commActionOpenSms.
  ///
  /// In en, this message translates to:
  /// **'Open in SMS'**
  String get commActionOpenSms;

  /// No description provided for @commMessagePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Message Body & Preview'**
  String get commMessagePreviewLabel;

  /// No description provided for @commTruthfulLoggingNotice.
  ///
  /// In en, this message translates to:
  /// **'Manual actions open in your device app and are truthfully logged as \'Opened in App\'.'**
  String get commTruthfulLoggingNotice;

  /// No description provided for @commTemplatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No templates found'**
  String get commTemplatesEmptyTitle;

  /// No description provided for @commTemplatesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create custom templates to quickly send updates to your customers.'**
  String get commTemplatesEmptySubtitle;

  /// No description provided for @commCreateTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get commCreateTemplateAction;

  /// No description provided for @commCategoryServiceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Service Updates'**
  String get commCategoryServiceUpdate;

  /// No description provided for @commCategoryAmcRenewal.
  ///
  /// In en, this message translates to:
  /// **'AMC Renewals'**
  String get commCategoryAmcRenewal;

  /// No description provided for @commCategoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get commCategoryMaintenance;

  /// No description provided for @commCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Due'**
  String get commCategoryPayment;

  /// No description provided for @commUseTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get commUseTemplateAction;

  /// No description provided for @commCreateTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get commCreateTemplateTitle;

  /// No description provided for @commEditTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get commEditTemplateTitle;

  /// No description provided for @commTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get commTemplateNameLabel;

  /// No description provided for @commInsertVariableLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to insert dynamic variables:'**
  String get commInsertVariableLabel;

  /// No description provided for @commContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Message Template Content'**
  String get commContentLabel;

  /// No description provided for @commLivePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Preview (Sample Data)'**
  String get commLivePreviewTitle;

  /// No description provided for @commSaveTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Save Template'**
  String get commSaveTemplateAction;

  /// No description provided for @commCampaignsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No campaigns created'**
  String get commCampaignsEmptyTitle;

  /// No description provided for @commCampaignsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create bulk WhatsApp or SMS campaigns to reach your consented customers.'**
  String get commCampaignsEmptySubtitle;

  /// No description provided for @commCreateCampaignAction.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get commCreateCampaignAction;

  /// No description provided for @commEntitledBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Messaging Entitlement Active'**
  String get commEntitledBannerTitle;

  /// No description provided for @commEntitledBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid bulk messaging and audience filtering are ready for your business.'**
  String get commEntitledBannerSubtitle;

  /// No description provided for @commLockedBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid Bulk Messaging Feature'**
  String get commLockedBannerTitle;

  /// No description provided for @commLockedBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your plan to unlock bulk marketing campaigns.'**
  String get commLockedBannerSubtitle;

  /// No description provided for @commUpgradeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Yaadibook Pro'**
  String get commUpgradeDialogTitle;

  /// No description provided for @commUpgradeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Bulk messaging campaigns allow you to reach hundreds of customers at once with promotions and renewal drives.'**
  String get commUpgradeDialogMessage;

  /// No description provided for @commUpgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get commUpgradeAction;

  /// No description provided for @commLaunchCampaignAction.
  ///
  /// In en, this message translates to:
  /// **'Launch Campaign'**
  String get commLaunchCampaignAction;

  /// No description provided for @commUsageSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication Usage & Cost Summary'**
  String get commUsageSummaryTitle;

  /// No description provided for @moreReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Reports'**
  String get moreReportsTitle;

  /// No description provided for @moreSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Plan'**
  String get moreSubscriptionTitle;

  /// No description provided for @moreOfflineSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Sync & Storage'**
  String get moreOfflineSyncTitle;

  /// No description provided for @moreLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get moreLegalTitle;

  /// No description provided for @moreDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account & Data'**
  String get moreDeleteAccountTitle;

  /// No description provided for @reportsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Reports'**
  String get reportsOverviewTitle;

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportsExportCsv;

  /// No description provided for @reportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportsThisMonth;

  /// No description provided for @reportsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get reportsLastMonth;

  /// No description provided for @reportsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get reportsLast3Months;

  /// No description provided for @reportsLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get reportsLast6Months;

  /// No description provided for @reportsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get reportsThisYear;

  /// No description provided for @reportsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsCustomRange;

  /// No description provided for @reportsOfflineEstimateNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: showing cached local data summary.'**
  String get reportsOfflineEstimateNotice;

  /// No description provided for @reportsRecordedAmountsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Recorded service & contract amounts reflect operational entries in Yaadibook, not formal accounting or GST tax invoices.'**
  String get reportsRecordedAmountsDisclaimer;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Plan'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get subscriptionRestoreAction;

  /// No description provided for @subscriptionUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Usage & Limits'**
  String get subscriptionUsageTitle;

  /// No description provided for @offlineSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Sync & Storage'**
  String get offlineSyncTitle;

  /// No description provided for @offlineSyncNowAction.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get offlineSyncNowAction;

  /// No description provided for @offlineClearCacheAction.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Cache'**
  String get offlineClearCacheAction;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account & Data'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your business workspace, customers, services, AMCs, reminders, communication history, and uploaded files. This cannot be undone.'**
  String get deleteAccountWarning;
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
