# Design System Quick Reference

## 🚀 Fast Implementation Guide

### Step 1: Add Imports
```dart
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_cards.dart';
```

### Step 2: Update Text Styles - Replace With AppTypography

**Replace:**
```dart
Text('My Title', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
```

**With:**
```dart
Text('My Title', style: AppTypography.headlineLarge)
```

---

## 📚 Text Styles Reference

### Display/Headlines
```dart
AppTypography.displayLarge        // 56px, Roboto 900 - Page titles
AppTypography.displayMedium       // 45px, Roboto 800 - Major headings
AppTypography.headlineLarge       // 32px, Roboto 800 - Section titles
AppTypography.headlineMedium      // 28px, Roboto 700 - Subsections
AppTypography.titleLarge          // 22px, Roboto 700 - Card titles
AppTypography.titleMedium         // 16px, Roboto 600 - List item titles
```

### Body Text
```dart
AppTypography.bodyLarge           // 16px, Open Sans 400 - Main content
AppTypography.bodyMedium          // 14px, Open Sans 400 - Secondary content
AppTypography.bodySmall           // 12px, Open Sans 400 - Minor content
```

### Labels & Badges
```dart
AppTypography.labelLarge          // 14px, Open Sans 600 - Button text, tags
AppTypography.labelMedium         // 12px, Open Sans 600 - Badge labels
AppTypography.labelSmall          // 11px, Open Sans 600 - Small labels

AppTypography.eyebrow             // 11px, Open Sans 700, 1.5px spacing
                                  // For: Labels, badges, CAPS text
```

### Special Styles
```dart
AppTypography.ctaButton           // 16px, Roboto 800 - Primary CTA text
AppTypography.secondaryButton     // 14px, Open Sans 600 - Secondary CTA text
AppTypography.caption             // 12px, Open Sans 500 - Small supporting text
```

---

## 🎨 Color Quick Reference

### Primary Colors
```dart
AppColors.primary        // #fbbf24 - Gold (main CTAs, highlights)
AppColors.secondary      // #1f2937 - Dark Gray (text, secondary)
AppColors.tertiary       // #f59e0b - Amber (accents, warnings)
```

### Semantic Colors
```dart
AppColors.surface        // #f3f4f6 - Main background
AppColors.surfaceHigh    // #ffffff - Premium cards
AppColors.surfaceHighest // #ffffff - Highest elevation
AppColors.surfaceLow     // #f9fafb - Subtle backgrounds
AppColors.surfaceLowest  // #f3f4f6 - Lowest elevation

AppColors.outline        // #e5e7eb - Borders
AppColors.outlineVariant // #d1d5db - Secondary borders
```

### Semantic Tokens
```dart
AppColors.scrimDark      // Dark overlay  
AppColors.scrimLight     // Light overlay
AppColors.modalOverlay   // Modal background
AppColors.lightOverlay   // Light overlay for cards
```

### Gradients
```dart
AppColors.kineticGradient  // Gold → Amber gradient (hero sections)
```

---

## 🔘 Button Quick Reference

### Primary CTA Button
```dart
PrimaryCTAButton(
  label: 'Continue',
  onPressed: () {},
  icon: Icons.arrow_forward,           // optional
  isLoading: false,                    // optional
)
```

### Secondary Button
```dart
SecondaryButton(
  label: 'Cancel',
  onPressed: () {},
  icon: Icons.close,                   // optional
)
```

### Compact Icon Button
```dart
CompactIconButton(
  icon: Icons.settings,
  onPressed: () {},
  backgroundColor: AppColors.primary,  // optional
)
```

### Outline Icon Button
```dart
OutlineIconButton(
  icon: Icons.share,
  label: 'Share',                      // optional
  onPressed: () {},
)
```

### Elevated Action Button
```dart
ElevatedActionButton(
  label: 'Action',
  onPressed: () {},
  backgroundColor: AppColors.primary,  // optional
)
```

---

## 🃏 Card Quick Reference

### Premium Highlight Card (Hero Sections)
```dart
PremiumHighlightCard(
  title: 'Hero Title',
  subtitle: 'SUBTITLE',
  description: 'Long description text...',
  gradient: AppColors.kineticGradient,  // optional
  onTap: () {},                         // optional
)
```

### Info Card (Information + Action)
```dart
InfoCard(
  icon: Icons.trending_up,
  title: 'Title',
  description: 'Supporting text',
  iconColor: AppColors.primary,         // optional
  trailing: Icon(Icons.arrow_forward),  // optional
  onTap: () {},                         // optional
)
```

### Metric Card (Statistics Display)
```dart
MetricCard(
  value: '78%',
  label: 'Completion Rate',
  icon: Icon(Icons.trending_up),        // optional
  valueColor: AppColors.secondary,      // optional
  onTap: () {},                         // optional
)
```

