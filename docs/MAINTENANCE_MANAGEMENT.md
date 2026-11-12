# Yaadibook — Maintenance Management Module

## 1. Overview & Purpose

In local Indian service businesses (HVAC/air conditioning, water purification/RO, CCTV security, electricals, appliances), scheduled maintenance visits represent the foundation of customer retention and recurring service revenue.

Yaadibook's Maintenance Management module enables small-business owners to:
1. Create recurring or one-time maintenance plans for customers.
2. Link maintenance to customer equipment optionally (never mandatory).
3. Automatically track upcoming, due, and overdue maintenance visits.
4. Execute key visit actions: **Mark Completed** (with work report, charges, notes), **Skip** (with logged reason), or **Reschedule** (with full date history).
5. Automatically compute and generate the next occurrence when recurring visits are completed or skipped without duplicate creation.
6. Provide fast phone call and WhatsApp communication directly from visit cards.

---

## 2. Core Architecture: Plans vs Occurrences

Yaadibook enforces a clear separation of concerns between recurring schedules and individual visits:

```
+--------------------------------------------------------------------+
|                         Maintenance Plan                           |
|  - Source of truth for recurring schedule                          |
|  - Frequency (Monthly, Quarterly, Half-Yearly, Yearly, Custom)     |
|  - Customer reference & optional equipment link                    |
|  - Next due date & anchor day preservation                         |
|  - Status: active | paused | completed | cancelled                |
+--------------------------------------------------------------------+
                                  |
                                  | 1-to-many
                                  v
+--------------------------------------------------------------------+
|                     Maintenance Occurrence                         |
|  - Individual scheduled field visit                                |
|  - Due date & original due date (audit reschedule history)         |
|  - Status: scheduled | upcoming | due | overdue | completed | ...  |
|  - Completed work report, amount charged, completion timestamp     |
|  - Skip reason if skipped                                          |
+--------------------------------------------------------------------+
```

- **`MaintenancePlan`** is the master specification.
- **`MaintenanceOccurrence`** is the operational visit record executed by the owner in the field.

---

## 3. Occurrence Lifecycle & Operational States

The operational state of each visit is computed dynamically based on the due date and execution status:

| Effective Status | Condition | Visual Indicator | Available Actions |
|:---|:---|:---|:---|
| **Due Today** | `status = 'scheduled'` AND `due_date = TODAY` | Amber Chip / Warning | Complete, Skip, Reschedule, Call, WhatsApp |
| **Overdue** | `status = 'scheduled'` AND `due_date < TODAY` | Red Chip / Error | Complete, Skip, Reschedule, Call, WhatsApp |
| **Upcoming** | `status = 'scheduled'` AND `due_date > TODAY` | Blue Chip / Info | Complete, Skip, Reschedule, Call, WhatsApp |
| **Completed** | `status = 'completed'` | Green Chip / Success | View work report & amount |
| **Skipped** | `status = 'skipped'` | Gray Chip / Neutral | View skip reason |
| **Cancelled** | `status = 'cancelled'` | Gray Chip / Neutral | View cancellation details |

---

## 4. User Experience & Screen Inventory

1. **Maintenance Overview Screen (`/maintenance`)**:
   - 4-card metric summary header: Due Today, Overdue, Upcoming, Active Plans.
   - Filter chips: All, Due Today, Overdue, Upcoming, Completed.
   - Quick action to open All Plans (`/maintenance/plans`).
   - Occurrence cards with inline Complete, Skip, Reschedule actions.
   - Floating Action Button to schedule a new visit (`/maintenance/add`).

2. **Maintenance Plans Screen (`/maintenance/plans`)**:
   - Filter tabs: All, Active, Paused, Completed, Cancelled.
   - Search by plan number or customer name.
   - Displays frequency badge, customer, equipment, and next due date.

3. **Add Maintenance Plan Screen (`/maintenance/add`)**:
   - Supports customer preselection via query parameter `?customerId=...`.
   - Customer picker bottom sheet.
   - Optional equipment picker filtered to selected customer.
   - Frequency selector: One-time or Recurring.
   - Presets: Monthly, Quarterly, Half-Yearly, Yearly, or Custom (Days/Weeks/Months/Years).
   - Anchor day automatic extraction from start date.
   - First due date picker and optional end date.
   - Reminder threshold configuration (default 3 days prior).

4. **Maintenance Plan Detail Screen (`/maintenance/plans/:id`)**:
   - Complete plan parameters and active status chip.
   - Customer identity card with one-click phone dialer and WhatsApp chat.
   - Linked equipment asset card.
   - Actions to Pause/Resume plan or Cancel plan.
   - Edit shortcut (`/maintenance/plans/:id/edit`).

5. **Maintenance Occurrence Detail Screen (`/maintenance/occurrences/:id`)**:
   - Full visit card with due date and rescheduled history.
   - Customer and equipment cards.
   - Interactive dialogs to complete (recording work report and amount), skip (recording reason), or reschedule (picking new due date).
   - Direct link to parent plan.

