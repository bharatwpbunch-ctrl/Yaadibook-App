# Yaadibook — Customer Communication System

## 1. Architecture Overview

Yaadibook's Customer Communication System enables local Indian service businesses to communicate effectively with their customers via **WhatsApp** and **SMS**. The system supports both **manual device-based messaging** and **automated API gateways**, governed by strict truthfulness in logging and telecom compliance.

```
+-------------------------------------------------------------------------------+
|                             Customer Communication                             |
+-------------------------------------------------------------------------------+
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------------+                         +-------------------------------+
|  1. Manual Native Dispatch    |                         |   2. Automated Cloud API      |
|  - WhatsApp (wa.me / deep)   |                         |   - Meta WhatsApp Cloud API   |
|  - Device SMS (sms: URI)      |                         |   - Indian DLT SMS Gateways   |
|  - Pre-filled message text    |                         |   - Bulk Messaging Campaigns  |
|  - Zero per-message cost      |                         |   - Delivery webhook receipts |
|  - Logged as: 'opened_in_app' |                         |   - Logged: submitted/deliv.  |
+-------------------------------+                         +-------------------------------+
```

---

## 2. Strict Truthfulness Principle

A core architectural principle of Yaadibook:
> **The app must never record a manual WhatsApp or SMS action as "sent" or "delivered".**

When an owner taps "Open in WhatsApp" or "Open in SMS":
- The device OS opens the corresponding app with the number and message pre-filled.
- Since external apps do not return delivery confirmation to the host application, Yaadibook records the log with status:
  ```json
  "status": "opened_in_app"
  ```
- Only official gateway integrations (Meta Cloud API, SMS gateway webhooks) may advance statuses to `submitted`, `delivered`, `read`, or `failed`.

---

## 3. Communication Lifecycle & Status States

| Status | Meaning | Source |
|---|---|---|
| `draft` | Message or campaign in composition | UI Composer |
| `opened_in_app` | Opened in native WhatsApp or SMS app on owner's phone | Manual Dispatch |
| `queued` | Queued in database for batch processor | Campaign Scheduler |
| `submitted` | Accepted by Meta Cloud API or SMS Gateway | Edge Function |
| `accepted` | Accepted by telecom carrier | Gateway Webhook |
| `delivered` | Successfully reached customer device | Gateway Webhook |
| `read` | Read by customer (WhatsApp blue ticks) | Meta Webhook |
| `failed` | Delivery failed or bounced | Provider Webhook / Error |
| `cancelled` | Cancelled before dispatch | Business Owner |

---

## 4. Contextual Integration Touchpoints

1. **Customer Details Screen**: Quick call, WhatsApp, and composer shortcuts; consent preferences; customer communication timeline.
2. **Service Details Screen**: "Send Status Update to Customer" button prefilling reference number and status.
3. **Maintenance Occurrence Screen**: "Send Maintenance Reminder" button prefilling scheduled visit date.
4. **AMC Contract Screen**: "Send Renewal Notice" button prefilling contract expiration date and amount.
5. **Reminders & Tasks**: Call and WhatsApp shortcuts on reminder cards.

