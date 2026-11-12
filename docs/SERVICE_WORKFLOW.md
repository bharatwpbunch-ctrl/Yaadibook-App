# Yaadibook — Service Workflow & Lifecycle Architecture

## 1. Lifecycle State Machine

A service record transitions through explicit lifecycle states designed for real-world field servicing.

```mermaid
stateDiagram-v2
    [*] --> Pending: Owner creates service entry
    Pending --> In_Progress: Start Work
    Pending --> Completed: Quick Completion
    Pending --> Cancelled: Customer/Owner Cancels
    In_Progress --> Completed: Work Finished & Charges Settled
    In_Progress --> Cancelled: Aborted or Unsolvable
    Cancelled --> In_Progress: Resume Service
    Completed --> [*]
```

### Transition Specifications

| Current State | Target State | Trigger / User Action | Required Data / Notes |
|---|---|---|---|
| `*` (New) | `Pending` | Add Service submitted with status `pending` | Customer, Title, Type, Date |
| `*` (New) | `In Progress` | Add Service submitted with status `in_progress` | Customer, Title, Type, Date |
| `Pending` | `In Progress` | Tap "Start Work" in Detail screen or Overview | Updates `status`, logs `status_changed` |
| `Pending` or `In Progress` | `Completed` | Tap "Mark Completed" | Prompts optional work performed notes, sets `completed_at: NOW()` |
| `Pending` or `In Progress` | `Cancelled` | Tap "Cancel Service" | Prompts cancellation reason, sets status to `cancelled` |
| `Cancelled` | `In Progress` | Tap "Resume Service" | Reopens cancelled job, resets to `in_progress` |

---

## 2. Creation Entry Points

```mermaid
flowchart TD
    A1["Quick Add Action (+) Bottom Sheet"] --> B1["Customer Selection Modal"]
    B1 --> C["Add Service Form (/services/add)"]
    A2["Services Overview Screen (FAB)"] --> B1
    A3["Customer Profile Screen ('Add Service' Action)"] --> D["Add Service Form with Preselected Customer (/services/add?customerId=xyz)"]
    C --> E["Save Service"]
    D --> E
    E --> F["Allocates Human-Readable Ref # (YB-SRV-XXXXXX)"]
    F --> G["Uploads Attachments to Storage"]
    G --> H["Logs 'created' Service Activity"]
    H --> I["Redirects to Service Details (/services/:id)"]
```

---

## 3. Financial Calculation Flow

```mermaid
flowchart LR
    A["Base Service Charge (₹)"] --> D["Subtotal = Base + Additional"]
    B["Additional Charges (₹)"] --> D
    C["Discount Amount (₹)"] --> E["Discount check: Discount <= Subtotal"]
    D --> F["Total Amount = Subtotal - Discount"]
    E --> F
    F --> G["Ensure Total >= 0"]
```

- Validation Rule 1: Amounts must be non-negative ($\ge 0$).
- Validation Rule 2: $\text{Discount} \le \text{Base} + \text{Additional}$.
- Validation Rule 3: $\text{Total Amount} = \max(0, \text{Base} + \text{Additional} - \text{Discount})$.

