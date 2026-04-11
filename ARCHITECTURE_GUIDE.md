# 🏗️ GrowUp AI - Architecture & Code Organization

## 📐 App Architecture

```
GrowUp AI (Material 3 + Riverpod)
│
├── Core Systems
│   ├── Theme System (Dark Mode)
│   │   ├── Colors (Violet, Cyan, Navy)
│   │   ├── Typography (Roboto + Open Sans)
│   │   └── Components (Buttons, Cards, Header)
│   │
│   ├── State Management (Riverpod)
│   │   └── UserStatsProvider (Coins, Streaks, Score)
│   │
│   └── Services
│       ├── Camera Service
│       ├── Analytics Service
│       └── API Service (Firebase)
│
└── Feature Modules
    ├── Onboarding (Entry Flow)
    │   ├── SplashScreen (3s animation)
    │   ├── OnboardingScreen (4 pages)
    │   ├── AuthScreen (Google + Guest)
    │   └── GoalSelectionScreen (Multi-select)
    │
    ├── Home (Main Navigation)
    │   └── MainNavigationScreen (Bottom nav)
    │
    ├── Dashboard (Hub)
    │   ├── Daily Tasks
    │   ├── Stats Display
    │   ├── Programs Preview
    │   └── AI Coach Access
    │
    ├── Face Scan (Analysis)
    │   ├── FaceScanScreen (Camera)
    │   ├── AnalyzingScanScreen (Processing)
    │   └── FaceScoreScreen (Results)
    │
    ├── Programs (Content)
    │   ├── ProgramsScreen (List)
    │   ├── ProgramDetailScreen (Progress)
    │   └── TaskListScreen (Daily)
    │
    ├── Assistant (AI Chat)
    │   ├── AssistantScreen (Chat interface)
    │   └── MessageBubbles (UI)
    │
    ├── Profile (User Account)
    │   ├── ProfileScreen (Stats)
    │   └── SettingsScreen (Preferences)
    │
    ├── Analytics (Tracking)
    │   ├── WeeklyReportScreen (Charts)
    │   └── StatsScreen (Metrics)
    │
    ├── AI Tools (Premium)
    │   ├── CelebrityFaceMatch
    │   ├── BeardStyleAdvisor
    │   └── HairColorAdvisor
    │
    └── Monetization (Revenue)
        ├── PremiumPaywall
        └── CoinStore
```

---

## 🔗 Data Flow (User Retention Loop)

```
Day 1 User Journey:
│
├─→ SplashScreen (3s)
│   ↓
├─→ OnboardingScreen (4 pages)
│   ↓
├─→ AuthScreen (Google/Guest)
│   ↓
├─→ GoalSelectionScreen (Multi-select)
│   ↓
└─→ Dashboard Hub
    ├─→ See 5 Daily Tasks
    ├─→ See Streak Counter (Day 1)
    ├─→ See Coin Balance (0 coins)
    ├─→ See User Level (1)
    ├─→ Complete Tasks (+10, +15, +20 coins)
    ├─→ Face Scan (+25 coins)
    ├─→ End of Day: 70 coins, Streak: 1
    │
Day 2+ User Journey:
    ├─→ See Motivation Message ("Great Progress! 💪")
    ├─→ See Streak Counter (Day 2, Day 3, etc.)
    ├─→ See Coin Balance (accumulated)
    ├─→ Complete Tasks + Scan
    ├─→ Unlock Program
    └─→ Eventually Buy Premium
```

---

## 🎮 Gamification Architecture

### Coin Economy
```
Earnings:
  └─ Daily Tasks: 10-50 coins each (5 tasks = 100+ coins)
  └─ Face Scan: 25 coins
  └─ Program Completion: 100-500 coins
  └─ Achievements: 25-100 coins
  └─ Daily Login: 5 coins

Spending:
  └─ Premium Features: 500-1000 coins
  └─ Attribute Boosts: 50-200 coins
  └─ Premium Tools: 100-300 coins
```

### Streak System
```
Day 1: Complete 1 task → Streak: 1 🔥
Day 2: Complete 1 task → Streak: 2 🔥🔥
Day 7: Complete 1 task → Streak: 7 🔥🔥🔥🔥🔥🔥🔥 (Bonus!)
Day 30: Complete 1 task → Streak: 30 🏆 (Badge Unlock!)
Miss a day: Streak resets to 0

Rewards:
  └─ Day 7: +50 bonus coins
  └─ Day 14: +100 bonus coins
  └─ Day 30: Badge + 200 bonus coins
  └─ Day 60: Badge + 500 bonus coins
```

