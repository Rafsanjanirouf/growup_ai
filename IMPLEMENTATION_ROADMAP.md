# 🗺️ Implementation Roadmap - Remaining Screens

## Overview
This roadmap shows exactly which screens need updating, in what order, and what changes are needed for each one.

**Status:** 3/25 screens complete (12%) → Phase 2 starting
**Time Estimate:** 6 hours to complete all 22 remaining screens

---

## Phase 2: High-Priority Screens (3 hours) 

### 🎯 Priority 1: Face Scan Module (4 screens)
These are high-traffic screens with important conversion funnel.

#### Screen 1.1: Face Scan Camera Screen
**File:** `lib/features/face_scan/face_scan_screen.dart`

**Changes Needed:**
- [ ] Add imports: app_typography, app_buttons
- [ ] Header: Replace Text() with AppTypography.titleLarge
- [ ] Instructions: AppTypography.bodyLarge
- [ ] "Take Photo" button: PrimaryCTAButton with camera icon
- [ ] Lighting tips: InfoCard components
- [ ] Result: ~15 min

**Template:**
```dart
// Replace hardcoded button:
ElevatedButton(
  onPressed: () {},
  child: Text('Take Photo'),
)

// With:
PrimaryCTAButton(
  label: 'Take Photo',
  icon: Icons.photo_camera,
  onPressed: () => launchCamera(),
)

// For tips section:
Column(
  children: [
    InfoCard(icon: Icons.light, title: 'Good Lighting', description: 'Bright, even lighting works best'),
    SizedBox(height: 12),
    InfoCard(icon: Icons.face, title: 'Face Visible', description: 'Center your face in frame'),
  ],
)
```

---

#### Screen 1.2: Face Score Display
**File:** `lib/features/face_scan/face_score_screen.dart`

**Changes Needed:**
- [ ] Add imports: app_typography, app_cards
- [ ] Header: AppTypography.displayLarge
- [ ] Score label: AppTypography.eyebrow
- [ ] Score value: ShaderMask + AppTypography.displayMedium
- [ ] Metrics grid: 3x MetricCard components
- [ ] Action button: PrimaryCTAButton
- [ ] Result: ~15 min

**Template:**
```dart
// Metrics section:
Row(
  children: [
    Expanded(
      child: MetricCard(
        value: '78%',
        label: 'Clarity',
        valueColor: AppColors.primary,
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: MetricCard(
        value: '85%',
        label: 'Symmetry',
        valueColor: AppColors.secondary,
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: MetricCard(
        value: '92%',
        label: 'Coverage',
        valueColor: AppColors.tertiary,
      ),
    ),
  ],
)
```

---

#### Screen 1.3: Face Analysis Details
**File:** `lib/features/face_scan/face_analysis_result_screen.dart`

**Changes Needed:**
- [ ] Add imports: app_typography, app_cards
- [ ] Analysis title: AppTypography.titleLarge
- [ ] Analysis items: Use InfoCard for each finding
- [ ] Recommendations: Use InfoCard in column
- [ ] CTA buttons: PrimaryCTAButton + SecondaryButton
- [ ] Result: ~15 min

**Template:**
```dart
// Analysis findings:
Column(
  children: [
    InfoCard(
      icon: Icons.warning,
      title: 'Hydration Needed',
      description: 'Skin shows signs of dehydration',
      iconColor: AppColors.tertiary,
    ),
    SizedBox(height: 12),
    InfoCard(
      icon: Icons.check_circle,
      title: 'Excellent Symmetry',
      description: 'Facial structure is well-proportioned',
      iconColor: AppColors.secondary,
    ),
  ],
)
```

---

#### Screen 1.4: Scan History
**File:** `lib/features/scan/scan_history_screen.dart` (NEW/UPDATE)

**Changes Needed:**
- [ ] Add imports: app_typography, app_cards
- [ ] Header: AppTypography.displaySmall
- [ ] Date labels: AppTypography.eyebrow
- [ ] Scan items: ProgressCard or custom card
- [ ] Trend badge: AppTypography.labelSmall
- [ ] Result: ~15 min

**Template:**
```dart
// Scan history items:
ProgressCard(
  title: 'Face Scan Results',
  subtitle: 'Jan 15, 2024',
  progress: 0.78,
  progressLabel: '78% Clear',
  trailing: Icon(Icons.arrow_forward),
)
```

---

