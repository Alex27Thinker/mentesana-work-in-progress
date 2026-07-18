# Performance Audit Workflow

This guide provides a step-by-step workflow for conducting a comprehensive performance audit of a Flutter application. Use this checklist when investigating performance issues or as part of a regular performance review process.

## Pre-Audit Preparation

### 1. Set Up Profiling Environment

```bash
# Build and run in profile mode
flutter run --profile

# Or for specific device
flutter run --profile -d <device-id>
```

**Why profile mode?**
- Debug mode includes overhead (assertions, debugging symbols)
- Release mode lacks profiling instrumentation
- Profile mode provides accurate metrics with profiling tools

### 2. Launch DevTools

```bash
# DevTools URL printed in console
# Or launch separately
dart devtools
```

### 3. Define Performance Baselines

Document target metrics:

```yaml
performance_targets:
  frame_time: 16ms      # 60 fps
  build_time: 8ms       # Half of frame budget
  memory_usage: 150MB   # Typical for medium app
  app_size: 20MB        # Download size target
  startup_time: 2s      # Time to interactive
```

## Audit Process

### Phase 1: Rendering Performance

**1.1 Enable Performance Overlay**

```dart
// Temporarily add to MaterialApp
MaterialApp(
  showPerformanceOverlay: true,
  home: MyHomePage(),
)
```

**1.2 Exercise Critical User Flows**

Test scenarios that users perform frequently:
- App launch to first screen
- Navigation between screens
- List scrolling (especially long lists)
- Form interactions
- Animations and transitions
- Pull-to-refresh operations

**1.3 Record and Analyze Frames**

In DevTools Performance view:

1. Click **Record**
2. Perform user flow
3. Click **Stop**
4. Identify red (janky) frames

**Look for:**
- Frames exceeding 16ms
- Consistent jank during specific operations
- GPU vs UI thread bottlenecks

**Sample findings:**
```
Screen: Product List
─────────────────────────────────────────
Scroll performance:
- Average frame time: 18.4ms (JANK)
- 65% of frames exceed 16ms
- UI thread: 14.2ms (high)
- Raster thread: 4.2ms (ok)

Issue: Build overhead during scroll
```

**1.4 Enable Frame Analysis**

Click janky frames for detailed breakdown:

```
Frame #342: 24.6ms
─────────────────
Build: 18.2ms ← PRIMARY ISSUE
  └─ ProductCard.build: 12.4ms
     └─ Image widget: 8.1ms

Layout: 3.8ms
Paint: 2.6ms

Recommendation: Use const constructors,
RepaintBoundary, cached network images
```

**1.5 Check Rendering Layers**

Enable visual debugging:

```dart
import 'package:flutter/rendering.dart';

// Check for excessive layers
debugPaintLayerBordersEnabled = true;

// Check for offscreen rendering
debugPaintSizeEnabled = true;
```

**Red flags:**
- Many gold borders (saveLayer calls from Opacity, ClipPath)
- Excessive blue borders (too many layers)
- Rapid color changes in repaint rainbow

### Phase 2: Build Performance

**2.1 Track Widget Builds**

In DevTools Performance view, enable **Track widget builds**.

**2.2 Analyze Build Frequency**

Record typical user session and check timeline:

```
Build Events (30 seconds):
──────────────────────────────
ProductCard.build: 234 calls ← EXCESSIVE
HeaderWidget.build: 234 calls ← EXCESSIVE
FooterWidget.build: 1 call    ← Good

Issue: ProductCard rebuilds on every scroll frame
```

**2.3 Identify Expensive Builds**

Sort timeline events by duration:

```
Longest Builds:
───────────────────────────────
1. ProductListScreen.build: 45.2ms
2. FilterPanel.build: 32.1ms
3. SearchResults.build: 28.4ms
```

**2.4 Check for Build Anti-Patterns**

Review code for common issues:

```dart
// ❌ Anti-pattern checklist:
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ Work in build()
    final sortedItems = items.toList()..sort();

    // ❌ No const constructors
    return Column(
      children: [
        Text('Title'),
        Text('Subtitle'),
      ],
    );

    // ❌ Creating controllers in build
    final controller = TextEditingController();

    // ❌ Accessing context in closures
    final handler = () => Navigator.of(context).push(...);
  }
}
```

### Phase 3: Memory Analysis

**3.1 Take Baseline Snapshot**

In DevTools Memory view:
1. Force GC (garbage collection button)
2. Take snapshot A
3. Note total memory (e.g., 87 MB)

**3.2 Exercise Feature**

Perform complete user flow:
```
1. Open product list
2. Scroll through items
3. Open product details
4. Navigate back
5. Repeat 5 times
```

**3.3 Take Post-Exercise Snapshot**

1. Force GC
2. Take snapshot B
3. Note total memory (e.g., 134 MB)

**3.4 Analyze Memory Growth**