### Progress Card (Progress Tracking)
```dart
ProgressCard(
  title: 'Program Name',
  subtitle: 'Week 2 of 4',
  progress: 0.5,
  progressLabel: '50%',                 // optional
  trailing: IconButton(...),            // optional
)
```

### Feature Card (Image Showcase)
```dart
FeatureCard(
  image: NetworkImage('https://...'),
  title: 'Feature Title',
  description: 'Feature description',
  badgeText: 'NEW',                     // optional
  onTap: () {},                         // optional
)
```

---

## 🎯 Common Patterns

### Hero Section Pattern
```dart
PremiumHighlightCard(
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LABEL', style: AppTypography.eyebrow),
            SizedBox(height: 8),
            Text('Title', style: AppTypography.displaySmall),
            SizedBox(height: 12),
            Text('Description', style: AppTypography.bodyLarge),
            SizedBox(height: 20),
            PrimaryCTAButton(label: 'Action', onPressed: () {}),
          ],
        ),
      ),
      SizedBox(width: 20),
      // Right content (icon, image, metric, etc)
    ],
  ),
)
```

### Feature Grid Pattern
```dart
Column(
  children: [
    Row(
      children: [
        Expanded(
          child: FeatureCard(
            image: NetworkImage('...'),
            title: 'Feature 1',
            badgeText: 'NEW',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FeatureCard(
            image: NetworkImage('...'),
            title: 'Feature 2',
          ),
        ),
      ],
    ),
  ],
)
```

### Metrics Dashboard Pattern
```dart
Row(
  children: [
    Expanded(
      child: MetricCard(value: '78%', label: 'Score'),
    ),
    SizedBox(width: 12),
    Expanded(
      child: MetricCard(value: '92%', label: 'Progress'),
    ),
    SizedBox(width: 12),
    Expanded(
      child: MetricCard(value: '45', label: 'Days'),
    ),
  ],
)
```

### Action Items List Pattern
```dart
Column(
  children: [
    InfoCard(
      icon: Icons.check_circle,
      title: 'Action 1',
      description: 'Details...',
      trailing: Icon(Icons.arrow_forward),
      onTap: () {},
    ),
    SizedBox(height: 12),
    InfoCard(
      icon: Icons.assignment,
      title: 'Action 2',
      description: 'Details...',
      trailing: Icon(Icons.arrow_forward),
      onTap: () {},
    ),
  ],
)
```

---

## ✔️ Screen Update Checklist

When updating a screen, verify:

- [ ] All imports added (app_typography, app_buttons, app_cards)
- [ ] All Text() styles replaced with AppTypography.*
- [ ] Section headers use AppTypography.titleLarge or headlineLarge
- [ ] Body text uses AppTypography.bodyLarge/Medium/Small
- [ ] Labels/badges use AppTypography.eyebrow or labelLarge
- [ ] All buttons use app_buttons components
- [ ] All card containers use app_cards components
- [ ] Colors use AppColors.* constants (no hardcoded Colors.white/black)
- [ ] Border radius in 16-24px range
- [ ] Shadow effects on cards (included in components)
- [ ] Touch targets minimum 48px height
- [ ] AppColors.primary for primary actions/highlights
- [ ] Proper spacing: 24-32px for sections, 12-16px for cards

---

## 🐛 Troubleshooting

**Issue:** AppTypography properties not showing up
- **Solution:** Make sure to import `app_typography.dart`

**Issue:** Can't extend button/card styling
- **Solution:** Pass optional parameters like `height`, `borderRadius`, `bgColor`

**Issue:** Colors not matching design?
- **Solution:** Always use `AppColors.*` constants, not hex values directly

**Issue:** Text still looks old/inconsistent?
- **Solution:** Search screen for `TextStyle(` and replace all with `AppTypography.*`

---

## 📈 Performance Tips

1. **Cards**: Pre-build static cards outside ListView when possible
2. **Images**: Use cached NetworkImage for FeatureCard
3. **Gradients**: Use const for AppColors.kineticGradient
4. **Shadows**: Let components handle shadows (don't add extra BoxShadow)
5. **Typography**: Use AppTypography properties directly (already optimized)

---

## 🎨 Extending the System

### Adding a New Text Style
Edit `app_typography.dart`:
```dart
static const myCustomStyle = TextStyle(
  fontFamily: 'Roboto',  // or 'Open Sans'
  fontSize: 18,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
  height: 1.4,
);
```

### Custom Button Variant
Create in `app_buttons.dart`:
```dart
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  
  const CustomButton({
    required this.label,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
      ),
      onPressed: onPressed,
      child: Text(label, style: AppTypography.ctaButton),
    );
  }
}
```

---

**Last Updated:** Today
**Version:** 1.0 Professional Design System
