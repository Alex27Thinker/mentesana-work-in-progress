---
name: flutter-core:flutter-state-management
description: >
  Comprehensive Flutter state management guidance covering built-in solutions, Provider, BLoC, and Riverpod.
  Use when working with state management, sharing data between widgets, managing app state,
  implementing reactive patterns, choosing state solutions, setState, ValueNotifier, ChangeNotifier,
  InheritedWidget, Provider package, BLoC pattern, Riverpod, state architecture, or comparing state management approaches.
trigger_phrases:
  - state management
  - manage state
  - share data between widgets
  - app state
  - ephemeral state
  - setState
  - ValueNotifier
  - ChangeNotifier
  - InheritedWidget
  - Provider
  - ChangeNotifierProvider
  - MultiProvider
  - BLoC pattern
  - flutter_bloc
  - Riverpod
  - StateProvider
  - FutureProvider
  - StreamBuilder
  - FutureBuilder
  - reactive programming
  - state architecture
  - which state management
  - choose state solution
---

# Flutter State Management

A comprehensive guide to managing state in Flutter applications, from simple built-in solutions to sophisticated state management patterns. This skill helps you understand the state management landscape, choose the right solution for your needs, and implement it effectively.

## Philosophy: Start Simple, Evolve When Needed

Flutter's official philosophy advocates for a pragmatic approach to state management: start with the simplest solution that works, and graduate to more complex patterns only when your application's complexity demands it. This "simple-first" approach prevents over-engineering while ensuring your codebase can scale gracefully.

The key insight is that there is no single "best" state management solution—the right choice depends on your specific requirements, team size, application complexity, and architectural preferences.

## Understanding State Types

Before choosing a state management solution, it's crucial to understand the fundamental distinction between two types of state in Flutter applications.

### Ephemeral State

Ephemeral state (also called UI state or local state) is state that is scoped to a single widget and doesn't need to be shared across the app. This includes:

- Current page in a PageView
- Animation progress or controller state
- Selected tab in a BottomNavigationBar
- Whether a panel is expanded or collapsed
- Current value in a TextField

For ephemeral state, `setState()` is the recommended solution. It's simple, performant, and keeps your code straightforward. Don't reach for complex state management solutions when `setState()` will suffice.

### App State

App state (also called shared state or application state) is state that needs to be shared across multiple widgets or persisted beyond a single screen. This includes:

- User authentication status and profile data
- Shopping cart contents
- User preferences and settings
- Data fetched from APIs
- Application-wide themes or configurations

App state requires a dedicated state management approach to ensure data flows correctly through your widget tree and updates are propagated efficiently.

## The State Management Spectrum

Flutter offers a spectrum of state management solutions, from built-in lightweight options to full-featured architectural patterns:

### Level 1: Built-in Solutions (Start Here)
- **setState()**: For ephemeral widget state
- **ValueNotifier & ValueListenableBuilder**: For simple reactive values
- **ChangeNotifier**: For custom observable objects
- **InheritedWidget**: For propagating data down the tree
- **StreamBuilder & FutureBuilder**: For async data

### Level 2: Lightweight Packages
- **Provider**: Flutter's recommended lightweight solution
- **Riverpod**: Modern, type-safe evolution of Provider

### Level 3: Architectural Patterns
- **BLoC**: Event-driven architecture with strict separation
- **Redux**: Unidirectional data flow with single source of truth
- **MobX**: Observable reactive programming

## Decision Tree: Choosing Your State Management Solution

Use this decision tree to select the appropriate state management approach:

### Question 1: Is this ephemeral or app state?

**If ephemeral (widget-scoped):**
→ Use `setState()` or `ValueNotifier`
→ No additional packages needed
→ **Stop here—you're done!**

**If app state (shared across widgets):**
→ Continue to Question 2

### Question 2: What's your application complexity?

**Simple app (1-3 screens, minimal shared state):**
→ Use `InheritedWidget` or `ValueNotifier` with `InheritedNotifier`
→ Consider Provider if you want a cleaner API
→ **References**: [Built-in State](references/built-in-state.md), [Provider Patterns](references/provider-patterns.md)