```
Baseline (Snapshot A):     87 MB
After exercise (Snapshot B): 134 MB
Growth:                    47 MB ← LEAK SUSPECTED

Expected growth: 5-10 MB (normal caching)
Actual growth: 47 MB (concerning)
```

**3.5 Diff Snapshots**

Click **Diff** and compare A to B:

```
Class                  Delta Instances    Delta Retained
──────────────────────────────────────────────────────────
ProductDetailScreen    +5                 +12.4 MB ← LEAK
Image                  +50                +23.1 MB ← LEAK
_ProductController     +5                 +8.2 MB  ← LEAK
String                 +2,341             +1.2 MB  ← Normal
```

**3.6 Investigate Retaining Paths**

Click leaked instances to see what's holding references:

```
ProductDetailScreen retained by:
├─ GlobalNavigationService._screenHistory
│  └─ GlobalNavigationService (static)
└─ _listeners (ChangeNotifier)
   └─ ProductController (not disposed)

Issue: Screens not disposed, controllers leaked
```

**3.7 Check Image Memory**

Monitor "Dart/Flutter Native" in memory chart:

```
Image Memory Pattern:
─────────────────────
Start: 12 MB
Load 10 images: 45 MB
Navigate away: 44 MB ← SHOULD DROP

Issue: Images not evicted from cache
```

### Phase 4: CPU Profiling

**4.1 Record CPU Profile**

In DevTools CPU Profiler:
1. Click **Record**
2. Perform expensive operation
3. Click **Stop**

**4.2 Analyze Flame Chart**

Look for wide sections (expensive operations):

```
main() [2000ms]
└─ runApp() [1950ms]
   └─ build() [1800ms]
      └─ loadProducts() [1200ms] ← HOT SPOT
         └─ jsonDecode() [800ms]
         └─ Product.fromJson() [400ms]
```

**4.3 Check Call Tree (Self Time)**

Sort by "Self" column:

```
Method                  Total     Self
──────────────────────────────────────
jsonDecode()            800ms    800ms  ← SLOWEST
_sortProducts()         400ms    400ms
Product.fromJson()      400ms    200ms
build()                 1800ms   100ms
```

**4.4 Identify Optimization Opportunities**

```
Finding: jsonDecode() takes 800ms
Solution: Move to isolate

Finding: _sortProducts() takes 400ms
Solution: Cache sorted results, don't sort in build()

Finding: Product.fromJson() called 1000 times
Solution: Implement object pooling or caching
```

### Phase 5: Network Performance

**5.1 Monitor Network Requests**

In DevTools Network view, record session:

```
HTTP Requests (Product List Screen):
─────────────────────────────────────────────
GET /api/products         450ms    45 KB
GET /api/products/1/image 234ms    234 KB
GET /api/products/2/image 245ms    256 KB
... (repeated 20 times)

Issues:
1. Serial image loading (not parallel)
2. No caching (same images re-downloaded)
3. Large image sizes (not optimized)
```

**5.2 Analyze Request Timing**

Click requests for breakdown:

```
GET /api/products (450ms)
─────────────────────────
DNS Lookup:       45ms
TCP Connect:      67ms
TLS Handshake:    89ms
Request Sent:     12ms
Waiting (TTFB):   198ms ← SLOW SERVER
Download:         39ms

Issue: Backend response time high
```

**5.3 Check Request Count**

```
Expected: 1 request for products, 1 for images
Actual: 1 + 20 image requests

Optimization: Bundle images in product response
or use image CDN with caching
```

### Phase 6: App Size Analysis

**6.1 Build with Size Analysis**

```bash
flutter build apk --analyze-size --release
```

**6.2 Review Terminal Output**

```
════════════════════════════════════════════
app-release.apk (total compressed)  22.4 MB
════════════════════════════════════════════
lib/
  arm64-v8a                         9.2 MB ← Check if expected
  armeabi-v7a                       8.1 MB
assets/
  flutter_assets                    3.8 MB ← Large assets?
    images/                         3.2 MB ← Investigate
    fonts/                          0.6 MB
res/
  drawable-xxxhdpi-v4               1.1 MB
```

**6.3 Analyze in DevTools**

Import JSON into App Size tool:

```
Package Breakdown:
─────────────────────────
package:my_app          3.2 MB
package:flutter         2.8 MB
package:firebase_core   1.4 MB ← Large dependency
package:video_player    0.9 MB
dart:core               0.8 MB

Investigation: Do we need all of firebase_core?
```

**6.4 Check Asset Sizes**

```bash
# List large assets
cd build/app/intermediates/merged_assets/release/out
find . -type f -size +500k -exec ls -lh {} \;

# Sample output:
-rw-r--r-- 1 user staff 2.1M product_banner.png ← Unoptimized
-rw-r--r-- 1 user staff 1.8M background.jpg     ← Could use WebP
-rw-r--r-- 1 user staff 0.9M CustomFont.ttf     ← Not subset
```

## Audit Report Template

### Executive Summary

