# Yaadibook — Supabase Setup & Operations Guide

This guide details the procedure for configuring, developing with, and deploying Yaadibook's Supabase backend.

---

## 1. Prerequisites & Account Setup

1. **Create Supabase Account**: Sign up at [supabase.com](https://supabase.com).
2. **Create New Project**:
   - Organization: Your organization or personal account.
   - Project Name: `yaadibook-dev` (or `yaadibook-prod` for production).
   - Database Password: Create a strong password and save it in a secure password manager.
   - Region: Select **Mumbai (ap-south-1)** for lowest latency across Gujarat and India.

---

## 2. Environment Variables Configuration

Copy `.env.example` to `.env` in the project root:

```powershell
Copy-Item .env.example .env
```

Set your project values in `.env`:

```env
APP_ENV=dev
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Passing Configuration to Flutter:
```powershell
# Development Run with --dart-define
flutter run -d chrome `
  --dart-define=APP_ENV=dev `
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

---

## 3. Supabase CLI Setup & Commands

The project is initialized with Supabase CLI (`supabase/config.toml`).

### 3.1 Verification
```powershell
supabase --version
# Expected: 3.x.x
```

### 3.2 Linking to Remote Project
```powershell
# Login to Supabase CLI
supabase login

# Link your project using its Project Ref ID (found in project settings)
supabase link --project-ref your-project-ref-id
```

### 3.3 Deploying Migrations to Remote Project
```powershell
# Push all pending migrations to the linked remote database
supabase db push
```

### 3.4 Local Development with Docker (Optional)
If Docker Desktop is installed:
```powershell
# Start local Supabase containers (PostgreSQL, Studio, Auth, Storage)
supabase start

# Apply migrations locally
supabase db reset

# Seed local database
# Seed data in supabase/seed.sql is automatically loaded by supabase db reset
```

---

## 4. Migration Files Catalog

All migrations reside in `supabase/migrations/`:

| Migration File | Contents |
| :--- | :--- |
| `20261104170001_core_schema.sql` | Schema foundations, extensions, `profiles`, `businesses`, RLS & security functions |
| `20261104170002_crm_and_services.sql` | `customers`, `customer_addresses`, `equipment`, `service_entries`, composite FKs & RLS |
| `20261104170003_maintenance_and_amc.sql` | `maintenance_plans`, `maintenance_occurrences`, `amc_contracts`, `amc_reminder_schedules` |
| `20261104170004_reminders_and_communication.sql` | `reminders`, `communication_logs`, `notification_preferences`, `business_settings`, `audit_logs`, `create_business_workspace` RPC |
| `20261104170005_storage_and_security.sql` | Storage buckets (`business-assets`, `customer-attachments`, `service-attachments`, `amc-documents`) & storage RLS |

---

## 5. Seed Data Execution

To load sample test data without real personal info:

```powershell
# Against local instance:
supabase db reset

# Against remote dev project via psql or Supabase SQL Editor:
# Run the contents of supabase/seed.sql in the Supabase Dashboard SQL Editor
```

---

## 6. Type Generation Workflow

When schema modifications are introduced, generate updated TypeScript/Dart schema types:

```powershell
# Generate TypeScript definitions (used for Edge Functions)
supabase gen types typescript --linked > supabase/functions/_shared/database.types.ts
```

