# Yaadibook — Final Product Specification (Phases 1–10 MVP)

## 1. Product Vision & Target Users
**Yaadibook** is a mobile-first business operations assistant built for local Indian service businesses (e.g., CCTV & security installers, RO/water purifier servicing, AC/appliance repair, electrical & plumbing contractors, solar maintenance providers).

## 2. Core Capabilities Implemented in MVP
1. **Authentication & Business Onboarding (Phases 1–3)**
   - Email/password login, signup, forgot-password reset, business workspace creation, profile & business address editing (`BusinessProfileScreen`).
   - Trilingual UI support: **English (`en`)**, **Gujarati (`gu`)**, **Hindi (`hi`)**.
2. **Today Dashboard & App Navigation (Phases 4–5)**
   - Daily operational overview (overdue follow-ups, due today reminders, upcoming AMCs/maintenance, quick-add sheet).
   - 4-tab mobile shell (`Today`, `Customers`, `Reminders`, `More`) plus central `+ Add` modal sheet.
3. **Customer Management (Phase 5)**
   - Individual & business customer profiles, multiple addresses, equipment tracking, phone duplicate checking, contact import, call/WhatsApp shortcuts, customer activity timeline, archiving/restoring.
4. **Services & Work Tracking (Phase 6)**
   - Installations, repairs, maintenance visits, inspections, recorded service amounts, payment status (`unpaid`, `partially_paid`, `paid`, `waived`), status transitions, activity history, and attachment storage.
5. **Maintenance Schedules & AMC Contracts (Phase 7 + Fixes)**
   - Recurring & custom-frequency maintenance plans, automatic occurrence schedules, pre-due reminders, AMC contract creation, expiry tracking (`active`, `expiring`, `expired`, `renewed`, `cancelled`), one-click renewal workflow, and pre-expiry customer reminders.
6. **Unified Reminders & Notification Engine (Phase 8)**
   - Unified reminders feed aggregating Maintenance, AMC, Customer Follow-up, and General reminders (`due_today`, `overdue`, `upcoming`, `completed`, `snoozed`), in-app Notification Centre, notification preferences & quiet hours, FCM device token registration, and server-side processing Edge Function scaffold.
7. **Customer Communication & Bulk Messaging (Phase 9)**
   - Manual one-tap WhatsApp & SMS prefilled communication, reusable trilingual message templates (`{{customer_name}}`, etc.), customer consent & opt-out management, communication history, and server-gated bulk campaigns/APIs.
8. **Business Reports & Exports (Phase 10A)**
   - Date-filtered Overview, Customers, Services & Recorded Amounts, Maintenance, AMCs, and Follow-ups reports.
   - CSV (OWASP formula-injection sanitized) and INR-formatted PDF export & sharing.
   - Explicit disclaimer separating operational recorded amounts from accounting/GST invoices.
9. **Offline Support & Synchronization (Phase 10B)**
   - Local caching & offline queuing for Customers, Services, and Reminders via Drift/SQLite (`HybridOfflineStore` + `SyncEngine`), conflict detection & resolution UI, connectivity banner, and automatic cache wipe on logout.
10. **Subscriptions, Compliance & Launch Readiness (Phase 10C–E)**
    - Free vs Pro plans (`subscription_plans`), authoritative backend `get_business_entitlements` RPC, central `entitlementsProvider`, Google Play Billing integration (`PlayBillingService` + `verify-play-purchase`), in-app Legal summaries, and Account & Data Deletion workflow.

## 3. Explicit Out-of-Scope Boundaries
- Full double-entry accounting, GST tax filing, and statutory tax invoices.
- Inventory/spare-parts stock management.
- Employee/technician multi-user accounts and payroll.
- Multi-branch franchise management or customer self-service portals.
- External payment gateways bypassing Google Play Billing rules on Android.

