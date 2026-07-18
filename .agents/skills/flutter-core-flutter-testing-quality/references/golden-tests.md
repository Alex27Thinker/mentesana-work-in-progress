# Golden Tests in Flutter

Golden tests (also called screenshot tests or snapshot tests) are a form of visual regression testing that compare the rendered output of your widgets against reference images. They catch unintended visual changes, ensure consistent UI across platforms, and validate complex widget layouts. Golden tests are particularly valuable for design systems, UI component libraries, and applications where visual consistency is critical.

## Table of Contents

- [What Are Golden Tests](#what-are-golden-tests)
- [Setting Up Golden Tests](#setting-up-golden-tests)
- [Creating Your First Golden Test](#creating-your-first-golden-test)
- [Generating Golden Files](#generating-golden-files)
- [Updating Golden Files](#updating-golden-files)
- [Testing Responsive Layouts](#testing-responsive-layouts)
- [Testing Themes](#testing-themes)
- [Testing Custom Widgets](#testing-custom-widgets)
- [Platform-Specific Goldens](#platform-specific-goldens)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

## What Are Golden Tests

Golden tests work by:

1. **Rendering** a widget to a test surface
2. **Capturing** the pixel output as an image
3. **Comparing** against a reference "golden" image
4. **Failing** if pixels differ beyond a threshold

Golden tests are excellent for:
- Detecting unintended visual regressions
- Validating complex widget compositions
- Ensuring cross-platform consistency
- Testing responsive breakpoints
- Verifying theme applications

Golden tests are NOT ideal for:
- Testing business logic (use unit tests)
- Testing user interactions (use widget/integration tests)
- Validating dynamic content that changes frequently

## Setting Up Golden Tests

Golden tests use the `flutter_test` package's built-in golden comparison functionality.

### Project Structure

```
my_app/
├── lib/
│   └── widgets/
│       └── user_card.dart
├── test/
│   ├── widgets/
│   │   └── user_card_test.dart
│   └── goldens/
│       ├── user_card_default.png
│       ├── user_card_dark_theme.png
│       └── user_card_small_screen.png
└── pubspec.yaml
```

### Dependencies

Golden tests use only the standard `flutter_test` package:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Configuration

Configure Flutter to use local golden file comparison:

```dart
// test/flutter_test_config.dart
import 'dart:async';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Configuration for golden tests
  await testMain();
}
```

## Creating Your First Golden Test

Let's create a golden test for a profile card widget.

### Widget: `lib/widgets/profile_card.dart`

```dart
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Golden Test: `test/widgets/profile_card_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/widgets/profile_card.dart';

void main() {
  group('ProfileCard Golden Tests', () {
    testWidgets('matches golden file with default theme', (tester) async {
      // Arrange: Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              name: 'John Doe',
              email: 'john@example.com',
            ),
          ),
        ),
      );

      // Assert: Compare against golden file
      await expectLater(
        find.byType(ProfileCard),
        matchesGoldenFile('goldens/profile_card_default.png'),
      );
    });

    testWidgets('matches golden file without avatar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              name: 'Jane Smith',
              email: 'jane@example.com',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(ProfileCard),
        matchesGoldenFile('goldens/profile_card_no_avatar.png'),
      );
    });
  });
}
```

## Generating Golden Files

Generate initial golden files or update after intentional changes.

### Generate New Goldens

```bash
# Generate all golden files
flutter test --update-goldens

# Generate goldens for specific test file
flutter test test/widgets/profile_card_test.dart --update-goldens

# Generate goldens matching pattern
flutter test --name="ProfileCard" --update-goldens
```

### Verify Goldens Match

```bash
# Run tests normally (will fail if goldens don't match)
flutter test

# Run specific golden test
flutter test test/widgets/profile_card_test.dart
```

### Golden File Locations

By default, golden files are stored relative to the test file:

```dart
// Stored at: test/goldens/my_widget.png
matchesGoldenFile('goldens/my_widget.png')

// Stored at: test/widgets/goldens/specific.png
matchesGoldenFile('widgets/goldens/specific.png')

// Stored at: test/my_golden.png
matchesGoldenFile('my_golden.png')
```

## Updating Golden Files

When you intentionally change UI, update golden files:

### Workflow for UI Changes

1. **Make UI changes** in your widget code
2. **Run tests** to see failures
3. **Review differences** (if using visual diff tools)
4. **Update goldens** if changes are intentional
5. **Commit updated golden files** with your code

```bash
# After UI changes, update goldens
flutter test --update-goldens

# Verify tests pass with new goldens
flutter test

# Commit both code and golden changes
git add lib/ test/
git commit -m "Update button styling and golden files"
```

## Testing Responsive Layouts

Test widgets at different screen sizes.

### Different Screen Sizes

```dart
testWidgets('matches golden at phone size', (tester) async {
  // Set phone screen size (375x667 - iPhone SE)
  tester.binding.window.physicalSizeTestValue = const Size(375, 667);
  tester.binding.window.devicePixelRatioTestValue = 2.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MyResponsiveWidget()),
    ),
  );

  await expectLater(
    find.byType(MyResponsiveWidget),
    matchesGoldenFile('goldens/responsive_phone.png'),
  );
});

