# Responsive Design Constraints for Story Adventure

## Device Size Specifications

### Screen Categories
```dart
class ResponsiveBreakpoints {
  static const double smallPhoneMaxWidth = 360;   // dp (iPhone SE)
  static const double mediumPhoneMaxWidth = 400;  // dp (iPhone 12 mini)
  static const double largePhoneMaxWidth = 480;   // dp (iPhone Pro Max)
  static const double smallTabletMaxWidth = 720;  // dp (iPad mini)
  static const double largeTabletMinWidth = 800;  // dp (iPad Pro)
}
```

## Anti-Crowding Strategies

### 1. Minimum Viable Sizes
- **Text**: 14sp minimum on small phones
- **Touch targets**: 44dp (iOS) / 48dp (Android) minimum
- **Line height**: 1.6x on small screens
- **Padding**: 12dp minimum screen padding

### 2. Progressive Content Disclosure
- Hide illustrations when text > 200 chars (small phones)
- Collapse app bars on scroll
- Use scrollable text areas with indicators
- Stack choices vertically on phones

### 3. Smart Scaling Rules
- Images: Max 30% screen height on phones
- Text containers: Max 40% height for story content
- Grid layouts: 1 col (phones) → 2 cols (tablets) → 3 cols (large tablets)

### 4. Overflow Prevention
- TextPainter pre-calculation for overflow detection
- Automatic scrollbar insertion
- Ellipsis for choice buttons (max 2-3 lines)
- Safe area enforcement with minimum padding

## Layout Adaptations by Device

### Small Phone (320-360dp)
```dart
// Compact layout
TextSize: 14sp
TouchTarget: 44dp
Padding: EdgeInsets.all(12)
ImageHeight: screenHeight * 0.3 (max 180dp)
TextArea: screenHeight * 0.4
Choices: Vertical stack
Illustration: Hidden if text > 200 chars
```

### Medium Phone (360-400dp)
```dart
// Balanced layout
TextSize: 15sp
TouchTarget: 48dp
Padding: EdgeInsets.all(16)
ImageHeight: screenHeight * 0.35 (max 220dp)
TextArea: screenHeight * 0.45
Choices: Vertical stack with spacing
Illustration: Always shown
```

### Large Phone (400-480dp)
```dart
// Comfortable layout
TextSize: 16sp
TouchTarget: 48dp
Padding: EdgeInsets.all(20)
ImageHeight: screenHeight * 0.4 (max 280dp)
TextArea: screenHeight * 0.5
Choices: 2-column grid if space allows
Illustration: Full size
```

### Small Tablet (600-720dp)
```dart
// Enhanced layout
TextSize: 17sp
TouchTarget: 56dp
Padding: EdgeInsets.all(24)
ImageHeight: width / aspectRatio (max 400dp)
TextArea: Flexible with max 450dp
Choices: 2-column grid
Illustration: Magazine style
```

### Large Tablet (800dp+)
```dart
// Premium layout
TextSize: 18sp
TouchTarget: 56dp
Padding: EdgeInsets.all(32)
ImageHeight: width / aspectRatio (max 500dp)
TextArea: Flexible with max 600dp
Choices: 3-column grid
Illustration: Full bleed with borders
```

## Landscape Orientation Handling

### Small Phone Landscape
- Hide illustration completely
- Split view: 60% text, 40% choices
- Reduce vertical padding
- Compact navigation

### Tablet Landscape
- Two-column layout
- Image on left (60%)
- Text/choices on right (40%)
- Maintain aspect ratios

## Text Management

### Line Height Adjustments
```dart
double getLineHeight(DeviceCategory category) {
  switch (category) {
    case DeviceCategory.smallPhone:
      return 1.6;  // More space between lines
    case DeviceCategory.mediumPhone:
      return 1.5;
    default:
      return 1.4;
  }
}
```

### Letter Spacing
```dart
double getLetterSpacing(DeviceCategory category) {
  switch (category) {
    case DeviceCategory.smallPhone:
      return 0.3;  // Improve readability
    case DeviceCategory.mediumPhone:
      return 0.2;
    default:
      return 0.1;
  }
}
```

### Maximum Visible Lines
- Small Phone: 6 lines
- Medium Phone: 8 lines
- Large Phone: 10 lines
- Small Tablet: 12 lines
- Large Tablet: 15 lines

## Image Scaling Strategy

### Aspect Ratio Preservation
```dart
double calculateImageHeight(
  DeviceCategory category,
  Size screenSize,
  BoxConstraints constraints,
) {
  const double targetAspectRatio = 16 / 9;
  
  switch (category) {
    case DeviceCategory.smallPhone:
      return (screenSize.height * 0.3).clamp(100, 180);
    case DeviceCategory.mediumPhone:
      return (screenSize.height * 0.35).clamp(150, 220);
    case DeviceCategory.largePhone:
      return (screenSize.height * 0.4).clamp(180, 280);
    case DeviceCategory.smallTablet:
      return (constraints.maxWidth / targetAspectRatio).clamp(250, 400);
    case DeviceCategory.largeTablet:
      return (constraints.maxWidth / targetAspectRatio).clamp(350, 500);
  }
}
```

## Performance Thresholds

### Animation Complexity
- Small phones: Reduce to 30fps animations
- Low memory: Disable particle effects
- Battery saver: Minimize GPU usage

### Image Quality
- Small phones: Load 1x resolution
- Tablets: Load 2x resolution
- Retina displays: Load 3x resolution

### Memory Management
- Cache limit: 5 pages on phones, 10 on tablets
- Preload: ±1 page on phones, ±2 on tablets
- Cleanup: Release pages > 3 positions away

## Testing Checklist

### Critical Dimensions
- [ ] 320dp width (iPhone SE 1st gen)
- [ ] 375dp width (iPhone 12/13 mini)
- [ ] 430dp width (iPhone Pro Max)
- [ ] 600dp width (Small tablet)
- [ ] 834dp width (iPad Pro 11")
- [ ] 1024dp width (iPad Pro 12.9")

### Orientation Tests
- [ ] Portrait → Landscape smooth transition
- [ ] Landscape → Portrait state preservation
- [ ] Split view on iPadOS
- [ ] Android multi-window

### Accessibility Tests
- [ ] 85% text scale
- [ ] 100% text scale (default)
- [ ] 130% text scale
- [ ] 200% text scale (accessibility)
- [ ] VoiceOver navigation
- [ ] TalkBack navigation

### Edge Cases
- [ ] Notch/Dynamic Island avoidance
- [ ] Keyboard appearance handling
- [ ] Status bar height variations
- [ ] Navigation bar (Android)
- [ ] Home indicator (iOS)