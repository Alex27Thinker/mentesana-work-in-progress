# Test Coverage in Flutter

Test coverage measures the percentage of your code that is executed during tests. It helps identify untested code paths, guide testing efforts, and maintain code quality. While 100% coverage doesn't guarantee bug-free code, comprehensive coverage combined with meaningful tests provides confidence in your application's reliability.

## Table of Contents

- [Understanding Coverage Metrics](#understanding-coverage-metrics)
- [Generating Coverage Reports](#generating-coverage-reports)
- [Reading Coverage Reports](#reading-coverage-reports)
- [Coverage Goals and Targets](#coverage-goals-and-targets)
- [Improving Coverage](#improving-coverage)
- [Coverage in CI/CD](#coverage-in-cicd)
- [Coverage Tools and Visualization](#coverage-tools-and-visualization)
- [Excluding Code from Coverage](#excluding-code-from-coverage)
- [Coverage Best Practices](#coverage-best-practices)
- [Beyond Coverage Metrics](#beyond-coverage-metrics)

## Understanding Coverage Metrics

Coverage reports track several metrics to measure test completeness.

### Line Coverage

Percentage of code lines executed during tests:

```dart
// Example function
int calculateDiscount(int price, bool isPremium) {
  if (isPremium) {                    // Line 1
    return (price * 0.8).toInt();     // Line 2 - Not covered
  }
  return price;                       // Line 3 - Covered
}

// Test only covers non-premium path
test('calculates regular price', () {
  expect(calculateDiscount(100, false), 100);
});

// Coverage: 2/3 lines = 66.67%
```

### Branch Coverage

Percentage of code branches (if/else, switch cases) tested:

```dart
int getShippingCost(int total, String country) {
  if (country == 'US') {              // Branch 1
    return 5;
  } else if (country == 'CA') {       // Branch 2 - Not covered
    return 8;
  } else {                            // Branch 3 - Not covered
    return 12;
  }
}

// Test only covers one branch
test('US shipping cost', () {
  expect(getShippingCost(100, 'US'), 5);
});

// Branch coverage: 1/3 branches = 33.33%
```

### Function Coverage

Percentage of functions called during tests:

```dart
class Calculator {
  int add(int a, int b) => a + b;           // Tested
  int subtract(int a, int b) => a - b;      // Tested
  int multiply(int a, int b) => a * b;      // Not tested
  int divide(int a, int b) => a ~/ b;       // Not tested
}

// Tests only cover add and subtract
test('addition', () {
  expect(Calculator().add(2, 3), 5);
});

test('subtraction', () {
  expect(Calculator().subtract(5, 3), 2);
});

// Function coverage: 2/4 functions = 50%
```

### Statement Coverage

Similar to line coverage but counts individual statements:

```dart
String formatName(String? first, String? last) {
  final firstName = first ?? 'Unknown';     // Statement 1
  final lastName = last ?? 'User';          // Statement 2
  return '$firstName $lastName';            // Statement 3
}

// All statements covered
test('formats name with both values', () {
  expect(formatName('John', 'Doe'), 'John Doe');
});

// Statement coverage: 3/3 = 100%
```

## Generating Coverage Reports

Flutter provides built-in coverage generation using LCOV format.

### Basic Coverage Generation

```bash
# Generate coverage data
flutter test --coverage

# Coverage data saved to: coverage/lcov.info
```

### Generate HTML Report

```bash
# Install lcov (macOS)
brew install lcov

# Install lcov (Linux)
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Coverage for Specific Tests

```bash
# Run specific test file with coverage
flutter test test/services/user_service_test.dart --coverage

# Run tests matching name pattern
flutter test --name="UserService" --coverage
```

### Coverage Script

Create a script for consistent coverage generation:

```bash
#!/bin/bash
# scripts/coverage.sh

# Clean previous coverage
rm -rf coverage

# Run tests with coverage
flutter test --coverage

# Remove generated files from coverage
lcov --remove coverage/lcov.info \
  'lib/**/*.g.dart' \
  'lib/**/*.freezed.dart' \
  'lib/generated/**' \
  -o coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

Make it executable:

```bash
chmod +x scripts/coverage.sh
./scripts/coverage.sh
```

## Reading Coverage Reports

Understanding coverage output helps identify gaps.

### LCOV Format

Raw coverage data in `coverage/lcov.info`:

```
SF:lib/services/user_service.dart
DA:10,1
DA:11,1
DA:12,0
DA:13,1
LH:3
LF:4
end_of_record
```

- `SF`: Source file
- `DA:line,hits`: Line number and execution count
- `LH`: Lines hit
- `LF`: Lines found
- Coverage: 3/4 = 75%

### HTML Report

HTML report (`coverage/html/index.html`) provides:

- **Overview**: Total coverage percentage
- **File list**: Coverage per file
- **Drill-down**: Click file to see line-by-line coverage
- **Color coding**: Green (covered), red (not covered)

### Console Output

```bash
# View coverage summary in terminal
lcov --list coverage/lcov.info

# View uncovered lines
lcov --list coverage/lcov.info | grep -E '0\.[0-9]+%|^[^0-9]*0%'
```

## Coverage Goals and Targets

Set realistic coverage targets based on code type.

### General Guidelines

**Overall Coverage: 70-80%**
- Good baseline for most applications
- Balances testing effort with value
- Focus on critical paths

**Business Logic: 90%+**
- Critical calculations
- Data validation
- Business rules
- Payment processing

**UI Code: 50-60%**
- Widget tests are more valuable than coverage
- Complex UI logic should be tested
- Simple presentational code can be lower

**Utilities: 100%**
- Pure functions
- Helpers and formatters
- Validation functions

**Generated Code: 0%**
- Exclude `*.g.dart`, `*.freezed.dart`
- No value in testing generated code

### File-Specific Targets

```yaml
# coverage_config.yaml
targets:
  lib/models/**:
    coverage: 80
  lib/services/**:
    coverage: 90
  lib/utils/**:
    coverage: 95
  lib/ui/widgets/**:
    coverage: 60
```

### Tracking Coverage Over Time

```bash
# Save coverage percentage
coverage_percent=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}')
echo "Coverage: $coverage_percent"

# Track in CI
echo "COVERAGE=$coverage_percent" >> $GITHUB_ENV
```

## Improving Coverage

Strategies for increasing test coverage effectively.

### Identify Uncovered Code

```bash
# Find files with low coverage
lcov --list coverage/lcov.info | grep -E '[0-4][0-9]\.[0-9]+%'

# List uncovered lines
lcov --list coverage/lcov.info | grep ': 0'
```

### Prioritize Critical Code

Focus testing efforts on:

1. **Business Logic**: Core functionality
2. **Data Transformations**: Parsing, formatting
3. **Error Handling**: Exception paths
4. **Security**: Authentication, authorization
5. **Payment**: Financial transactions

### Test Edge Cases

```dart
// Current: Only tests happy path
test('formats currency', () {
  expect(formatCurrency(100), '\$100.00');
});

// Improved: Tests edge cases
group('formatCurrency', () {
  test('formats positive amount', () {
    expect(formatCurrency(100), '\$100.00');
  });

  test('formats negative amount', () {
    expect(formatCurrency(-50), '-\$50.00');
  });

  test('formats zero', () {
    expect(formatCurrency(0), '\$0.00');
  });

  test('handles very large numbers', () {
    expect(formatCurrency(1000000), '\$1,000,000.00');
  });

  test('handles decimal precision', () {
    expect(formatCurrency(99.99), '\$99.99');
  });
});
```

### Test Error Paths

```dart
class ApiService {
  Future<User> fetchUser(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    try {
      final response = await http.get(Uri.parse('/users/$id'));

      if (response.statusCode == 404) {
        throw UserNotFoundException();
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to fetch user');
      }

      return User.fromJson(jsonDecode(response.body));
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }
}

// Comprehensive tests covering all paths
group('ApiService.fetchUser', () {
  test('throws on empty id', () {
    expect(() => service.fetchUser(''), throwsArgumentError);
  });

  test('returns user on success', () async {
    final user = await service.fetchUser('123');
    expect(user.id, '123');
  });

  test('throws UserNotFoundException on 404', () {
    expect(
      () => service.fetchUser('missing'),
      throwsA(isA<UserNotFoundException>()),
    );
  });

  test('throws ApiException on server error', () {
    expect(
      () => service.fetchUser('error'),
      throwsA(isA<ApiException>()),
    );
  });

  test('throws ApiException on network error', () {
    expect(
      () => service.fetchUser('network-fail'),
      throwsA(isA<ApiException>()),
    );
  });
});
```

### Add Parametrized Tests

```dart
// Test multiple scenarios efficiently
group('validateEmail', () {
  final testCases = [
    ('valid@example.com', true),
    ('user@domain.co.uk', true),
    ('invalid', false),
    ('', false),
    ('no-at-sign.com', false),
    ('@no-local.com', false),
    ('no-domain@.com', false),
  ];

  for (final (email, isValid) in testCases) {
    test('validates "$email" as ${isValid ? "valid" : "invalid"}', () {
      expect(validateEmail(email), isValid);
    });
  }
});
```

## Coverage in CI/CD

Automate coverage tracking in continuous integration.

### GitHub Actions

```yaml
# .github/workflows/coverage.yml
name: Test Coverage

on: [push, pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Install lcov
        run: sudo apt-get install -y lcov

      - name: Generate coverage report
        run: |
          lcov --remove coverage/lcov.info \
            'lib/**/*.g.dart' \
            'lib/**/*.freezed.dart' \
            -o coverage/lcov.info
          lcov --list coverage/lcov.info

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
          fail_ci_if_error: true

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | cut -d'%' -f1)
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage below 70% threshold"
            exit 1
          fi
```

### Coverage Badges

Add coverage badge to README:

```markdown
# My Flutter App

[![Coverage](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)
```

### Enforce Coverage Thresholds

```bash
#!/bin/bash
# Fail if coverage drops below threshold

THRESHOLD=75
COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | cut -d'%' -f1)

echo "Current coverage: $COVERAGE%"
echo "Required threshold: $THRESHOLD%"

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "❌ Coverage below threshold!"
  exit 1
else
  echo "✅ Coverage meets threshold"
  exit 0
fi
```

### Pull Request Comments

Automatically comment coverage on PRs:

```yaml
- name: Comment coverage on PR
  uses: romeovs/lcov-reporter-action@v0.3.1
  with:
    lcov-file: coverage/lcov.info
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Coverage Tools and Visualization

Tools for better coverage insights.

### Codecov

Cloud-based coverage reporting:

1. Sign up at [codecov.io](https://codecov.io)
2. Add repository
3. Configure in GitHub Actions (see above)
4. View reports on Codecov dashboard

**Features:**
- Diff coverage (changes only)
- Coverage trends over time
- File explorer with coverage
- PR comments with coverage changes

### Coveralls

Alternative to Codecov:

```yaml
- name: Upload to Coveralls
  uses: coverallsapp/github-action@master
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    path-to-lcov: coverage/lcov.info
```

### Local Coverage Server

```bash
# Serve coverage report locally
cd coverage/html
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

### VS Code Coverage Extension

Install "Coverage Gutters" extension:

1. Generate coverage: `flutter test --coverage`
2. Open command palette
3. Run "Coverage Gutters: Display Coverage"
4. See coverage in editor gutter

## Excluding Code from Coverage

Some code doesn't need coverage tracking.

### Exclude Generated Files

```bash
# Remove generated files from coverage
lcov --remove coverage/lcov.info \
  'lib/**/*.g.dart' \
  'lib/**/*.freezed.dart' \
  'lib/generated/**' \
  -o coverage/lcov.info
```

### Exclude Specific Lines

Use `// coverage:ignore-line`:

```dart
void debugOnlyFunction() {
  // coverage:ignore-line
  debugPrint('Debug information');
}
```

### Exclude Blocks

Use `// coverage:ignore-start` and `// coverage:ignore-end`:

```dart
// coverage:ignore-start
void debugFunction() {
  debugPrint('Debug 1');
  debugPrint('Debug 2');
  debugPrint('Debug 3');
}
// coverage:ignore-end
```

### Exclude Files

```bash
# Exclude entire directories
lcov --remove coverage/lcov.info \
  'lib/debug/**' \
  'lib/generated/**' \
  'test/**' \
  -o coverage/lcov.info
```

### Coverage Ignore Configuration

Create `.lcovrc`:

```
# .lcovrc
geninfo_unexecuted_blocks = 0
lcov_branch_coverage = 0
```

## Coverage Best Practices

### 1. Focus on Behavior, Not Lines

```dart
// Bad: Tests implementation details
test('uses correct variable name', () {
  final service = UserService();
  expect(service.hasOwnProperty('_users'), true);
});

// Good: Tests behavior
test('fetches users from service', () async {
  final users = await service.fetchUsers();
  expect(users, isNotEmpty);
});
```

### 2. Don't Chase 100% Coverage

```dart
// Don't test trivial code just for coverage
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  // No need to test this getter
  String get displayName => name;
}
```

### 3. Test Critical Paths First

Priority order:
1. Business logic
2. Data validation
3. Error handling
4. Edge cases
5. UI interactions

### 4. Use Coverage to Find Gaps

```bash
# Find untested files
lcov --list coverage/lcov.info | grep '0.0%'

# Review and add tests for critical files
```

### 5. Review Coverage in PRs

```bash
# Check coverage diff
lcov --diff coverage/base.info coverage/lcov.info
```

### 6. Maintain Coverage Over Time

```bash
# Track coverage history
echo "$(date),$(lcov --summary coverage/lcov.info | grep lines)" >> coverage_history.csv
```

### 7. Don't Sacrifice Test Quality

```dart
// Bad: Test that doesn't verify behavior
test('test exists', () {
  expect(true, true);
});

// Good: Meaningful test
test('calculates total correctly', () {
  final cart = ShoppingCart();
  cart.addItem(Product(price: 10));
  cart.addItem(Product(price: 20));
  expect(cart.total, 30);
});
```

## Beyond Coverage Metrics

Coverage is one metric, but quality requires more.

### Mutation Testing

Test that tests actually catch bugs:

```dart
// Original code
int add(int a, int b) => a + b;

// Mutated code
int add(int a, int b) => a - b; // Bug introduced

// Do tests catch the mutation?
test('add works', () {
  expect(add(2, 3), 5); // Would fail with mutation
});
```

### Code Review

Manual review catches issues coverage misses:
- Logic errors
- Performance problems
- Security vulnerabilities
- Design issues

### Integration Testing

Coverage doesn't capture integration issues:
- API integration
- Database operations
- Navigation flows
- Cross-screen interactions

### Performance Testing

Coverage doesn't measure performance:
- Load testing
- Memory profiling
- Frame rendering
- Network efficiency

### User Feedback

Real-world usage finds issues tests miss:
- Usability problems
- Edge cases in production
- Platform-specific bugs
- Performance under load

## Summary

Effective coverage tracking:

- **Generate coverage** with `flutter test --coverage`
- **Set realistic targets**: 70-80% overall, higher for critical code
- **Focus on behavior**, not just lines
- **Test edge cases** and error paths
- **Track in CI/CD** with automated checks
- **Use coverage tools** like Codecov or Coveralls
- **Exclude generated code** from coverage
- **Review coverage in PRs** to prevent regressions
- **Don't chase 100%** - focus on meaningful tests
- **Look beyond coverage** with mutation testing, reviews, and integration tests

Coverage is a useful metric for identifying untested code, but it's not a substitute for well-designed, meaningful tests that validate your application's behavior and reliability.
