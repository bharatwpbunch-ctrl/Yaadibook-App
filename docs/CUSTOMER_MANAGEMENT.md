# Yaadibook — Customer Management Specification

## 1. Overview & Business Context

The Customer Management module serves as the primary relationship repository for Yaadibook business owners. It provides individual service providers (AC technicians, CCTV installers, RO service agents, electricians, appliance repairers) a simple, fast mobile interface to maintain customer details, address information, contact history, and service relationships without the overhead of desktop CRM software.

---

## 2. Key Capabilities & User Stories

1. **Customer Directory & Search**
   - View all active, archived, or total customers in clean Material 3 cards.
   - Real-time debounced search by customer name, mobile number, and email.
   - Filter chips for `Active`, `Archived`, and `All`.
   - Sort dropdown: `Recently added`, `Name (A–Z)`, `Name (Z–A)`.
   - Contact initials avatar with high contrast badges for business clients and archived records.

2. **Add & Edit Customer**
   - Required fields: Full Name, 10-digit Mobile Number (with automatic +91 prefix indicator).
   - Optional fields: Alternate Mobile Number, Email Address, Customer Type (`Individual` / `Business` segmented toggle), Collapsible Address section (Line 1, Line 2, Area, City, State, PIN code), Customer Notes.
   - Automatic phone normalization: cleans spaces, hyphens, parentheses, trunk `0`, and country code `91`.
   - **Duplicate Phone Number Detection**: Automatically checks Supabase for existing numbers under the owner's business. Displays an alert dialog with options to "View Profile" or "Save Anyway".

3. **Customer Details & Activity Timeline**
   - **Identity Card**: Initials avatar, customer name, business/individual tag, primary phone, alternate phone, email.
   - **Quick Communication Bar**:
     - **Call Button**: Opens native phone dialer with `tel:` URI and non-blockingly logs communication to `communication_logs` (status `initiated`).
     - **WhatsApp Button**: Opens WhatsApp directly using pre-formatted greeting message `"Hello {CustomerName}, greetings from {BusinessName}."` and logs to `communication_logs` (status `opened`).
   - **Address & Notes Card**: Formatted address display and editable customer preferences/notes.
   - **Service & Maintenance Overview**: 2x2 metric cards displaying live Total Services, Pending Services, Completed Services, and Reminders.
   - **Service History Section**: Chronological list of customer service visits with status pills, dates, and amounts, plus an "Add Service" action preselecting this customer.
   - **Activity Timeline**: Chronological events recording Customer Created, Customer Updated, Phone Calls, WhatsApp messages, and Archive/Restore actions.

4. **Archive & Restore (Soft Deletion)**
   - Hard deletion is prohibited to protect historical service and accounting data integrity.
   - Owners can archive inactive customers with a confirmation dialog.
   - Archived customers are hidden from the active list but remain fully searchable under the `Archived` filter and can be restored at any time.

---

## 3. Data Architecture & Entities

### `customers` Table
- `id`: UUID (Primary Key)
- `business_id`: UUID (Foreign Key to `businesses.id`, isolated by RLS)
- `full_name`: TEXT NOT NULL
- `primary_phone`: VARCHAR(20) NOT NULL
- `alternate_phone`: VARCHAR(20)
- `email`: VARCHAR(255)
- `customer_type`: TEXT NOT NULL DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business'))
- `notes`: TEXT
- `archived_at`: TIMESTAMPTZ (NULL = active, non-NULL = archived)
- `created_at`, `updated_at`: TIMESTAMPTZ NOT NULL

### `customer_addresses` Table
- `id`: UUID (Primary Key)
- `business_id`: UUID (Foreign Key, tenant-isolated)
- `customer_id`: UUID (Foreign Key to `customers.id`, CASCADE delete)
- `address_label`: VARCHAR(50) DEFAULT 'Main'
- `address_line1`: TEXT NOT NULL
- `address_line2`: TEXT
- `area`: VARCHAR(100) NOT NULL
- `city`: VARCHAR(100) NOT NULL DEFAULT 'Ahmedabad'
- `state`: VARCHAR(100) NOT NULL DEFAULT 'Gujarat'
- `postal_code`: VARCHAR(10) NOT NULL
- `is_default`: BOOLEAN DEFAULT true

### `communication_logs` Table
- `id`: UUID (Primary Key)
- `business_id`: UUID (Tenant isolated)
- `customer_id`: UUID (Linked customer)
- `channel`: VARCHAR(20) NOT NULL CHECK (channel IN ('call', 'whatsapp', 'sms', 'email'))
- `direction`: VARCHAR(10) NOT NULL DEFAULT 'outgoing' CHECK (direction IN ('incoming', 'outgoing'))
- `message_type`: VARCHAR(50) DEFAULT 'manual'
- `message_content`: TEXT
- `status`: VARCHAR(20) NOT NULL DEFAULT 'initiated' CHECK (status IN ('initiated', 'opened', 'sent', 'delivered', 'failed', 'unknown'))

---

## 4. State Management (Riverpod)

| Provider | Type | Purpose |
|---|---|---|
| `customerSearchQueryProvider` | `StateProvider.autoDispose<String>` | Active search term in directory |
| `customerFilterProvider` | `StateProvider.autoDispose<CustomerFilter>` | Active filter (active, archived, all) |
| `customerSortProvider` | `StateProvider.autoDispose<CustomerSort>` | Sort order (recentlyAdded, nameAsc, nameDesc) |
| `customersListProvider` | `FutureProvider.autoDispose<List<Customer>>` | Reactive customer list from Supabase |
| `customerDetailProvider(id)` | `FutureProvider.autoDispose.family<Customer?, String>` | Full customer record with primary address |
| `customerActivityProvider(customer)` | `FutureProvider.autoDispose.family<List<CustomerActivityItem>, Customer>` | Chronological timeline items |
| `customerFormControllerProvider(customer)` | `StateNotifierProvider.autoDispose.family<CustomerFormController, CustomerFormState, Customer?>` | Add / Edit form validation & duplicate detection |

---

## 5. Security & Multi-Tenancy
- Row Level Security (RLS) is active on `customers`, `customer_addresses`, and `communication_logs`.
- All operations are scoped through `current_user_business_id()` so owners can never access another business's customers.
- Mobile dialer and WhatsApp operations require user confirmation and launch externally via explicit platform intent schemes (`tel:`, `whatsapp://`, `https://wa.me/`).