### Level System
```
Level = Face Score / 20
  Level 1: Score 0-19
  Level 2: Score 20-39
  Level 3: Score 40-59
  Level 4: Score 60-79
  Level 5: Score 80-99
  Level 6: Score 100+

Unlocks:
  Level 2: Advanced programs
  Level 3: AI tools
  Level 4: Premium features
  Level 5: Community features
  Level 6: All features
```

---

## 🎨 Component Hierarchy

### Universal AppHeader (120px)
```
┌─────────────────────────────────────┐
│  ← Title (20px, bold)               │  56px AppBar
├─────────────────────────────────────┤
│  🔥 7 | ✓ 3/5 | 🪙 1250 | ⭐ 4   │  64px Stats Bar
└─────────────────────────────────────┘
```

### Dashboard Layout
```
┌─────────────────────────────────────┐
│         AppHeader (120px)           │
├─────────────────────────────────────┤
│                                     │
│  [Motivation Hero - Gradient]       │
│  "Great Progress! 💪"              │
│  [Progress Bar: 3/5 Tasks]          │
│                                     │
│  Today's Missions                   │
│  ☑ Task 1 (+10)                     │
│  ☐ Task 2 (+15)                     │
│  ☐ Task 3 (+20)                     │
│  ☐ Task 4 (+25)                     │
│  ☐ Task 5 (+30)                     │
│                                     │
│  Active Programs                    │
│  [Program Card - Cyan Border]       │
│                                     │
│  [AI Coach Gradient Card]           │
│  "Get Personalized Guidance"        │
│  [Chat Now Button]                  │
│                                     │
└─────────────────────────────────────┘
                   ↓
           [Bottom Navigation]
```

---

## 📊 State Management with Riverpod

### UserStatsProvider Structure
```dart
class UserStats {
  final int coins;           // Total coins earned
  final int streak;          // Current streak days
  final int completedToday;  // Tasks done today
  final int faceScore;       // Latest face scan score
  final int level;           // Derived: score / 20
  final int totalFaceScans;  // Lifetime scans
  final List<String> goals;  // User's selected goals
}

UserStatsNotifier Methods:
  └─ addCoins(int amount) → Update coins
  └─ addStreak() → Increment streak
  └─ addCompletedTask() → Increment daily counter
  └─ updateFaceScore(int score) → Update from scan
  └─ consumeFreeScan() → Decrement free scans
  └─ setGoals(List<String>) → Set user goals
```

### Usage Example
```dart
// In any widget:
final userStats = ref.watch(userStatsProvider);
final statsNotifier = ref.read(userStatsProvider.notifier);

// Get current stats
print('Coins: ${userStats.coins}');
print('Streak: ${userStats.streak}');

// Update stats
await statsNotifier.addCoins(25);
await statsNotifier.updateFaceScore(87);
```

---

## 🎯 User Retention Loop Design

### Morning Session (7-9 AM)
1. User notifications → Opens app
2. Sees motivation message based on streak
3. Notices 5 tasks ready to complete
4. Completes 2-3 tasks (10-15 min)
5. Earns 50-75 coins
6. Sees streak maintained

### Afternoon Session (12-2 PM)
1. Lunch break notification
2. Check progress dashboard
3. Maybe complete 1 more task
4. Browse programs available
5. Earn 10-25 more coins

### Evening Session (7-9 PM)
1. Face scan suggestion notification
2. Take evening scan (+25 coins)
3. See improvement from yesterday
4. Browse AI insights
5. Plan tomorrow's goals

### Weekly Engagement
1. Monday-Friday: Daily task completion
2. Weekend: Face scan comparison
3. Sunday: Review weekly progress
4. See all achievements stacking up

---

## 🔐 Data Persistence

### SharedPreferences (Local)
```
Keys:
  'user_name' → String
  'selected_goals' → JSON
  'coin_balance' → Int
  'streak_count' → Int
  'face_score' → Int
  'last_task_date' → DateTime
  'free_scans_remaining' → Int
```

### Firestore (Cloud)
```
Collections:
  /users/{uid}
    ├── profile
    │   ├── name: String
    │   ├── email: String
    │   ├── avatar: String
    │   └── goals: List<String>
    │
    ├── stats
    │   ├── coins: Int
    │   ├── streak: Int
    │   ├── level: Int
    │   └── totalScans: Int
    │
    └── scans
        ├── {scanId}
        │   ├── timestamp: DateTime
        │   ├── score: Int
        │   ├── image_url: String
        │   └── metrics: Object
```

