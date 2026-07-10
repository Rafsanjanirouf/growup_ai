# Product Requirements Document (PRD): GrowUp AI Admin Dashboard & Analytics

## 1. Document Information
- **Product Name:** GrowUp AI Admin Dashboard
- **Document Status:** Draft / Review
- **Target Audience:** Internal Team (Admins, Product Managers, Customer Support)
- **Objective:** To provide a comprehensive web-based admin panel for monitoring user activity, managing business/user accounts, tracking subscription revenue, and analyzing AI feature usage.

---

## 2. Executive Summary
The GrowUp AI Admin Dashboard is a centralized command center designed to give the internal team full visibility and control over the application's ecosystem. It focuses heavily on **Analytics**, providing actionable insights into user retention, habit tracking engagement, AI feature utilization (e.g., AI Hair Style), and revenue streams.

---

## 3. Goals & Key Objectives
- **Data-Driven Insights:** Provide real-time and historical analytics on app usage, retention, and AI adoption.
- **Revenue Tracking:** Monitor subscription conversions, recurring revenue, and churn rates.
- **User Management:** Enable customer support to resolve issues, manage user accounts, and verify Business Accounts.
- **Content & System Management:** Allow admins to manage AI prompts, habit categories, and system notifications.

---

## 4. User Personas (Admin Panel Users)
1. **Super Admin:** Full access to all modules, including billing, user roles, and system settings.
2. **Data Analyst / Product Manager:** Access to all analytics, usage metrics, and export features (Read-only for sensitive data).
3. **Customer Support:** Access to user profiles, issue resolution, subscription status, and basic activity logs.

---

## 5. Core Features & Requirements

### 5.1. Authentication & Security
- Secure Login (Email/Password + Two-Factor Authentication).
- Role-Based Access Control (RBAC) to restrict access based on user persona.
- Session timeout and activity logging for security audits.

### 5.2. Dashboard Overview (The "At a Glance" Page)
- **Top KPIs (Cards):**
  - Total Active Users (DAU, MAU).
  - Total Revenue / MRR (Monthly Recurring Revenue).
  - Total Subscriptions (Active vs. Canceled).
  - Number of Active Business Accounts.
  - AI Generation Count (Today/This Week).
- **Recent Activity Feed:** Latest sign-ups, recent subscriptions, and system alerts.

### 5.3. Comprehensive Analytics Module
This is the core of the dashboard, visualized via charts (Line, Bar, Pie) and data tables.

#### A. User Analytics
- **Acquisition & Retention:** New users vs. Returning users over time.
- **Demographics:** Geographic location, device OS (Android/iOS), app version.
- **Engagement:** Average session length, most visited screens.

#### B. AI Feature Usage Analytics
- **Feature Breakdown:** Usage stats for specific AI features (e.g., AI Hair Style vs. General AI Recommendations).
- **Generation Metrics:** Total images/recommendations generated per user.
- **Error Rates:** Number of failed AI generations or API timeouts.

#### C. Habit Tracking Analytics
- **Popular Habits:** Most frequently added habits by users.
- **Completion Rates:** Average streak lengths and habit completion percentages.
- **Drop-off Points:** Where users fail to maintain their habits.

#### D. Revenue & Subscription Analytics (Financials)
- **Conversion Funnel:** Free -> Trial -> Paid user conversion rates.
- **Subscription Tiers:** Breakdown of users on Free, Basic, Pro, etc.
- **Churn Rate:** Monthly percentage of users canceling subscriptions.
- **LTV & CAC:** Customer Lifetime Value vs. Customer Acquisition Cost (if integrated with marketing data).

### 5.4. User & Business Account Management
- **User List:** Search, filter, and sort all users (by email, ID, subscription status, join date).
- **User Detail View:**
  - Basic Info, Subscription Status, Device Info.
  - Activity Log (recent logins, habits created, AI generated).
  - Action Buttons: Reset password, Suspend account, Revoke/Grant premium access manually (for support).
- **Business Account Management:**
  - Verification queue for newly registered Business Accounts.
  - View business profiles, associated services, and verification documents.
  - Approve, reject, or request more information.

### 5.5. Content & System Management
- **Push Notifications:** Compose and send targeted push notifications to segments (e.g., "All Free Users", "Users inactive for 7 days").
- **App Version Control:** Force update toggles, maintenance mode switch.
- **AI Configuration (Optional):** Tweak AI prompts, set daily generation limits for free users.

---

