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

## 3. Authentication & Onboarding Conventions (Phase 3)

1. **User Identity vs Profile**:
   - Authentication sessions are managed by Supabase Auth (`auth.users`).
   - Business owner metadata resides in `public.profiles`.
   - On registration, profile creation is idempotent via `upsertProfile`.
2. **Business Isolation & Single Workspace**:
   - Each authenticated owner can create at most one business in MVP.
   - All workspace creations must invoke the PostgreSQL function `create_business_workspace` atomically.
   - Do not trust client-supplied owner user IDs; ownership is derived from `auth.uid()`.
3. **User-Friendly Error Translation**:
   - Never surface raw SQL errors, stack traces, or Supabase AuthException strings directly to the user.
   - Map errors to friendly localized strings in `AuthController`.
4. **Form State Preservation**:
   - When a network or server validation error occurs during onboarding or registration, preserve user inputs in the controller state to allow safe retry without retyping.

---

## 4. Git & Branching Strategy

- `main`: Production-ready releases.
- `develop`: Integration branch for active phase features.
- Feature branches: `feature/phase-X-feature-name`.
- Never commit `.env` or credentials. Always verify `.gitignore` before committing.

