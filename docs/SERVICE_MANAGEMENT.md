# Yaadibook — Service Management Specification

## 1. Overview & Business Context

The Service Management module provides small, independent service businesses across India (AC maintenance, CCTV installers, water purifier technicians, electricians, appliance mechanics) with a straightforward, mobile-first system to record work, track job progress, link customer equipment, document charges, attach onsite photos, and manage service history without requiring complex ERP software or technician dispatch tools.

Yaadibook is designed for the individual business owner who personally manages or executes customer jobs.

---

## 2. Key Capabilities & Features

### 1. Human-Readable Business-Scoped Reference Numbers
- Every service entry is assigned an atomic human-readable reference number: `YB-SRV-XXXXXX` (e.g. `YB-SRV-000001`).
- Numbers are tracked in the database table `public.business_sequences` via atomic PL/pgSQL function `public.next_service_number(p_business_id UUID)`.
- Numbers are continuous, monotonic, and completely business-isolated (each business maintains its own sequence).

### 2. Service Creation & Association
- **Customer Selection**: Mandatory association with an existing customer.
  - When initiated from a customer profile, the customer is preselected automatically.
  - When initiated from the central Quick Add (`+`) action or Services Overview, a bottom sheet search modal allows quick selection.
- **Service Categories**:
  - Installation
  - Repair
  - Maintenance
  - Inspection
  - General Service
  - Other
- **Optional Equipment Association**:
  - Service entries can optionally link to customer equipment (e.g., "Split AC 1.5T", "Hikvision 8CH DVR").
  - Equipment tracking is strictly optional and never blocks creating or completing a service record.
- **Service Address**: Automatically inherits customer's primary address, or selects among registered customer addresses.