**Medium complexity (5-10 screens, moderate shared state):**
→ Use **Provider** for simplicity and community support
→ Use **Riverpod** for type safety and modern features
→ **References**: [Provider Patterns](references/provider-patterns.md), [Riverpod Guide](references/riverpod-guide.md)

**Large/Enterprise app (10+ screens, complex state flows):**
→ Use **Riverpod** for flexibility and compile-time safety
→ Use **BLoC** for strict architecture and enterprise requirements
→ **References**: [BLoC Architecture](references/bloc-architecture.md), [State Comparison](references/state-comparison.md)

### Question 3: Do you have special requirements?

**Need event-driven architecture with audit trails?**
→ Use **BLoC** (excellent for regulated industries)
→ **Reference**: [BLoC Architecture](references/bloc-architecture.md)

**Want compile-time safety and no BuildContext dependency?**
→ Use **Riverpod** (catches errors at compile time)
→ **Reference**: [Riverpod Guide](references/riverpod-guide.md)

**Working with streams extensively?**
→ Use **BLoC** or **StreamBuilder** with built-in solutions
→ **Reference**: [Built-in State](references/built-in-state.md)

**Team prefers simple, familiar patterns?**
→ Use **Provider** (gentle learning curve)
→ **Reference**: [Provider Patterns](references/provider-patterns.md)

## Core Principles for Effective State Management

Regardless of which solution you choose, follow these principles:

### 1. Think Declaratively

Flutter uses a declarative paradigm where **UI = f(state)**. Your UI should be a pure function of your state. Instead of imperatively updating widgets, change the state and let Flutter rebuild the affected widgets.

```dart
// Imperative (wrong approach)
void updateCounter() {
  counterText.text = count.toString();
}

// Declarative (Flutter way)
void updateCounter() {
  setState(() {
    count++;
  });
  // UI automatically reflects the new state
}
```

### 2. Separate Concerns

Keep your business logic separate from your UI code. State management solutions should handle:
- **Business Logic**: Data transformations, calculations, API calls
- **State**: Current application data
- **UI Logic**: Widget structure and presentation

Your widgets should be thin presentation layers that react to state changes, not contain business logic.

### 3. Minimize Rebuilds

Only rebuild widgets that actually depend on changed state. Use:
- `ValueListenableBuilder` for single values
- `Consumer` or `Selector` in Provider
- `ref.watch()` in Riverpod with granular dependencies
- `BlocBuilder` in BLoC

Avoid rebuilding entire screens when only a small portion needs to update.

### 4. Make State Predictable

State changes should be:
- **Traceable**: Easy to understand what caused a state change
- **Testable**: Business logic can be tested independently
- **Debuggable**: State history can be inspected

### 5. Handle Async Operations Properly

Async state (loading, error, data) is common in real applications. Use:
- `FutureBuilder` and `StreamBuilder` for simple cases
- Provider's `FutureProvider` or Riverpod's `AsyncValue`
- BLoC's event-state pattern with loading states

## Common Patterns and Use Cases

### Pattern 1: Counter App (Learning)
The classic Flutter counter demonstrates basic state management concepts. See how the same app can be implemented with different solutions:
→ **Example**: [Simple State Examples](examples/simple-state.md)

### Pattern 2: Form State (Ephemeral)
Form inputs, validation, and temporary UI state should generally stay local:
- Use `TextEditingController` for text inputs
- Use `setState()` for validation state
- Only elevate to app state if form data needs to be shared

### Pattern 3: Authentication State (App State)
User login status is shared across the entire app:
- Store user data and auth token in app state
- Protect routes based on auth state
- Make auth state available globally
→ **References**: [Provider Patterns](references/provider-patterns.md), [Riverpod Guide](references/riverpod-guide.md)

### Pattern 4: Shopping Cart (Complex App State)
Shopping carts demonstrate complex state with multiple operations:
- Adding/removing items
- Calculating totals
- Persisting across sessions
- Synchronizing with backend
→ **Example**: [Complex State Examples](examples/complex-state.md)

### Pattern 5: Real-time Data (Streams)
Chat apps, live dashboards, and real-time updates:
- Use `StreamBuilder` with built-in solutions
- Use `StreamProvider` in Provider/Riverpod
- Use BLoC for complex stream transformations
→ **Reference**: [Built-in State](references/built-in-state.md)

