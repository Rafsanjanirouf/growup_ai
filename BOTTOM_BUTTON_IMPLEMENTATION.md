# Bottom Button UI & Animation Implementation Guide

## Overview
All screens now use a consistent, animated bottom button with premium styling similar to the splash screen. The `BottomActionButton` component provides:
- Premium gradient styling
- Tab animation (slides up when pressed)
- Scale animation (grows into view)
- Loading state support
- Customizable labels and icons

## Component: `BottomActionButton`

### Location
`lib/shared/widgets/bottom_action_button.dart`

### Features
- **Tab Animation**: Button slides up 8px with smooth easing when tapped
- **Scale Animation**: Button scales in with elastic effect when first visible
- **Loading State**: Shows spinner and custom text while loading
- **Flexible**: Works as standalone or with external AnimationController
- **Premium Styling**: Gradient background, glassmorphic effects, shadows

### Usage

#### Basic Usage (Simple Button)
```dart
BottomActionButton(
  label: 'Continue',
  icon: Icons.arrow_forward,
  onTap: () {
    // Handle tap
  },
)
```

#### With Custom Positioning
```dart
BottomActionButton(
  label: 'Scan Face',
  icon: Icons.camera,
  bottomOffset: 48, // Adjust from bottom
  onTap: _startScan,
)
```

#### With Loading State
```dart
BottomActionButton(
  label: 'Analyze',
  isLoading: _isAnalyzing,
  loadingText: 'Analyzing...',
  onTap: !_isAnalyzing ? _analyze : null,
)
```

#### With External Animation Controller
```dart
late AnimationController _buttonController;

@override
void initState() {
  _buttonController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
}

// In build method
BottomActionButton(
  label: 'Submit',
  scaleController: _buttonController,
  showAnimation: true,
  onTap: _submit,
)

@override
void dispose() {
  _buttonController.dispose();
  super.dispose();
}
```

## Screen-by-Screen Implementation

### 1. Splash Screen (DONE)
- ✅ Uses ScaleTransition for appearance animation
- ✅ Shows loading state during initialization
- ✅ Optimized for fast loading (1.5s timeout)

**Import:**
```dart
import '../../shared/widgets/bottom_action_button.dart';
```

### 2. Onboarding Screen
Located: `lib/features/onboarding/onboarding_screen.dart`

**Current State**: Has bottom buttons but no tab animations

**Apply**: Replace row of buttons with bottom action buttons with animations

### 3. Programs Screen
Located: `lib/features/programs/programs_screen.dart`

**Apply**: Add "Start Program" button with animation

### 4. Dashboard Screen
Located: `lib/features/dashboard/dashboard_screen.dart`

**Apply**: Add contextual action button (e.g., "View Today's Tasks")

### 5. Face Scan Screen
Located: `lib/features/face_scan/face_scan_screen.dart`

**Apply**: Replace capture button with animated action button

### 6. Program Detail Screen
Located: `lib/features/programs/program_detail_screen.dart`

**Apply**: Replace CTA button with bottom action button

## Animation Details

### Tab Animation (Press Effect)
- Duration: 300ms
- Curve: easeInOut
- Translation: Slides up 8px on press, returns on release
- Provides tactile feedback without changing states

### Scale Animation (Entrance)
- Duration: 500ms
- Curve: elasticOut
- Begins from 0, scales to 1
- Smooth, professional appearance

### Color Transitions
- Primary gradient for normal state
- Maintained on press (tab animation handles feedback)
- Loading state shows spinner with white color

## Implementation Checklist

- [ ] Review and apply to OnboardingScreen
- [ ] Review and apply to ProgramsScreen
- [ ] Review and apply to DashboardScreen
- [ ] Review and apply to FaceScanScreen
- [ ] Review and apply to ProgramDetailScreen
- [ ] Test all animations on device
- [ ] Verify loading states work correctly
- [ ] Check performance (smooth 60fps)
- [ ] Test on various screen sizes

## Technical Notes

1. **Performance**: Button uses `Positioned` layout for efficient rendering
2. **Memory**: Internal AnimationController is disposed properly if not provided externally
3. **State Management**: Supports both controlled (external controller) and uncontrolled modes
4. **Touch Feedback**: Tab animation provides visual feedback while maintaining material design principles

## Customization Options

```dart
const BottomActionButton({
  required String label,           // Button text
  VoidCallback? onTap,            // Tap callback
  IconData? icon,                 // Optional icon
  bool isLoading = false,         // Show loading state
  String? loadingText,            // Custom loading text
  double bottomOffset = 60,       // Distance from bottom
  bool showAnimation = true,      // Enable entrance animation
  AnimationController? scaleController, // External controller
})
```

## Future Enhancements

1. Add swipe-up gesture recognition
2. Add haptic feedback on tap
3. Support multiple button variations (secondary, danger, etc.)
4. Add icon-only mode
5. Support floating action menu patterns