### 🎯 Priority 2: Onboarding Module (4 screens)
Critical for user acquisition and first impression.

#### Screen 2.1: Welcome/Splash
**File:** `lib/features/onboarding/splash_screen.dart`

**Changes Needed:**
- [ ] Add imports: app_typography, app_buttons, app_cards
- [ ] Title: AppTypography.displayLarge
- [ ] Subtitle: AppTypography.bodyLarge
- [ ] Hero: PremiumHighlightCard
- [ ] CTA: PrimaryCTAButton(label: 'Get Started')
- [ ] Result: ~10 min

---

#### Screen 2.2-2.4: Onboarding Steps
**Files:** `lib/features/onboarding/onboarding_[step].dart`

**Changes Needed Per Screen:**
- [ ] Add imports
- [ ] Page title: AppTypography.titleLarge
- [ ] Description: AppTypography.bodyLarge
- [ ] Feature highlights: Use InfoCard or FeatureCard
- [ ] Navigation buttons: PrimaryCTAButton + SecondaryButton
- [ ] Progress indicator: Use AppTypography.labelSmall
- [ ] Result: ~10 min each (3x = 30 min total)

---

### 🎯 Priority 3: AI Tools Showcase (6 screens)
High engagement area, needs premium feel.

#### Screen 3.1-3.6: Individual AI Tools
**Files:** `lib/features/ai_tools/[tool_name]_screen.dart`

Each tool screen needs:
- [ ] Add imports: app_typography, app_cards, app_buttons
- [ ] Tool title: AppTypography.displaySmall
- [ ] Tool icon: Large, prominent display
- [ ] Features list: Multiple InfoCard components
- [ ] Before/After: Use FeatureCard with images
- [ ] Primary CTA: PrimaryCTAButton(label: 'Try [Tool]')
- [ ] Result: ~10 min each (6x = 60 min total)

**Template - AI Tool Screen:**
```dart
Column(
  children: [
    PremiumHighlightCard(
      child: Row(
        children: [
          Icon(Icons.face, size: 48, color: AppColors.scrimLight),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('[Tool Name]', style: AppTypography.displaySmall),
                SizedBox(height: 8),
                Text('[Description]', style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 24),
    
    Text('Features', style: AppTypography.titleLarge),
    SizedBox(height: 16),
    InfoCard(icon: Icons.star, title: 'Feature 1', description: 'Details...'),
    SizedBox(height: 12),
    InfoCard(icon: Icons.star, title: 'Feature 2', description: 'Details...'),
    
    SizedBox(height: 32),
    Text('See Results', style: AppTypography.titleLarge),
    SizedBox(height: 16),
    Row(
      children: [
        Expanded(
          child: FeatureCard(
            image: NetworkImage('before.jpg'),
            title: 'Before',
            badgeText: 'BEFORE',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FeatureCard(
            image: NetworkImage('after.jpg'),
            title: 'After',
            badgeText: 'AFTER',
          ),
        ),
      ],
    ),
    
    SizedBox(height: 32),
    PrimaryCTAButton(label: 'Try [Tool]', onPressed: () {}),
  ],
)
```

---

## Phase 3: Polish Screens (2 hours)

### 🎯 Priority 4: Engagement Screens (2 screens)

#### Screen 4.1: Assistant Chat
**File:** `lib/features/assistant/assistant_chat_screen.dart`

**Changes:**
- [ ] Chat header: AppTypography.titleLarge
- [ ] Message bubbles: AppTypography.bodyMedium on semi-transparent bg
- [ ] Input area: Use PrimaryButton for send
- [ ] Result: ~15 min

---

#### Screen 4.2: Coin Store
**File:** `lib/features/monetization/coin_store_screen.dart`

**Changes:**
- [ ] Add imports: app_typography, app_cards, app_buttons
- [ ] Screen title: AppTypography.displaySmall
- [ ] Coin packages: FeatureCard components with price overlay
- [ ] Buy button: PrimaryCTAButton on each card
- [ ] Result: ~15 min

**Template:**
```dart
Column(
  children: [
    FeatureCard(
      image: NetworkImage('coin_100.png'),
      title: '100 Coins',
      description: '\$0.99',
      onTap: () => buyCoins(100),
    ),
    // More coin packages...
  ],
)
```

---

## Phase 4: Utility Screens (1 hour)

### 🎯 Priority 5: Account & Navigation (3 screens)