## Migration and Coexistence

State management solutions can coexist in the same app, enabling gradual migration:

### Migrating from setState to Provider
1. Identify shared state currently passed through constructors
2. Create `ChangeNotifier` classes for that state
3. Wrap app in `ChangeNotifierProvider`
4. Use `Consumer` or `Provider.of()` to access state
5. Remove prop drilling

### Migrating from Provider to Riverpod
1. Add Riverpod dependencies alongside Provider
2. Wrap app in `ProviderScope` (can coexist with `MultiProvider`)
3. Migrate features one at a time
4. Use `@riverpod` generators for new code
5. Remove Provider once fully migrated

### When NOT to Migrate
If your current solution:
- Works reliably without bugs
- Has good test coverage
- Team understands it well
- Meets performance requirements

Then focus on new features rather than migration. Only migrate if you have clear pain points.

## State Management and Architecture

State management is closely tied to your app architecture:

### MVVM (Model-View-ViewModel)
- **Model**: Data classes and repositories
- **View**: Flutter widgets
- **ViewModel**: `ChangeNotifier` or `StateNotifier` holding state
- Works well with Provider and Riverpod
→ **Cross-reference**: flutter-architecture skill

### BLoC/Clean Architecture
- **Presentation**: Widgets and BLoC/Cubit
- **Domain**: Use cases and entities
- **Data**: Repositories and data sources
- Enforces strict separation of concerns
→ **Reference**: [BLoC Architecture](references/bloc-architecture.md)

### Repository Pattern
- Abstract data sources behind repository interfaces
- State management layer calls repositories
- Works with any state solution
→ **Cross-reference**: flutter-data-networking skill

## Testing State Management

All state management solutions should be thoroughly testable:

### Unit Testing State Logic
Test business logic independently of Flutter:
```dart
test('counter increments', () {
  final counter = CounterNotifier();
  counter.increment();
  expect(counter.value, 1);
});
```

### Widget Testing with State
Test widgets with mocked state:
- Provider: Use custom `ProviderScope` overrides
- Riverpod: Use `ProviderContainer` with overrides
- BLoC: Use `BlocProvider.value()` with test blocs

### Integration Testing
Test complete features with real state management:
- Verify state propagates correctly
- Test async state transitions
- Verify UI responds to state changes

## Performance Considerations

### Memory Management
- Dispose controllers, notifiers, and streams
- Use `autoDispose` in Riverpod
- Avoid memory leaks from lingering listeners

### Rebuild Optimization
- Use `const` constructors where possible
- Implement `select()` or `Selector` for granular dependencies
- Profile rebuilds with Flutter DevTools

### State Persistence
- Use `shared_preferences` for simple key-value data
- Use `hive` or `sqflite` for structured data
- Implement state hydration on app startup

## Next Steps: Dive Deeper

Now that you understand the state management landscape, explore specific solutions:

### For Beginners
Start with **Built-in State Solutions**:
→ [Built-in State](references/built-in-state.md)
→ [Simple State Examples](examples/simple-state.md)

### For Production Apps
Choose between **Provider** and **Riverpod**:
→ [Provider Patterns](references/provider-patterns.md)
→ [Riverpod Guide](references/riverpod-guide.md)
→ [State Comparison](references/state-comparison.md)

### For Enterprise Applications
Consider **BLoC** for strict architecture:
→ [BLoC Architecture](references/bloc-architecture.md)
→ [Complex State Examples](examples/complex-state.md)

### For Decision Making
Compare all solutions:
→ [State Comparison](references/state-comparison.md)

## Related Skills

- **flutter-ui-widgets**: StatefulWidget and widget lifecycle
- **flutter-architecture**: MVVM, Clean Architecture patterns
- **flutter-data-networking**: Async state from APIs
- **flutter-testing**: Testing state management implementations

## Remember

State management is not about choosing the "best" solution—it's about choosing the **right** solution for your specific needs. Start simple with built-in solutions, and evolve your approach as your application grows in complexity. Focus on principles (declarative UI, separation of concerns, testability) rather than dogma about specific packages.
