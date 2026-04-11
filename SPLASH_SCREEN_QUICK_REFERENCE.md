# Splash Screen - Quick Reference Guide

## What Was Built

A premium animated splash screen for GrowUp AI that:
1. ✅ Shows app branding with gradient logo
2. ✅ Plays AI video in the background
3. ✅ Displays typing animation: "Welcome to Growup Ai, I'm your lookmaxing assistant"
4. ✅ Shows continue button only when text & video complete
5. ✅ Authenticates users based on SharedPreferences
6. ✅ Routes authenticated users directly to Dashboard
7. ✅ Routes new users to Onboarding flow

---

## Visual Flow

```
┌─────────────────────────────────────┐
│      SplashScreen Appears           │  ← App Start
│   • Video starts playing            │
│   • Text typing animation begins    │
│   • Loading indicator visible       │
└─────────────────────────────────────┘
           ↓ 3-5 seconds
┌─────────────────────────────────────┐
│  Animations Complete ✓              │
│  • Video finished or looping        │
│  • Text fully typed out             │
│  • Continue button appears          │
└─────────────────────────────────────┘
           ↓ User Taps Continue
        ┌──┬────┬──┐
        │  │    │  │
        ↓  ↓    ↓  ↓
    [Check Authentication Status]
        │        │
    YES │        │ NO
        ↓        ↓
    Dashboard  Onboarding
                  ↓
             AuthScreen
                  ↓
          GoalSelectionScreen
                  ↓
             Dashboard
```

---

## Key Components

### 1. **SplashScreen Widget** (`lib/features/onboarding/splash_screen.dart`)
- ConsumerStatefulWidget with Riverpod integration
- Manages video playback and typing animation
- Handles authentication routing

### 2. **AuthProvider** (`lib/core/providers/auth_provider.dart`)
- `isUserAuthenticatedProvider`: Checks if user is logged in
- Reads from SharedPreferences keys:
  - `userName`: User's display name
  - `userEmail`: User's email
  - `isOnboardingComplete`: Boolean flag

### 3. **Authentication Flow**
UpdatedFiles that save auth state:
- `AuthScreen`: Saves when user signs in with Google or continues as guest
- `GoalSelectionScreen`: Marks `isOnboardingComplete = true`

---

## The Typing Animation

**Text**: "Welcome to Growup Ai, I'm your lookmaxing assistant" (52 characters)
**Duration**: 3000 milliseconds

**Algorithm**:
```
Elapsed Time (ms)  →  Progress (0-1)  →  Char Count  →  Display
0                     0%               0              ""
300                   10%              5              "Welco"
1500                  50%              26             "Welcome to Growup Ai, I'"
3000                  100%             52             "Welcome to Growup Ai, I'm your lookmaxing assistant"
```

**Cursor Animation**:
- Blinking text cursor visible during typing
- Fades away when text is complete

---

## Video Integration

**Asset Path**: `assets/videos/splash_bg.mp4`
**Settings**:
- `setLooping(false)`: Plays once, then stops
- `setVolume(0)`: Always muted for splash screen
- Listens for completion via `addListener()`
- Falls back to gradient background if video fails to load

---

## Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Logo Gradient | Gold → Green | #D4AF37 → #1DBF73 |
| Button Gradient | Gold → Green | #D4AF37 → #1DBF73 |
| Background | Ultra Dark | #0D0D0D |
| Text | White | #FFFFFF |
| Secondary Text | Light Gray | #CCCCCC |
| Gold Glow (Shadow) | Gold 40% | #D4AF37 (alpha: 0.4) |

---

## Animation Timings

| Animation | Duration | Curve |
|-----------|----------|-------|
| Text Typing | 3000ms | Linear (calculated) |
| Button Scale | 500ms | elasticOut |
| Cursor Blink | Continuous | Custom opacity |
| Video Playback | Variable | N/A |

---

## SharedPreferences Structure

After user completes signup:
```json
{
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "isOnboardingComplete": true,
  "selectedGoals": "jawline,skin,confidence"
}
```

The splash screen checks for the presence of `userName`, `userEmail`, and `isOnboardingComplete` to determine if user is authenticated.

---

## Testing the Flows

### Test Case 1: First Time User
1. Clear SharedPreferences
2. Launch app → Splash shows
3. Text animates for 3 seconds
4. Video completes
5. Continue button appears
6. Tap Continue → Onboarding Screen

### Test Case 2: Returning Authenticated User
1. Set in SharedPreferences:
   - `userName` = "Test User"
   - `userEmail` = "test@test.com"
   - `isOnboardingComplete` = true
2. Launch app → Splash shows
3. Both animations complete
4. Continue button appears
5. Tap Continue → **Dashboard directly** (skips onboarding)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Video not showing | Check asset path in `pubspec.yaml`: `assets: - assets/videos/splash_bg.mp4` |
| Text not animating | Ensure `initState()` is called. Check console for errors. |
| Button not appearing | Both `_isTextComplete` and `_isVideoComplete` must be true |
| Navigation stuck | Clear app cache/data and restart |
| Wrong page after tap | Check SharedPreferences values in Flutter DevTools |

---

## Future Customizations

You can easily modify:

1. **Text Content**: Change `_welcomeText` variable
2. **Typing Speed**: Change `_typingDuration` (in milliseconds)
3. **Video Path**: Change video asset path in `VideoPlayerController.asset()`
4. **Button Style**: Modify gradient colors or padding
5. **Animation Curves**: Change `CurvedAnimation` values

---

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `splash_screen.dart` | Main splash UI & logic | ✅ Created |
| `auth_provider.dart` | Authentication state mgmt | ✅ Created |
| `auth_screen.dart` | Sign in/guest flow | ✅ Updated |
| `goal_selection_screen.dart` | Settings after auth | ✅ Updated |
| `main.dart` | Entry point | ✅ Already using |

---

## Notes

- The splash screen uses **Riverpod** for state management (follows app architecture)
- Video is **muted** for splash (no interruption of system sounds)
- Button has **elastic animation** for premium feel
- **Dark theme** throughout (matching app design)
- Fully **responsive** on all screen sizes (uses percentage-based padding)