## 6. Technical & Non-Functional Requirements

### 6.1. Tech Stack Recommendations
- **Frontend Framework:** Flutter Web, React.js, or Vue.js (for fast dashboard development).
- **UI Library:** Material UI, Ant Design, or Tailwind CSS (for clean, responsive data tables and charts).
- **Charting Library:** Recharts, Chart.js, or FL Chart (if using Flutter).
- **Backend/Database Integration:** Firebase Admin SDK / Supabase API / Custom REST APIs connecting to the existing database.

### 6.2. Performance & Exporting
- **Data Export:** All analytics tables must be exportable to `.CSV` and `.PDF`.
- **Date Filtering:** Every analytics page must have a global date picker (Today, Last 7 Days, Last 30 Days, Custom Range).
- **Loading Speed:** Dashboard queries should be optimized; utilize pagination for user lists.

---

## 7. Database & Architecture (Firestore Schema)

The Admin Dashboard interacts with the following Firestore collections. All paths, field names, and data types are extracted directly from the live production codebase.

---

### 📁 Collection: `users` — `/users/{uid}`
**Purpose:** Single source of truth for all user accounts. Created on first login and updated on every session.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Firebase Auth UID (same as document ID) |
| `email` | `string` | User's email address |
| `display_name` | `string` | Display name from Auth or onboarding |
| `photo_url` | `string` | Profile photo URL (Google/Firebase Storage) |
| `auth_provider` | `string` | `"auth-- email"`, `"google.com"`, etc. |
| `age` | `number` | User age (default: 18) |
| `gender` | `string` | `"Male"` / `"Female"` / etc. |
| `skin_type` | `string` | e.g. `"Oily"`, `"Dry"`, `"Combination"` |
| `skinType` | `string` | Duplicate field (legacy — same as `skin_type`) |
| `budget` | `string` | e.g. `"Basic"`, `"Mid-Range"`, `"Premium"` |
| `goals` | `array<string>` | e.g. `["Glowing Skin", "Jawline"]` |
| `problems` | `array<string>` | e.g. `["Acne", "Dark Circles"]` |
| `current_streak` | `number` | Current habit streak count |
| `last_streak_date` | `string` | Last date streak was incremented (yyyy-MM-dd) |
| `aura_score` | `number` | Latest aura score from face scan (0–100) |
| `is_pro` | `boolean` | **Premium flag** — `true` if user has active subscription |
| `onboarding_completed` | `boolean` | Whether user finished onboarding flow |
| `profileCompleted` | `boolean` | Whether profile setup is complete |
| `completedAt` | `timestamp \| null` | When profile was completed |
| `language` | `string` | e.g. `"English"`, `"Bangla"` |
| `languageLocale` | `string` | e.g. `"en-US"`, `"bn-BD"` |
| `device_id` | `string` | Hardware device ID (used for fraud detection) |
| `device_model` | `string` | e.g. `"Samsung Galaxy S21"` |
| `device_os` | `string` | e.g. `"Android 13"`, `"iOS 17.0"` |
| `device_brand` | `string` | e.g. `"Samsung"`, `"Apple"` |
| `block` | `boolean` | `true` = account is blocked |
| `block_date` | `timestamp \| null` | When account was blocked |
| `block_reason` | `string` | Reason for block (e.g., multi-account violation) |
| `backup_enabled` | `boolean` | Whether user enabled cloud backup |
| `backup_consent_shown` | `boolean` | Whether consent dialog was shown |
| `backup_consent_at` | `timestamp` | When consent was given |
| `backup_updated_at` | `timestamp` | Last backup config update |
| `created_at` | `timestamp` | Account creation time |
| `updated_at` | `timestamp` | Last profile update time |

**🖥️ Admin Dashboard Use:**
- **User Management** → Search, filter, view all user profiles
- Grant/revoke `is_pro` manually (for support/gifting)
- Block/unblock accounts via `block`, `block_reason`
- View demographics: `age`, `gender`, `skin_type`, `goals`
- Device fraud detection: `device_id`, `block`

---

### 📁 Collection: `subscription` — `/subscription/{uid}`
**Purpose:** Custom subscription override managed by admin. Used when a subscription is gifted or granted outside RevenueCat (e.g., influencer deals, support tickets).

