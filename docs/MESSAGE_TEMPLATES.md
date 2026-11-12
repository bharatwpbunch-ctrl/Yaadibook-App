# Yaadibook — Reusable Message Templates

## 1. Overview
Yaadibook provides customizable, multilingual message templates to speed up customer communication across service updates, maintenance reminders, AMC renewal drives, and payment follow-ups.

---

## 2. Dynamic Placeholder Placeholders

Templates support mustache-style double bracket variables:

| Variable | Description | Sample Replacement |
|---|---|---|
| `{{customer_name}}` | Full name of the customer | "Rahul Shah" |
| `{{business_name}}` | Registered business name | "Bharat CCTV Solutions" |
| `{{business_phone}}` | Contact phone number of the business | "+91 98250 12345" |
| `{{service_title}}` | Title of the service entry | "Camera Installation" |
| `{{service_reference}}`| Formatted service number | "SRV-2026-089" |
| `{{service_status}}` | Current status of the service | "Completed" |
| `{{maintenance_date}}`| Due date of maintenance visit | "12 Nov 2026" |
| `{{amc_end_date}}` | Expiration date of AMC contract | "31 Dec 2026" |
| `{{amount}}` | Due payment or contract amount | "2,500" |

---

## 3. Standard Seeded Multilingual Templates

### English (en)
- **Service Update**: "Hello {{customer_name}}, this is {{business_name}}. Update on your service {{service_title}} (Ref: {{service_reference}}): Status is now {{service_status}}. For questions, contact {{business_phone}}."
- **AMC Renewal**: "Dear {{customer_name}}, your AMC contract with {{business_name}} expires on {{amc_end_date}}. Renew today to ensure uninterrupted service. Call {{business_phone}}."
- **Maintenance**: "Hello {{customer_name}}, your scheduled maintenance visit is due on {{maintenance_date}}. Our technician will visit as planned. Regards, {{business_name}} ({{business_phone}})."
- **Payment Due**: "Dear {{customer_name}}, a pending payment of ₹{{amount}} is due for service {{service_reference}}. Kindly settle at your earliest convenience. Thank you, {{business_name}}."

### Gujarati (gu)
- **સર્વિસ અપડેટ**: "નમસ્તે {{customer_name}}, {{business_name}} તરફથી. આપની સર્વિસ {{service_title}} (નંબર: {{service_reference}}) નું સ્ટેટસ {{service_status}} છે. વધુ માહિતી માટે સંપર્ક કરો: {{business_phone}}."
- **AMC રીન્યુઅલ**: "આદરણીય {{customer_name}}, {{business_name}} સાથે આપનો AMC કરાર {{amc_end_date}} ના રોજ પૂર્ણ થાય છે. અવિરત સેવા માટે રિન્યુ કરાવો. સંપર્ક: {{business_phone}}."

### Hindi (hi)
- **सेवा स्थिति अपडेट**: "नमस्ते {{customer_name}}, {{business_name}} से सूचना. आपकी सेवा {{service_title}} (संदर्भ: {{service_reference}}) की स्थिति अब {{service_status}} है. संपर्क करें: {{business_phone}}."
- **AMC नवीनीकरण**: "प्रिय {{customer_name}}, {{business_name}} के साथ आपका AMC अनुबंध {{amc_end_date}} को समाप्त हो रहा है. निरंतर सेवा के लिए आज ही नवीनीकरण करें. संपर्क: {{business_phone}}."