```markdown
# Performance Audit Report
**App**: MyApp v1.2.3
**Date**: 2024-01-15
**Auditor**: Performance Team

## Overall Health: ⚠️ NEEDS IMPROVEMENT

- **Rendering**: ⚠️ 65% of frames drop below 60fps
- **Memory**: ❌ Memory leak detected (47MB growth)
- **Build Performance**: ⚠️ Excessive rebuilds in lists
- **Network**: ⚠️ Redundant requests, no caching
- **App Size**: ✅ Within budget (22MB)
```

### Detailed Findings

```markdown
## 1. Rendering Performance

### Issue: Janky Scrolling in Product List
**Severity**: High
**Impact**: User experience degraded during primary use case

**Metrics**:
- Average frame time: 18.4ms (target: <16ms)
- 65% frames janky
- Build time: 14.2ms (excessive)

**Root Cause**:
- ProductCard widget rebuilds on every frame
- No const constructors
- Images not cached
- No RepaintBoundary

**Recommendation**:
1. Add const constructors to ProductCard
2. Wrap ProductCard in RepaintBoundary
3. Use CachedNetworkImage package
4. Implement image caching strategy

**Priority**: P0 (critical)
**Effort**: 2-3 days

## 2. Memory Leak

### Issue: ProductDetailScreen Not Released
**Severity**: Critical
**Impact**: App crashes after viewing ~20 products

**Metrics**:
- Memory growth: 47MB per usage cycle
- Expected: 5-10MB
- Leaked instances: 5x ProductDetailScreen

**Root Cause**:
- GlobalNavigationService keeps screen history
- ProductController listeners not removed
- Timer in ProductDetailScreen not cancelled

**Recommendation**:
1. Remove screen history from GlobalNavigationService
2. Dispose ProductController properly
3. Cancel timers in dispose()

**Priority**: P0 (critical)
**Effort**: 1-2 days

## 3. Build Performance

### Issue: Excessive Rebuilds
**Severity**: Medium
**Impact**: Battery drain, slight lag

**Metrics**:
- ProductCard.build: 234 calls in 30s
- Expected: <30 calls

**Root Cause**:
- Parent widget setState triggers all children
- No build optimization

**Recommendation**:
1. Split ProductList into smaller widgets
2. Use const constructors
3. Localize setState calls

**Priority**: P1 (high)
**Effort**: 1 day
```

### Action Plan

```markdown
## Immediate Actions (This Week)

1. ✅ Fix memory leak in ProductDetailScreen
   - Owner: @john
   - Deadline: 2024-01-17

2. ✅ Optimize ProductCard widget
   - Owner: @sarah
   - Deadline: 2024-01-18

3. ✅ Implement image caching
   - Owner: @mike
   - Deadline: 2024-01-19

## Short-Term Actions (This Sprint)

4. ⏳ Reduce build overhead in list
5. ⏳ Optimize network requests
6. ⏳ Add performance tests to CI

## Long-Term Actions (Next Quarter)

7. 📋 Implement deferred loading
8. 📋 Asset optimization strategy
9. 📋 Performance monitoring in production
```

## Automation Scripts

### Automated Performance Check

```dart
// test/performance/performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Performance audit', (tester) async {
    await tester.pumpWidget(MyApp());

    // 1. Memory baseline
    final initialMemory = await getMemoryUsage();

    // 2. Exercise app
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // 3. Check memory growth
    final finalMemory = await getMemoryUsage();
    final growth = finalMemory - initialMemory;

    expect(growth, lessThan(10 * 1024 * 1024)); // Less than 10 MB

    // 4. Frame time check
    final frames = await getFrameTimings();
    final jankyFrames = frames.where((f) => f > 16).length;
    final jankyPercent = jankyFrames / frames.length;

    expect(jankyPercent, lessThan(0.1)); // Less than 10% jank
  });
}
```

### CI/CD Integration

```yaml
# .github/workflows/performance.yml
name: Performance Audit

on: [pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Build with size analysis
        run: |
          flutter build apk --analyze-size --release

      - name: Check size budget
        run: |
          SIZE=$(grep "total compressed" build/outputs/size.txt | awk '{print $3}')
          if [ $SIZE -gt 25000000 ]; then
            echo "App size exceeded budget: $SIZE"
            exit 1
          fi

      - name: Run performance tests
        run: flutter test test/performance/

      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: performance-report
          path: build/reports/performance/
```

## Regular Audit Schedule

```yaml
audit_schedule:
  weekly:
    - Quick rendering check (30 min)
    - Memory snapshot comparison (15 min)

  bi_weekly:
    - Full rendering audit (2 hours)
    - Network performance review (1 hour)

  monthly:
    - Comprehensive audit (1 day)
    - Size analysis and optimization (4 hours)
    - Generate and review metrics (2 hours)

  quarterly:
    - Deep optimization sprint (1 week)
    - Performance architecture review (2 days)
    - Team training and knowledge sharing (1 day)
```

This audit workflow ensures systematic identification and resolution of performance issues. Regular audits prevent performance regression and maintain a smooth user experience throughout the app's lifecycle.
