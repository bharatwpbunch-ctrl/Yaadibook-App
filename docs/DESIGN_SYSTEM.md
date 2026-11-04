# Yaadibook — Design System & Component Guidelines

## 1. Brand Identity & Personality

- **Name**: Yaadibook (યાદીબુક / यादीबुक) — from "Yaadi" (List / Memory / Record).
- **Personality**:
  - **Friendly & Approachable**: Non-intimidating for non-technical users and shop owners.
  - **Reliable & Professional**: Inspires trust with clean structure and crisp contrast.
  - **Simple & Fast**: Big touch targets, direct actions, minimal text entry.
  - **Modern & Lightweight**: Neutral background with fresh green highlights.

---

## 2. Design Tokens

### 2.1 Color Palette (`AppColors`)

| Token | Hex Value | Usage |
| :--- | :--- | :--- |
| `primary` | `#15803D` | Primary action buttons, active navigation, key brand accents |
| `primaryLight` | `#22C55E` | Highlights, badges |
| `primaryDark` | `#166534` | Text on green containers, high contrast elements |
| `primaryContainer` | `#DCFCE7` | Metric badges, active list item backgrounds |
| `onPrimary` | `#FFFFFF` | Text on primary buttons |
| `secondary` | `#0284C7` | Informational badges, secondary highlights |
| `secondaryContainer`| `#E0F2FE` | Tag backgrounds |
| `background` | `#F8FAFC` | Scaffold background (Slate 50) |
| `surface` | `#FFFFFF` | Card & dialog surfaces |
| `textPrimary` | `#0F172A` | Primary headings, body copy (Slate 900) |
| `textSecondary` | `#475569` | Subtitles, helper text (Slate 600) |
| `textMuted` | `#94A3B8` | Placeholder text, inactive icons (Slate 400) |
| `border` | `#E2E8F0` | Subtle card & input borders (Slate 200) |
| `success` | `#16A34A` | Completed status, positive actions |
| `warning` | `#D97706` | Pending status, near-due reminders |
| `error` | `#DC2626` | Overdue status, form validation errors |
| `whatsApp` | `#25D366` | Direct customer WhatsApp messaging button |

### 2.2 Spacing System (`AppSpacing`)

Based on an 8pt baseline grid with 4pt half-steps:
- `xxs`: 2px
- `xs`: 4px
- `sm`: 8px
- `md`: 12px
- `lg`: 16px (Standard screen & card padding)
- `xl`: 20px
- `xxl`: 24px
- `xxxl`: 32px
- `massive`: 48px
- **Minimum Touch Target**: 48px height across all buttons, touch cards, and inputs for easy field thumb usage.

### 2.3 Corner Radii (`AppRadii`)

- `xs`: 4px (Small tags)
- `sm`: 8px (Inner chips)
- `md`: 12px (Standard buttons, inputs, cards)
- `lg`: 16px (Dialogs, feature banners)
- `xl`: 24px (Bottom sheets)
- `pill`: 999px (Status badges, circular avatars)

---

## 3. Reusable Component Catalog

All components are located in `lib/core/widgets/`:

1. **`YbPrimaryButton`**: Full-width primary CTA with integrated circular progress indicator and icon support.
2. **`YbSecondaryButton`**: Bordered outline button for secondary actions.
3. **`YbTextInput`**: High-contrast text input with integrated label, error text, and prefix icon.
4. **`YbSearchInput`**: Instant search field with clear button and debounced callback support.
5. **`YbDropdown<T>`**: Form select component matching input field styling.
6. **`YbDatePickerField`**: Tap-to-pick date field formatted with localized date strings.
7. **`YbCustomerCard`**: Contact card with initial avatar, phone, address, and quick Call/WhatsApp triggers.
8. **`YbServiceCard`**: Service summary card displaying title, customer, date, amount (₹), and status badge.
9. **`YbReminderCard`**: Due date card highlighting upcoming or overdue follow-ups.
10. **`YbStatusBadge`**: Pill badge supporting `active`, `pending`, `completed`, `cancelled`, and `overdue`.
11. **`YbEmptyState`**: Empty list placeholder with custom illustration icon, message, and action CTA.
12. **`YbLoadingState`**: Centered brand progress spinner with optional loading message.
13. **`YbErrorState`**: Error view with retry action button.
14. **`YbConfirmDialog`**: Standardized confirmation dialog for critical or destructive actions.
15. **`YbBottomSheet`**: Modal bottom sheet with drag handle, title, and close action.
16. **`YbSectionHeader`**: Clean section header with title, subtitle, and trailing "View All" link.

