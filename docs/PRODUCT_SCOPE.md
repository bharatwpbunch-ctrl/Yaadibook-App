# Yaadibook — Product Scope & Specifications

## 1. Executive Summary

**Yaadibook** is a simple, mobile-first business management assistant specifically tailored for individual small-business owners and service professionals in India, with an initial launch focus on Gujarat.

It simplifies customer management, service record keeping, periodic maintenance scheduling, Annual Maintenance Contract (AMC) renewal tracking, follow-up organization, and direct customer communication via phone and WhatsApp.

---

## 2. Target Audience & Business Verticals

Initial focus verticals in Gujarat and tier-2/tier-3 cities across India:
- **CCTV & Security Installation**: Camera installations, DVR/NVR maintenance, wire checking, AMC contracts.
- **AC & HVAC Service**: Seasonal filter cleaning, gas recharging, installation, preventative maintenance contracts.
- **RO & Water Purifier**: Periodic cartridge/membrane filter replacement, TDS level checkups, quarterly AMC visits.
- **Appliance Repair**: Washing machine, microwave, refrigerator repair and service follow-ups.
- **Other Local Service-based Businesses**: Electricians, plumbers, solar panel maintenance, elevator upkeep.

---

## 3. Confirmed Product Decisions (Fixed for MVP)

1. **One Owner, One Business**: An owner manages a single business workspace.
2. **No Multi-User/Technicians in MVP**: No employee management, technician dispatch, or team hierarchy in Phase 1 or MVP.
3. **No Multi-Branch**: Single workshop/office location per account.
4. **Equipment Tracking is Optional**: Services and customer records can be created with or without linking specific equipment serials/models.
5. **Languages**: Trilingual support from day one:
   - **English (`en`)**
   - **Gujarati (`gu`)**
   - **Hindi (`hi`)**
   - Default language: English.
6. **Platform Priority**:
   - Android-first development (primary target OS in Indian small business).
   - iOS-ready clean Flutter architecture.
7. **Backend & Database**:
   - **Supabase** (Managed PostgreSQL, Auth, Row Level Security, Edge Functions).

---

## 4. Feature Roadmap by Phases

### Phase 1: Project Foundation & Mobile Architecture (Current)
- Flutter project initialization with clean architecture.
- Central design tokens & reusable UI component library (buttons, inputs, cards, dialogs, sheets).
- Riverpod state management setup.
- GoRouter navigation shell with bottom navigation bar (Today, Customers, Quick Add, Reminders, More).
- Trilingual localization engine (English, Gujarati, Hindi) with ARB files and live language switching.
- Safe environment configuration (dev, staging, prod) and Supabase client integration preparation.
- Unit and widget test suite foundation.

### Phase 2: Authentication & Business Profile Setup
- Phone OTP / Supabase Auth integration.
- Business profile onboarding (business name, owner name, category, phone, address).
- Secure token persistence.

### Phase 3: Customer Management & Service Records
- Customer directory (CRUD, search, direct call/WhatsApp triggers).
- Service record logging (date, charges, notes, service type).
- Optional equipment association.

### Phase 4: AMC & Maintenance Engine
- AMC contract creation (start date, duration, visit schedule, price).
- Maintenance visit scheduling and automated due-date calculations.

### Phase 5: Reminders & Customer Communication
- Automated follow-up alerts (due services, overdue visits, AMC renewal).
- One-click WhatsApp message templates with customer-specific placeholders.

---

## 5. Explicit Out-of-Scope Restrictions for MVP

The following are strictly prohibited in the MVP:
- Technician / employee role management.
- Multi-branch accounting.
- Multi-tenancy team permissions.
- In-app payment gateway / digital checkout.
- Subscription billing systems.
- Heavy enterprise ERP features.
- Automated bulk spam messaging.

