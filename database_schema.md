# Database Schema Design (SQL-Friendly)

This schema has been updated by thoroughly reviewing all data models and UI features currently present in the app (including Profile, Scan History, Habits, Daily Progress, and AI Coach Chat). We will implement this in Firestore using flat "root collections" (instead of deep subcollections) so it maps perfectly to PostgreSQL tables in the future.

## Schema Definition

### 1. Table: `users`
Stores all profile information and settings from `user_provider.dart` and `profile_screen.dart`.
* **Firestore Collection:** `/users/{uid}`

| Column / Field | Type | Description |
|---|---|---|
| `id` | VARCHAR (PK) | Firebase UID (Primary Key) |
| `email` | VARCHAR | User's email address |
| `display_name` | VARCHAR | User's name |
| `photo_url` | VARCHAR | URL of profile picture in Firebase Storage |
| `age` | INT | User's age (default 18) |
| `gender` | VARCHAR | Male, Female, etc. |
| `skin_type` | VARCHAR | Oily, Dry, Normal, etc. |
| `budget` | VARCHAR | Basic, Standard, Premium |
| `goals` | JSONB / Array| Array of target goals |
| `current_streak` | INT | Number of continuous days tasks were completed |
| `aura_score` | FLOAT | Global aura score |
| `is_pro` | BOOLEAN | Subscription status |
| `onboarding_completed`| BOOLEAN | Has the user finished onboarding? |
| `device_id` | VARCHAR | Unique device hardware ID (Android ID / iOS vendor ID) |
| `device_model` | VARCHAR | Device model name (e.g. `Samsung Galaxy S24`) |
| `device_os` | VARCHAR | OS version string (e.g. `Android 14`) |
| `device_brand` | VARCHAR | Device manufacturer (e.g. `Samsung`, `Apple`) |
| `block` | BOOLEAN | Is account blocked? (default false) |
| `block_date` | TIMESTAMP | When the account was blocked |
| `block_reason` | VARCHAR | Human-readable reason for blocking |
| `created_at` | TIMESTAMP | Account creation date |
| `updated_at` | TIMESTAMP | Last update date |

---

### 2. Table: `scan_history`
Stores the detailed AI analytics from face scans. This table is highly detailed to support advanced Lookmaxxing metrics.
* **Firestore Collection:** `/scan_history/{scan_id}`

| Column / Field | Type | Description |
|---|---|---|
| `id` | VARCHAR (PK) | Unique ID for the scan |
| `user_id` | VARCHAR (FK)| References `users.id` |
| `scan_date` | TIMESTAMP | Date and time of the scan |
| `overall_score` | FLOAT | Overall attractiveness score (1-10 or 1-100) |
| `aura_score` | FLOAT | Overall aura score |
| `symmetry_score` | FLOAT | Facial symmetry percentage |
| `golden_ratio_score`| FLOAT | How close the face is to the 1:1.618 ideal proportion |
| `cuteness_score` | FLOAT | Perception metric for cute features |
| `hotness_score` | FLOAT | Perception metric for hot/attractive features |
| `domination_score`| FLOAT | Perception metric for dominant/masculine/strong features |
| `jawline_details` | JSONB | e.g. `{ "sharpness": 85, "angle": "sharp" }` |
| `cheekbone_details`| JSONB | e.g. `{ "height": "high", "width": "prominent" }` |
| `eye_details` | JSONB | e.g. `{ "canthal_tilt": "positive", "spacing": "ideal" }` |
| `nose_details` | JSONB | e.g. `{ "width_ratio": "balanced" }` |
| `lip_details` | JSONB | e.g. `{ "ratio_upper_lower": "1:1.6" }` |
| `chin_details` | JSONB | e.g. `{ "projection": "strong", "shape": "square" }` |
| `skin_details` | JSONB | e.g. `{ "texture": 90, "tone_uniformity": 88 }` |
| `posture_score` | FLOAT | Posture alignment score |
| `rating` | VARCHAR | E.g., 'Legendary', 'Elite', 'Rising', 'Developing' |
| `highlights` | JSONB / Array | List of top positive string highlights |
| `suggestions` | JSONB / Array | Actionable suggestions based on weak areas (e.g. Mewing, Skincare routines, Face fat workouts) |
| `image_url` | VARCHAR | (Optional) URL of the scanned image |

---

### 3. Table: `habits`
Stores the library of available tasks/habits from `habit_provider.dart`.
* **Firestore Collection:** `/habits/{habit_id}`

| Column / Field | Type | Description |
|---|---|---|
| `id` | VARCHAR (PK) | Unique ID (e.g., 'm1', 'a1') |
| `title` | VARCHAR | Name of the habit |
| `description` | TEXT | Details about the habit |
| `time_of_day` | VARCHAR | 'morning', 'afternoon', 'night' |
| `icon` | VARCHAR | Material icon name |

---

### 4. Table: `daily_progress`
Tracks how many tasks a user completed on a specific day from `daily_progress_provider.dart`.
* **Firestore Collection:** `/daily_progress/{progress_id}`

| Column / Field | Type | Description |
|---|---|---|
| `id` | VARCHAR (PK) | Auto-generated ID |
| `user_id` | VARCHAR (FK)| References `users.id` |
| `date_key` | VARCHAR | E.g., '2026-06-01' (For easy SQL grouping) |
| `timestamp` | TIMESTAMP | Exact date and time |
| `completed_count`| INT | Number of tasks completed |
| `total_count` | INT | Total tasks assigned that day |

---

### 5. Table: `chat_history` (New)
Stores the chat messages between the user and the AI Coach from `coach_screen.dart`.
* **Firestore Collection:** `/chat_history/{message_id}`

| Column / Field | Type | Description |
|---|---|---|
| `id` | VARCHAR (PK) | Auto-generated ID for the message |
| `user_id` | VARCHAR (FK)| References `users.id` |
| `text` | TEXT | The content of the message |
| `is_user` | BOOLEAN | True if the user sent it, False if AI sent it |
| `timestamp` | TIMESTAMP | Date and time the message was sent |

---

## Migration Strategy (Firestore to PostgreSQL)

When you are ready to migrate to PostgreSQL:
1. **Data Export:** Export Firestore root collections as JSON arrays.
2. **Foreign Keys:** Because we are explicitly storing `user_id` in `scan_history`, `daily_progress`, and `chat_history`, mapping these JSON arrays to SQL tables with Foreign Key constraints will be seamless.
3. **No Deep Nesting:** We avoid Firestore sub-collections (e.g., `users/123/scan_history/456`), which are difficult to flatten into SQL tables. All data will be perfectly normalized.

---

### 6. Table: `devices` (New — Security)
Tracks devices used to create accounts. Used to detect and block suspicious multi-account activity.
* **Firestore Collection:** `/devices/{device_id}`

| Column / Field | Type | Description |
|---|---|---|
| `device_id` | VARCHAR (PK) | Unique hardware device ID |
| `model` | VARCHAR | Device model (e.g. `Redmi Note 12`) |
| `os` | VARCHAR | OS version (e.g. `Android 14`) |
| `brand` | VARCHAR | Device brand (e.g. `Xiaomi`) |
| `account_count` | INT | Number of accounts created from this device |
| `uids` | JSONB / Array | List of Firebase UIDs created on this device |
| `flagged` | BOOLEAN | True if suspicious activity detected |
| `flagged_at` | TIMESTAMP | When the device was flagged |
| `block_reason` | VARCHAR | Reason for blocking |
| `first_seen` | TIMESTAMP | When first account was created on device |
| `last_seen` | TIMESTAMP | When last account was created/updated on device |