---

## 🚀 Performance Optimization

### Image Loading
```
SplashScreen Logo:
  └─ 100x100 SVG/PNG → 5KB
  └─ Loaded on startup
  └─ Cached in memory

Card Images:
  └─ 300x200 WebP
  └─ Lazy loaded
  └─ Cached after first load

User Avatar:
  └─ 48x48 JPEG
  └─ From Gravatar/Firebase
  └─ Cached locally
```

### Animation Performance
```
Splash: 1 rotation controller → 60fps
Onboarding: 1 page controller → 60fps
Header Stats: Text updates only → No animation
Task Completion: Scale animation → 60fps
Dashboard Hero: Gradient background → GPU rendered
```

### Network Optimization
```
API Calls:
  └─ Face scan analysis: 2-4 seconds
  └─ Program fetch: Cached
  └─ Chat responses: Streamed
  └─ User stats: Real-time with Firestore

Offline Fallback:
  └─ Use cached data
  └─ Queue pending actions
  └─ Sync when online
```

---

## 📱 Responsive Design

### Breakpoints
```
Mobile (< 600dp):
  └─ Single column layout
  └─ Full-width cards
  └─ Bottom navigation

Tablet (600+ dp):
  └─ 2 column layout
  └─ Side-by-side cards
  └─ Navigation drawer
```

### SafeArea Handling
```
Notch/Bezel Management:
  └─ MediaQuery.of(context).viewPadding.top
  └─ Scaffold handles automatically
  └─ AppBar respects system UI
```

---

## 🧪 Testing Architecture

### Unit Tests
```dart
// Test UserStatsProvider
test('addCoins increments coin balance', () {
  // ...
});

test('addStreak increments streak', () {
  // ...
});
```

### Widget Tests
```dart
// Test DashboardScreen renders correctly
testWidgets('Dashboard displays all sections', (WidgetTester tester) {
  // ...
});
```

### Integration Tests
```dart
// Test full onboarding flow
testWidgets('Complete user flow', (WidgetTester tester) {
  // Splash → Onboarding → Auth → Goals → Dashboard
});
```

---

## 📊 Metrics & Analytics

### User Engagement Tracking
```
Events:
  └─ app_open
  └─ task_completed
  └─ face_scan_taken
  └─ program_started
  └─ premium_purchased
  └─ screen_viewed

Properties:
  └─ user_level
  └─ coins_earned
  └─ streak_days
  └─ time_in_app
  └─ features_used
```

### Retention Cohorts
```
Day 1: 100% (all users)
Day 3: 60% (retention from first 3 players)
Day 7: 40% (if streak system works)
Day 14: 30% (if programs engaging)
Day 30: 15% (hardcore players)
```

---

## 🔄 Update Strategy

### Push Updates
```
Version 1.1: Fix bugs
Version 1.2: Add new programs
Version 1.3: New AI tools
Version 2.0: Social features
```

### A/B Testing
```
Test A: Blue buttons vs Purple
Test B: 5 tasks vs 10 tasks  
Test C: Daily notifications vs Weekly
```

---

## 🎯 Success Metrics Dashboard

Track these KPIs:
- DAU (Daily Active Users)
- 7-day retention
- Task completion rate
- Average coins earned per user
- Program participation rate
- Face scans per user per week
- Premium conversion rate
- ARPU (Average Revenue Per User)

---

## 📚 Code Quality

### Naming Conventions
```
Classes: PascalCase
Functions: camelCase
Constants: CONSTANT_CASE
Files: snake_case.dart
Widgets: SuffixWithScreen/Card/Button
```

### Code Organization
```
Each file should have:
  1. Imports (organized)
  2. Constants
  3. Main widget class
  4. State management (if needed)
  5. Helper methods
  6. Sub-components at bottom
```

### Documentation
```
/// Public class/method documentation
/// Parameters and return types clearly described
/// Example usage when helpful
```

---

**This architecture supports:**
- ✅ Scalability (easy to add features)
- ✅ Maintainability (clear organization)
- ✅ Performance (optimized rendering)
- ✅ User Retention (gamification built-in)
- ✅ Revenue (monetization ready)
- ✅ Analytics (tracking built-in)

It's production-ready and designed for 50,000+ users! 🚀