testWidgets('matches golden at tablet size', (tester) async {
  // Set tablet screen size (768x1024 - iPad)
  tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
  tester.binding.window.devicePixelRatioTestValue = 2.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MyResponsiveWidget()),
    ),
  );

  await expectLater(
    find.byType(MyResponsiveWidget),
    matchesGoldenFile('goldens/responsive_tablet.png'),
  );
});

testWidgets('matches golden at desktop size', (tester) async {
  // Set desktop screen size (1920x1080)
  tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MyResponsiveWidget()),
    ),
  );

  await expectLater(
    find.byType(MyResponsiveWidget),
    matchesGoldenFile('goldens/responsive_desktop.png'),
  );
});
```

### Orientation Testing

```dart
testWidgets('matches golden in portrait', (tester) async {
  tester.binding.window.physicalSizeTestValue = const Size(375, 667);
  tester.binding.window.devicePixelRatioTestValue = 2.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(MaterialApp(home: MyWidget()));

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/portrait.png'),
  );
});

testWidgets('matches golden in landscape', (tester) async {
  tester.binding.window.physicalSizeTestValue = const Size(667, 375);
  tester.binding.window.devicePixelRatioTestValue = 2.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  await tester.pumpWidget(MaterialApp(home: MyWidget()));

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/landscape.png'),
  );
});
```

## Testing Themes

Verify widgets look correct with different themes.

### Light and Dark Themes

```dart
testWidgets('matches golden with light theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: MyThemedWidget()),
    ),
  );

  await expectLater(
    find.byType(MyThemedWidget),
    matchesGoldenFile('goldens/themed_light.png'),
  );
});

testWidgets('matches golden with dark theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: MyThemedWidget()),
    ),
  );

  await expectLater(
    find.byType(MyThemedWidget),
    matchesGoldenFile('goldens/themed_dark.png'),
  );
});
```

### Custom Theme Testing

```dart
testWidgets('matches golden with custom theme', (tester) async {
  final customTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: customTheme,
      home: Scaffold(body: MyThemedWidget()),
    ),
  );

  await expectLater(
    find.byType(MyThemedWidget),
    matchesGoldenFile('goldens/themed_custom.png'),
  );
});
```

### High Contrast Themes

```dart
testWidgets('matches golden with high contrast theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.highContrastLight(),
      ),
      home: Scaffold(body: MyThemedWidget()),
    ),
  );

  await expectLater(
    find.byType(MyThemedWidget),
    matchesGoldenFile('goldens/themed_high_contrast.png'),
  );
});
```

## Testing Custom Widgets

Golden tests are perfect for validating custom reusable widgets.

### Testing Button Variations

```dart
void main() {
  group('CustomButton Golden Tests', () {
    testWidgets('primary button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Primary',
              onPressed: () {},
              type: ButtonType.primary,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_primary.png'),
      );
    });

    testWidgets('secondary button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Secondary',
              onPressed: () {},
              type: ButtonType.secondary,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_secondary.png'),
      );
    });

    testWidgets('disabled button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Disabled',
              onPressed: null,
              type: ButtonType.primary,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_disabled.png'),
      );
    });

    testWidgets('button with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'With Icon',
              icon: Icons.add,
              onPressed: () {},
              type: ButtonType.primary,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_with_icon.png'),
      );
    });
  });
}
```

### Testing Card Layouts

```dart
testWidgets('product card matches golden', (tester) async {
  final product = Product(
    id: '1',
    name: 'Test Product',
    price: 29.99,
    imageUrl: 'https://example.com/image.jpg',
    rating: 4.5,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductCard(product: product),
      ),
    ),
  );

  await expectLater(
    find.byType(ProductCard),
    matchesGoldenFile('goldens/product_card.png'),
  );
});
```

### Testing List Items

```dart
testWidgets('list item variations', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            UserListItem(
              name: 'John Doe',
              status: UserStatus.online,
            ),
            UserListItem(
              name: 'Jane Smith',
              status: UserStatus.offline,
            ),
            UserListItem(
              name: 'Bob Johnson',
              status: UserStatus.away,
            ),
          ],
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(ListView),
    matchesGoldenFile('goldens/user_list.png'),
  );
});
```

## Platform-Specific Goldens

Generate separate goldens for iOS, Android, web, and desktop.

### Platform Directory Structure

```
test/
└── goldens/
    ├── android/
    │   └── widget.png
    ├── ios/
    │   └── widget.png
    ├── macos/
    │   └── widget.png
    └── web/
        └── widget.png
```

### Platform-Specific Test

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

testWidgets('matches platform-specific golden', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyWidget()));

  String goldenPath;
  if (kIsWeb) {
    goldenPath = 'goldens/web/widget.png';
  } else if (Platform.isAndroid) {
    goldenPath = 'goldens/android/widget.png';
  } else if (Platform.isIOS) {
    goldenPath = 'goldens/ios/widget.png';
  } else if (Platform.isMacOS) {
    goldenPath = 'goldens/macos/widget.png';
  } else {
    goldenPath = 'goldens/default/widget.png';
  }

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile(goldenPath),
  );
});
```

