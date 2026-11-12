# Yaadibook — Mobile Contact Import Specification

## 1. Overview & Privacy Principles

Yaadibook provides selective mobile contact importing to allow Indian service business owners to quickly bootstrap their customer list from their phone's address book without manually retyping customer names and phone numbers.

### Core Privacy Principles:
1. **Explicit Permission**: Contacts are accessed only when the owner explicitly chooses to import contacts.
2. **Selective Import**: The application **never** performs silent, background, or whole-address-book scraping. Only contacts explicitly chosen by the owner are imported.
3. **Transparent Rationale**: When permission has not yet been granted, a clear, friendly rationale card explains why access is requested.
4. **Permanent Denial Handling**: If permission is permanently denied in Android/iOS settings, the app provides a direct button to open the device application settings (`openAppSettings()`).

---

## 2. Technical Implementation

### Dependencies
- `permission_handler: ^13.0.2`: Manages runtime permission requests and status checking.
- `flutter_contacts: ^2.1.0`: Native platform bridge to fetch address book contacts on Android and iOS.

### Android Manifest Permissions & Queries
In `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="tel" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <package android:name="com.whatsapp" />
    <package android:name="com.whatsapp.w4b" />
</queries>
```

---

## 3. Contact Import User Flow

```mermaid
flowchart TD
    A[Customers Screen Empty / Header Action] -->|Tap 'Import from Contacts'| B[Check Permission Status]
    B -->|Not Granted / Denied| C[Display Permission Rationale Screen]
    C -->|Tap 'Allow Contacts Access'| D[Request Runtime Permission]
    D -->|Granted| E[Fetch Device Contacts with Phone Numbers]
    D -->|Permanently Denied| F[Display 'Open Settings' Action]
    B -->|Granted| E
    E --> G[Display Searchable Contact List]
    G -->|Search Contact Name/Phone| H[Filter Results Dynamically]
    G -->|Tap Single Contact Arrow| I{Multiple Phone Numbers?}
    I -->|Yes| J[Show Phone Number Selector Dialog]
    I -->|No| K[Open Add Customer Screen with Prefilled Name & Phone]
    J -->|Select Phone| K
    G -->|Multi-select Checkboxes| L[Show 'Import Selected (N)' Button]
    L -->|Submit Batch Import| M[Normalize Phones & Check Duplicates]
    M -->|Save Non-duplicates| N[Update Supabase Database]
    N --> O[Show Result SnackBar & Return to Customers Screen]
```

---

## 4. Duplicate Detection & Data Integrity

When contacts are imported:
1. Each phone number is normalized through `CommunicationService.normalizePhoneNumber()`.
2. Existing customer numbers in the owner's business are queried.
3. In batch import mode, exact duplicates are skipped automatically and reported in the completion toast:
   `"5 customers imported (2 skipped/duplicates)."`
4. In single-contact mode, the owner is navigated to `AddCustomerScreen` where full duplicate detection alerts the user and offers the choice to view the existing customer profile or save anyway.

---

## 5. Trilingual Support

All contact import copy is fully translated into English, Gujarati, and Hindi:
- Permission Rationale: `contactPermissionRationaleTitle`, `contactPermissionRationaleMessage`, `contactPermissionGrant`
- Settings Fallback: `contactPermissionDeniedMessage`, `contactOpenSettings`
- Multiple Numbers Picker: `contactSelectPhoneTitle`, `contactSelectPhoneMessage`
- Batch Action: `contactActionImportSelected`