| Field | Type | Description |
|-------|------|-------------|
| `custom_subscription` | `boolean` | `true` = admin-granted subscription active |
| `subscription_category` | `string` | `"Gift"`, `"Custom"`, `"Trial"`, `"Purchase"` |
| `custom_sub_start_date` | `timestamp` | When the custom subscription starts |
| `custom_sub_end_date` | `timestamp \| null` | Expiry date; `null` = lifetime grant |

**🖥️ Admin Dashboard Use:**
- **Premium Management** → Grant/revoke premium access for specific users
- Set subscription type: Gift, Custom, Trial, Lifetime
- Set expiry date for time-limited grants
- View all users with custom subscriptions (not via RevenueCat)

> **Note:** Production subscriptions are managed via **RevenueCat** (`entitlement: "MobTeam Pro"`, `offering: "New Offer 2"`). This collection only handles **admin overrides**.

---

### 📁 Collection: `devices` — `/devices/{device_id}`
**Purpose:** Tracks device hardware IDs and linked accounts. Enforces the **max 2 accounts per device** anti-fraud policy.

| Field | Type | Description |
|-------|------|-------------|
| `device_id` | `string` | Hardware device ID (document ID) |
| `model` | `string` | Device model name |
| `os` | `string` | OS version string |
| `brand` | `string` | Device brand |
| `account_count` | `number` | Total accounts registered from this device |
| `uids` | `array<string>` | All UIDs linked to this device |
| `flagged` | `boolean` | `true` = auto-flagged for multi-account abuse |
| `flagged_at` | `timestamp` | When device was flagged |
| `block_reason` | `string` | Reason (e.g., `"Multiple accounts detected..."`) |
| `first_seen` | `timestamp` | First account created from this device |
| `last_seen` | `timestamp` | Most recent activity |

**🖥️ Admin Dashboard Use:**
- **Anti-Fraud Panel** → View `flagged` devices, `account_count > 2`
- Click into a device to see all linked `uids`
- Manually flag/unflag devices
- View `first_seen` / `last_seen` for activity timeline

---

### 📁 Collection: `scan_history` — `/scan_history/{scan_id}`
**Purpose:** Full AI face scan results. Each document is one scan session per user. The primary AI analytics data source.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique scan ID (document ID) |
| `user_id` | `string` | Linked Firebase UID |
| `scan_date` | `timestamp` | Date/time of the scan |
| `overall_score` | `number` | Overall attractiveness score (0–100) |
| `aura_score` | `number` | Aura score (stored as 1–10 scale) |
| `symmetry_score` | `number` | Facial symmetry score |
| `golden_ratio_score` | `number` | Golden ratio score |
| `cuteness_score` | `number` | Cuteness/softness score |
| `hotness_score` | `number` | Attractiveness/hotness score |
| `domination_score` | `number` | Dominance/strong features score |
| `posture_score` | `number` | Posture quality score |
| `rating` | `string` | `"Legendary"` / `"Elite"` / `"Rising"` / `"Developing"` |
| `jawline_details` | `map` | Nested jawline analysis data |
| `cheekbone_details` | `map` | Nested cheekbone analysis data |
| `eye_details` | `map` | Nested eye analysis (`alertness`, etc.) |
| `nose_details` | `map` | Nested nose analysis data |
| `lip_details` | `map` | Nested lip analysis data |
| `chin_details` | `map` | Nested chin analysis data |
| `skin_details` | `map` | Nested skin analysis (`texture`, etc.) |
| `highlights` | `array<string>` | Top AI-generated insights for user |
| `suggestions` | `array<string>` | AI improvement recommendations |
| `image_url` | `string` | Firebase Storage URL (empty if backup disabled) |
| `image_backup_enabled` | `boolean` | Whether user allowed image backup |
| `week_index` | `number` | Sequential week number from user's first scan |
| `created_at` | `timestamp` | Server-side write time |

**🖥️ Admin Dashboard Use:**
- **AI Feature Analytics** → Total scans per day/week/month
- Score distribution charts (average aura, symmetry, etc.)
- Rating breakdown: % Legendary vs Elite vs Rising vs Developing
- Per-user scan history in User Detail View

---

### 📁 Collection: `habits` — `/habits/{habit_id}`
**Purpose:** Global/user habit library. Each document represents one habit/task entry.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique habit ID (document ID) |
| `title` | `string` | Habit name (e.g., `"Hydration Kickstart 💧"`) |
| `description` | `string` | Detailed description |
| `time_of_day` | `string` | `"morning"` / `"noon"` / `"evening"` / `"night"` |
| `icon` | `string` | Material icon name (e.g., `"water_drop"`) |
| `user_id` | `string` | UID if custom habit; absent/empty for global habits |
| `isCustom` | `boolean` | `true` = user-created custom task |
| `frequency` | `string` | `"daily"` / `"weekly"` / `"monthly"` |
| `targetCount` | `number` | How many times to complete per period |

