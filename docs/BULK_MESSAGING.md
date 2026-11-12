# Yaadibook — Paid Bulk Messaging & Broadcast Campaigns

## 1. Overview
Bulk Messaging enables business owners to run targeted broadcast campaigns (e.g., Diwali seasonal checkup offer, pre-monsoon maintenance drive, AMC renewal batches).

---

## 2. Entitlement Interface (Phase 10 Foundation)
To prevent building fake or premature billing while ensuring modular architecture:
- Yaadibook implements `isBulkMessagingEntitledProvider`:
  ```dart
  final isBulkMessagingEntitledProvider = StateProvider<bool>((ref) => true);
  ```
- Defaults to `true` in development to allow thorough feature verification.
- Ready to be swapped with the subscription entitlement repository in Phase 10 (Subscriptions & In-App Purchases).

---

## 3. Campaign Wizard Flow
1. **Basics**: Campaign Title, Channel (WhatsApp / SMS), Category.
2. **Template**: Selection of approved template with dynamic placeholders.
3. **Audience Filtering**:
   - Filter segments: All Customers, Residential, Commercial, Industrial, With AMC.
   - Filter logic strictly excludes opted-out contacts and requires `marketing_consent == true`.
   - Live recipient preview list.
4. **Review & Cost Estimation**:
   - Total recipients count.
   - Per-message rate (WhatsApp: ₹0.85, SMS: ₹0.20).
   - Estimated total cost in INR.
5. **Dispatch & Tracking**:
   - Inserts `communication_campaigns` and individual `campaign_recipients`.
   - Real-time progress bar and delivery breakdown.

