/// Core constants for Yaadibook.
class AppConstants {
  AppConstants._();

  static const String appName = 'Yaadibook';
  static const String appVersion = '0.1.0';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCountryCode = '+91';

  // Indian standard 10-digit mobile number regex pattern
  static final RegExp indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
}