**🖥️ Admin Dashboard Use:**
- **Content Management** → View/add/edit global habit templates
- Analytics: Which habits are most popular (by count in `daily_progress`)

---

### 📁 Collection: `daily_progress` — `/daily_progress/{userId_dateKey}`
**Purpose:** Per-user daily habit completion tracking. Document ID is composite: `{uid}_{yyyy-MM-dd}`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Composite ID: `{uid}_{dateKey}` |
| `user_id` | `string` | Firebase UID |
| `date_key` | `string` | Date string: `"2026-06-18"` |
| `timestamp` | `timestamp` | Server write time |
| `completed_count` | `number` | Number of tasks completed that day |
| `total_count` | `number` | Total tasks assigned that day |

**🖥️ Admin Dashboard Use:**
- **Habit Analytics** → Average completion rate globally
- User engagement heatmaps (days with activity)
- Drop-off analysis: users with 0 completion for N days

---

### 📁 Collection: `coach_usage` — `/coach_usage/{userId_dateKey}`
**Purpose:** Tracks AI Coach (chat) token and message usage per user per day. Document ID is composite: `{uid}_{yyyy-MM-dd}`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Composite ID: `{uid}_{dateKey}` |
| `user_id` | `string` | Firebase UID |
| `date_key` | `string` | Date string: `"2026-06-18"` |
| `tokens_used` | `number` | Total Gemini tokens consumed (incremented) |
| `message_count` | `number` | Total messages sent (incremented) |
| `last_used_at` | `timestamp` | Last coach message time |

**🖥️ Admin Dashboard Use:**
- **AI Coach Analytics** → Daily token consumption, MAU for coach feature
- Identify heavy users approaching daily limits
- Monitor cost trends (tokens ≈ API cost)

---

### 📁 Collection: `generation_usage` — `/generation_usage/{userId_periodKey}`
**Purpose:** Tracks AI image generation usage. Supports both **daily** (image-to-text) and **monthly** (image generation) limits. Document ID is composite: `{uid}_{yyyy-MM-dd}` or `{uid}_{yyyy-MM}`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Composite ID |
| `user_id` | `string` | Firebase UID |
| `date_key` | `string` | Daily key: `"2026-06-18"` (for image-to-text) |
| `month_key` | `string` | Monthly key: `"2026-06"` (for image generation) |
| `image_to_text_count` | `number` | Daily image-to-text API calls (limit from `app_settings`) |
| `image_generation_count` | `number` | Monthly AI image generation count (limit from `app_settings`) |
| `last_used_at` | `timestamp` | Last generation time |

**🖥️ Admin Dashboard Use:**
- **AI Generation Analytics** → Total outfit/hairstyle generations per day
- Monitor daily/monthly limits; identify abuse patterns
- Visualize free vs premium generation counts

---

### 📁 Collection: `daily_metrics` — `/daily_metrics/{dateKey}`
**Purpose:** Aggregated global daily activity metrics. Written to automatically every time a user uses the AI Coach. Document ID is the date string `yyyy-MM-dd`.

| Field | Type | Description |
|-------|------|-------------|
| `date_key` | `string` | Date string: `"2026-06-18"` |
| `total_tokens` | `number` | Sum of all tokens used across all users that day |
| `total_inputs` | `number` | Sum of all AI coach messages sent that day |
| `active_users` | `array<string>` | Array of unique UIDs who used the coach |
| `updated_at` | `timestamp` | Last aggregation update time |

**🖥️ Admin Dashboard Use:**
- **Dashboard Overview KPIs** → DAU (length of `active_users`), daily token cost
- Line charts: token usage trends over time
- Identify peak usage days for infrastructure scaling

---

### 📁 Collection: `outfit_history` — `/outfit_history/{id}`
**Purpose:** Stores AI outfit analysis history for each user.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique ID (document ID) |
| `user_id` | `string` | Firebase UID |
| `date` | `timestamp` | Date of outfit analysis |
| `image_url` | `string` | Firebase Storage URL of uploaded outfit image |
| `full_data` | `map` | Full Gemini AI response payload |
| `created_at` | `timestamp` | Server write time |