### Skip Tests on Specific Platforms

```dart
testWidgets('android-specific golden', (tester) async {
  // ...
}, skip: !Platform.isAndroid);

testWidgets('ios-specific golden', (tester) async {
  // ...
}, skip: !Platform.isIOS);
```

## CI/CD Integration

Automate golden testing in continuous integration.

### GitHub Actions Example

```yaml
# .github/workflows/golden_tests.yml
name: Golden Tests

on: [push, pull_request]

jobs:
  golden-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run golden tests
        run: flutter test --update-goldens=false

      - name: Upload failure screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: golden-failures
          path: test/failures/
```

### Handling Golden File Differences

```yaml
# Compare golden files in PR
- name: Check for golden changes
  run: |
    if git diff --name-only | grep -q "\.png$"; then
      echo "Golden files changed. Please review:"
      git diff --name-only | grep "\.png$"
      exit 1
    fi
```

## Best Practices

### 1. Use Stable Test Data

Avoid dynamic data that changes between test runs:

```dart
// Bad: Current date changes
Text('Today is ${DateTime.now()}')

// Good: Fixed test date
Text('Today is 2024-01-15')
```

### 2. Mock Network Images

Replace network images with local assets:

```dart
// Use Image.asset in tests instead of Image.network
await tester.pumpWidget(
  MaterialApp(
    home: Image.asset('assets/test_image.png'),
  ),
);
```

Or use a custom image provider:

```dart
testWidgets('with mocked image', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileCard(
        name: 'John',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      ),
    ),
  );

  // Image will fail to load in test, showing placeholder
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(ProfileCard),
    matchesGoldenFile('goldens/profile_with_image.png'),
  );
});
```

### 3. Keep Golden Files Small

Test individual components, not entire screens:

```dart
// Bad: Full screen golden (large, fragile)
await expectLater(
  find.byType(HomeScreen),
  matchesGoldenFile('home_screen.png'),
);

// Good: Individual widget golden (small, focused)
await expectLater(
  find.byType(HeaderWidget),
  matchesGoldenFile('header_widget.png'),
);
```

### 4. Use Descriptive Golden File Names

```dart
// Bad: Unclear names
matchesGoldenFile('test1.png')
matchesGoldenFile('widget.png')

// Good: Descriptive names
matchesGoldenFile('goldens/button_primary_enabled.png')
matchesGoldenFile('goldens/user_card_dark_theme.png')
matchesGoldenFile('goldens/list_item_selected_state.png')
```

### 5. Test Multiple States

Capture different widget states:

```dart
group('Button states', () {
  testWidgets('enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MyButton(enabled: true)),
    );
    await expectLater(
      find.byType(MyButton),
      matchesGoldenFile('goldens/button_enabled.png'),
    );
  });

  testWidgets('disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MyButton(enabled: false)),
    );
    await expectLater(
      find.byType(MyButton),
      matchesGoldenFile('goldens/button_disabled.png'),
    );
  });

  testWidgets('loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MyButton(isLoading: true)),
    );
    await expectLater(
      find.byType(MyButton),
      matchesGoldenFile('goldens/button_loading.png'),
    );
  });
});
```

### 6. Review Golden Changes Carefully

When updating goldens:

```bash
# Generate new goldens
flutter test --update-goldens

# Use git diff to review pixel changes
git diff test/goldens/

# Verify changes are intentional before committing
git add test/goldens/
git commit -m "Update button styling"
```

### 7. Set Fixed Dimensions

Wrap widgets in constrained containers:

```dart
testWidgets('fixed size golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 300,
        height: 200,
        child: MyWidget(),
      ),
    ),
  );

  await expectLater(
    find.byType(SizedBox),
    matchesGoldenFile('goldens/widget_300x200.png'),
  );
});
```

### 8. Test Edge Cases

Include edge cases in golden tests:

```dart
testWidgets('long text overflow', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 200,
        child: Text('This is a very long text that will overflow'),
      ),
    ),
  );

  await expectLater(
    find.byType(SizedBox),
    matchesGoldenFile('goldens/text_overflow.png'),
  );
});

testWidgets('empty state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: EmptyStateWidget()),
  );

  await expectLater(
    find.byType(EmptyStateWidget),
    matchesGoldenFile('goldens/empty_state.png'),
  );
});
```

## Summary

Golden tests validate visual consistency:

- **Use `matchesGoldenFile()`** to compare rendered output
- **Generate goldens** with `flutter test --update-goldens`
- **Test responsive layouts** at different screen sizes
- **Test theme variations** for light, dark, and custom themes
- **Keep goldens small** by testing individual components
- **Use stable test data** to ensure consistent renders
- **Review changes carefully** when updating golden files
- **Automate in CI** to catch unintended visual regressions
- **Test multiple states** (enabled, disabled, loading, error)
- **Use descriptive names** for golden files

Golden tests are powerful tools for maintaining visual consistency and catching unintended UI regressions in Flutter applications.