### 3. Work Details & Charge Breakdown
- **Work Details**:
  - Service Title (Mandatory, e.g. "AC Deep Cleaning & Gas Checkup")
  - Service Date (Defaults to today, selectable)
  - Issue / Description (Customer's initial complaint or request)
  - Work Performed (Detailed notes on replacement parts, labor done)
  - Internal Notes (Private notes for the business owner)
- **Financial Calculation Formula**:
  $$\text{Total Amount} = \max(0, \text{Base Service Charge} + \text{Additional Charges} - \text{Discount})$$
  - Real-time live calculation during entry.
  - Negative charges are rejected.
  - Discounts exceeding the charges subtotal are rejected by UI and database trigger.
  - Currency displayed throughout in Indian Rupee format (`₹`, Lakhs/Crores grouping via `CurrencyFormatter`).

### 4. Service Lifecycle & Progress Tracking
- Valid Statuses:
  - `Pending`: Service scheduled or requested, work has not started.
  - `In Progress`: Technician or owner is actively diagnosing or executing work.
  - `Completed`: Work finished, completion timestamp recorded.
  - `Cancelled`: Job cancelled by customer or business; historical record retained for audit purposes.
- Seamless status actions:
  - "Start Work" -> Moves Pending to In Progress.
  - "Mark Completed" -> Prompts for completion notes, work performed, and final charge adjustment.
  - "Cancel Service" -> Warns user that records are preserved and transitions to Cancelled.
  - "Resume Service" -> Reopens a cancelled service back to In Progress.

### 5. Service Photos & Document Attachments
- Up to multiple files per service.
- Supported file types: Images (`image/jpeg`, `image/png`, `image/webp`) and Documents (`application/pdf`).
- Device integration: Direct capture via Camera or selection from Gallery using `image_picker`.
- Storage: Supabase Storage bucket `service-attachments`.
  - Storage path structure: `{business_id}/{service_id}/{timestamp}_{filename}`.
  - Fully private bucket protected by RLS policy `public.is_business_owner()`.
  - Secure short-lived signed URLs for viewing and downloading attachments.

### 6. Service Activity Audit Timeline
- Chronological event timeline persisted in `public.service_activities`:
  - `created`: Initial service record created.
  - `status_changed`: Service moved between lifecycle states (records old and new status).
  - `details_updated`: Title, charges, or work description modified.
  - `attachment_added`: New photo or document uploaded.
  - `attachment_removed`: Attachment deleted.
- Each event displays actor, description, and localized relative/absolute timestamps.

### 7. Customer Communication Integration
- Direct One-Touch Phone Call (`CommunicationService.makePhoneCall`): Opens device native dialer with prefilled customer phone.
- Pre-composed WhatsApp Message (`CommunicationService.openWhatsApp`):
  `"Hello {CustomerName}, regarding your service '{ServiceTitle}' ({ServiceNumber}) with {BusinessName}."`

---

## 3. Database Schema

### `service_entries`
| Column | Type | Constraints / Description |
|---|---|---|
| `id` | UUID | Primary Key, `gen_random_uuid()` |
| `business_id` | UUID | Foreign Key to `businesses.id`, NOT NULL |
| `customer_id` | UUID | Foreign Key to `customers.id`, NOT NULL |
| `customer_address_id` | UUID | Foreign Key to `customer_addresses.id`, NULLable |
| `equipment_id` | UUID | Foreign Key to `equipment.id`, NULLable |
| `service_number` | VARCHAR(30) | NOT NULL, format `YB-SRV-XXXXXX` |
| `service_type` | VARCHAR(50) | NOT NULL DEFAULT 'general' |
| `title` | TEXT | NOT NULL |
| `description` | TEXT | NULLable |
| `work_performed` | TEXT | NULLable |
| `service_date` | DATE | NOT NULL DEFAULT CURRENT_DATE |
| `status` | VARCHAR(20) | NOT NULL DEFAULT 'pending' |
| `service_amount` | NUMERIC(10,2) | NULLable |
| `additional_charges` | NUMERIC(10,2) | NOT NULL DEFAULT 0.00 |
| `discount_amount` | NUMERIC(10,2) | NOT NULL DEFAULT 0.00 |
| `total_amount` | NUMERIC(10,2) | NOT NULL DEFAULT 0.00 |
| `payment_status` | VARCHAR(20) | NULLable ('unpaid', 'partially_paid', 'paid') |
| `notes` | TEXT | NULLable |
| `completed_at` | TIMESTAMPTZ | NULLable |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() |

### `service_attachments`
| Column | Type | Constraints / Description |
|---|---|---|
| `id` | UUID | Primary Key |
| `business_id` | UUID | Foreign Key to `businesses.id`, NOT NULL |
| `service_id` | UUID | Foreign Key to `service_entries.id` ON DELETE CASCADE |
| `file_path` | TEXT | Storage object path in `service-attachments` bucket |
| `file_name` | TEXT | Original file name |
| `file_size` | BIGINT | Size in bytes |
| `mime_type` | TEXT | File MIME type |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() |

### `service_activities`
| Column | Type | Constraints / Description |
|---|---|---|
| `id` | UUID | Primary Key |
| `business_id` | UUID | Foreign Key to `businesses.id`, NOT NULL |
| `service_id` | UUID | Foreign Key to `service_entries.id` ON DELETE CASCADE |
| `activity_type` | VARCHAR(50) | NOT NULL |
| `title` | TEXT | NOT NULL |
| `description` | TEXT | NULLable |
| `old_status` | VARCHAR(50) | NULLable |
| `new_status` | VARCHAR(50) | NULLable |
| `actor_user_id` | UUID | NULLable |
| `metadata` | JSONB | NOT NULL DEFAULT '{}' |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() |

---

## 4. UI Navigation & Routes

| Route | Destination Screen | Description |
|---|---|---|
| `/services` | `ServicesOverviewScreen` | 2x2 Metric summary, Pending services, Recent services, FAB |
| `/services/list` | `ServicesListScreen` | Filterable (All, Pending, In Progress, Completed, Cancelled), searchable, sortable list |
| `/services/add` | `AddServiceScreen` | Full service creation wizard (Customer, Details, Equipment, Charges, Photos) |
| `/services/:id` | `ServiceDetailScreen` | Full detail screen, quick call/WhatsApp, status actions, charges, photos, timeline |
| `/services/:id/edit` | `EditServiceScreen` | Form prefilled with existing service details to edit |

