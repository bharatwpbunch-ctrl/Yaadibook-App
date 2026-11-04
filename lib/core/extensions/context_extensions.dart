import 'package:flutter/material.dart';
import '../../app/localization/generated/app_localizations.dart';

extension ContextExtensions on BuildContext {
  /// Convenient accessor for localized strings.
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw StateError(
        'AppLocalizations not found in current context. Ensure that your widget is beneath a Localizations ancestor.',
      );
    }
    return localizations;
  }

  /// Current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Current screen size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Current [Locale].
  Locale get currentLocale => Localizations.localeOf(this);
}
