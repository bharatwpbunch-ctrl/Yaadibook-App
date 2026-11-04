# Yaadibook — Development Guidelines & Code Standards

## 1. Code Standards & Style

1. **Strict Dart Formatter**: All code must pass `dart format . --line-length=120` without exceptions.
2. **Analysis Lints**: All code must pass `flutter analyze` with 0 errors and 0 warnings.
3. **No Hardcoded Strings**: Never hardcode user-facing strings directly inside widgets. Always add keys to `lib/app/localization/arb/app_en.arb`, `app_gu.arb`, and `app_hi.arb` and access via `context.l10n.<key>`.
4. **No Direct Database Calls in Widgets**: UI components must never instantiate or call `SupabaseClient` directly. All data access must pass through Riverpod providers and repositories.
5. **No Massive Widgets**: Break down widgets larger than 120 lines into dedicated private or shared sub-widgets.
6. **Consistent Naming**:
   - Files: `snake_case.dart` (e.g. `customer_card.dart`).
   - Classes & Enums: `PascalCase` (e.g. `YbCustomerCard`, `AppColors`).
   - Variables & Methods: `camelCase` (e.g. `formatShort`, `onCustomerTapped`).
   - Private members: Prefix with underscore `_`.

---

## 2. Testing Requirements

1. **Unit Tests**:
   - Formatters (`CurrencyFormatter`, `DateFormatter`).
   - Configuration & Environment loaders.
   - StateNotifiers (`AppLocaleNotifier`).
2. **Widget Tests**:
   - App root initialization (`YaadibookApp`).
   - Theme loading and colors.
   - Multilingual loading & locale switching.
   - Navigation routing between bottom tabs.
   - Core Design System widgets (`YbPrimaryButton`, `YbTextInput`, `YbStatusBadge`, `YbCustomerCard`).
3. Run test suites via `flutter test`. All tests must pass cleanly.

---

## 3. Git & Branching Strategy

- `main`: Production-ready releases.
- `develop`: Integration branch for active phase features.
- Feature branches: `feature/phase-X-feature-name`.
- Never commit `.env` or credentials. Always verify `.gitignore` before committing.