**🖥️ Admin Dashboard Use:**
- **AI Feature Analytics** → Outfit AI usage count, trends
- Moderate flagged or inappropriate uploaded images

---

### 📁 Collection: `hairstyle_history` — `/hairstyle_history/{id}`
**Purpose:** Stores AI hairstyle generation history for each user (premium feature).

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique ID (document ID) |
| `user_id` | `string` | Firebase UID |
| `date` | `timestamp` | Date of hairstyle generation |
| `image_url` | `string` | Original uploaded photo URL |
| `generated_image_url` | `string` | AI-generated hairstyle image URL (premium) |
| `full_data` | `map` | Full Gemini/AI response payload |
| `created_at` | `timestamp` | Server write time |

**🖥️ Admin Dashboard Use:**
- **AI Feature Analytics** → Hairstyle generation count (premium-only metric)
- Correlate `generated_image_url` population with `is_pro` user count

---

### 📁 Collection: `app_settings` — `/app_settings/limits`
**Purpose:** Global configuration document. Controls AI feature rate limits for all users. Admin-writable.

| Field | Type | Description |
|-------|------|-------------|
| `daily_chat_tokens` | `number` | Max Gemini tokens per user per day for AI Coach (default: `50000`) |
| `daily_image_to_text_limit` | `number` | Max image-to-text calls per user per day (default: `50`) |
| `monthly_image_generation_limit` | `number` | Max AI image generations per user per month (default: `5`) |

**🖥️ Admin Dashboard Use:**
- **System Management** → Edit rate limits without code deployment
- Adjust limits dynamically for free vs premium tiers
- Emergency throttling during high API cost periods

---

### 📁 Subcollection: `users/{uid}/tasks` — `/users/{uid}/tasks/{dateKey}`
**Purpose:** Per-user daily task list synced to Firestore. Document ID is the date string `yyyy-MM-dd`.

| Field | Type | Description |
|-------|------|-------------|
| `date` | `string` | Date key: `"2026-06-18"` |
| `items` | `array<map>` | Array of task objects (see Habit model for fields) |
| `lastUpdated` | `timestamp` | Last sync time |

**Each item in `items` array contains:**

| Sub-field | Type | Description |
|-----------|------|-------------|
| `id` | `string` | Habit ID |
| `title` | `string` | Task title |
| `timeOfDay` | `string` | `"morning"` / `"noon"` / `"evening"` / `"night"` |
| `frequency` | `string` | `"daily"` / `"weekly"` / `"monthly"` |
| `isCompleted` | `boolean` | Completion status |
| `icon` | `string` | Material icon name |
| `description` | `string` | Task description |
| `isCustom` | `boolean` | User-created task flag |
| `targetCount` | `number` | Required completions |
| `currentCount` | `number` | Current completions |

**🖥️ Admin Dashboard Use:**
- **User Detail View** → See a user's exact daily task list for any date
- Debug habit sync issues for support tickets

---

### 📊 Collection Relationship Overview

```
users/{uid}
  ├── subscription/{uid}          ← Admin premium override
  ├── devices/{device_id}         ← Anti-fraud, links back to users
  ├── users/{uid}/tasks/{date}    ← Daily task subcollection
  │
scan_history/{scan_id}            ← AI face scan (user_id FK)
habits/{habit_id}                 ← Global + user habit library
daily_progress/{uid_date}         ← Habit completion tracking (user_id FK)
coach_usage/{uid_date}            ← AI Coach token usage (user_id FK)
generation_usage/{uid_period}     ← Image generation usage (user_id FK)
daily_metrics/{date}              ← Global aggregated daily stats
outfit_history/{id}               ← AI outfit analysis (user_id FK)
hairstyle_history/{id}            ← AI hairstyle generation (user_id FK)
app_settings/limits               ← Global rate limit config (Admin-only write)
```

---

## 8. Future Enhancements (Phase 2)
- **A/B Testing Dashboard:** Interface to manage and view results of app A/B tests.
- **Predictive Analytics:** AI-driven predictions on user churn based on usage patterns.
- **Feedback & Bug Reports Hub:** Centralized place to view in-app user feedback and crash reports.
- **PostgreSQL Migration:** Built-in tools to export flattened Firestore data seamlessly to a structured SQL database.

---

## 9. Approval & Sign-off
- **Prepared By:** Antigravity (AI Assistant)
- **Date:** 2026-06-18
- **Reviewer:** [User / Stakeholders]
- **Status:** Pending Review