#### Screen 5.1: User Profile
**File:** `lib/features/profile/profile_screen.dart`

**Changes:**
- [ ] Section headers: AppTypography.labelLarge
- [ ] User name: AppTypography.titleLarge
- [ ] Info items: InfoCard components
- [ ] Actions: SecondaryButton + PrimaryButton
- [ ] Result: ~12 min

---

#### Screen 5.2: Settings
**File:** `lib/features/profile/settings_screen.dart`

**Changes:**
- [ ] Section titles: AppTypography.labelLarge with eyebrow styling
- [ ] Setting items: InfoCard with trailing toggle/button
- [ ] Result: ~10 min

---

#### Screen 5.3: Home/Bottom Navigation
**File:** `lib/features/home/home_screen.dart`

**Changes:**
- [ ] Tab labels: AppTypography.labelSmall for nav items
- [ ] Section headers: AppTypography.titleLarge
- [ ] Content: Mix of cards from completed screens
- [ ] Result: ~8 min

---

## 📋 Complete Screen Inventory

### Total Screens: 25

**Completed:** ✅ 3 screens
```
✅ Dashboard
✅ Premium Paywall  
✅ Weekly Report
```

**Remaining:** ⏳ 22 screens

**Phase 2:** 14 screens (3 hours)
```
1. Face Scan Camera
2. Face Score Display
3. Face Analysis Details
4. Scan History
5. Welcome/Splash
6. Onboarding Step 1
7. Onboarding Step 2
8. Onboarding Step 3
9. AI Tool: Beard Style
10. AI Tool: Hair Restoration
11. AI Tool: Skin Enhancement
12. AI Tool: [Tool 4]
13. AI Tool: [Tool 5]
14. AI Tool: [Tool 6]
```

**Phase 3:** 4 screens (2 hours)
```
15. Assistant Chat
16. Coin Store
17. Day Complete Celebration
18. Active Program Tracker
```

**Phase 4:** 4 screens (1 hour)
```
19. Profile
20. Settings
21. Home Navigation
22. [Additional screens]
```

---

## ⏱️ Time Estimates

| Phase | Screens | Time | Notes |
|-------|---------|------|-------|
| Phase 1 (Done) | 3 | 4h | Design system creation |
| Phase 2 | 14 | 3h | High priority + AI tools |
| Phase 3 | 4 | 2h | Polish features |
| Phase 4 | 4 | 1h | Utility screens |
| **TOTAL** | **25** | **~13h** | From start to 100% |

---

## 🎯 Implementation Strategy

### Best Approach:
1. **Start with Phase 2** (highest impact)
2. Do Face Scan first (user funnel)
3. Then Onboarding (first impression)
4. Then AI Tools (engagement showcase)
5. Move to Phase 3 & 4 (final polish)

### Pro Tips:
- ✅ Use DESIGN_SYSTEM_QUICK_REFERENCE.md as you work
- ✅ Copy code templates above into each screen
- ✅ Test 1-2 screens thoroughly before batch processing
- ✅ Keep updated screens open for reference
- ✅ Update in order: imports → typography → buttons → cards

### Quality Gate:
Before moving to next phase, verify:
- [ ] All Text uses AppTypography.* (grep for `TextStyle(` should return 0)
- [ ] All buttons are PrimaryCTAButton/SecondaryButton
- [ ] No hardcoded Colors.white/black/Colors
- [ ] All cards use component library

---

## 📝 Template Checklist

Copy this for each screen update:
```dart
// 1. Add imports
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_cards.dart';

// 2. Replace all Text() - search for "Text('" and replace with "Text(..., style: AppTypography.???)"

// 3. Replace all buttons - look for ElevatedButton, TextButton → use app_buttons

// 4. Replace all cards - look for Container/BoxDecoration → use app_cards

// 5. Verify colors - search for "Colors.white" or "Colors.black" → use AppColors

// 6. Test on device - hot reload and verify appearance
```

---

## 🚀 Ready to Start?

1. Pick **Screen 1.1: Face Scan Camera** from Phase 2
2. Open the file `lib/features/face_scan/face_scan_screen.dart`
3. Follow template above for ~15 min of work
4. Test it looks good
5. Move to next screen

**You got this!** Each screen takes 10-15 minutes once you're in rhythm. 💪

---

**Created:** Today
**Updated:** As screens complete
**Total Remaining:** ~13 hours to 100%
