---
name: flutter-core:flutter-forms-input
version: 1.0.0
description: Comprehensive guide to Flutter forms, validation, gestures, and input handling
applies_to:
  - "**/*.dart"
  - "**/pubspec.yaml"
dependencies:
  - flutter-core
tags:
  - flutter
  - forms
  - validation
  - gestures
  - input
  - focus
  - keyboard
last_updated: 2026-01-23
---

# Flutter Forms and Input Handling

Master Flutter's form system, validation strategies, gesture detection, and input management to create interactive, user-friendly applications.

## Overview

Flutter provides a comprehensive system for handling user input through forms, text fields, validation, gestures, and focus management. This skill covers the complete spectrum of input handling, from simple text fields to complex multi-step forms with validation, and from basic tap detection to custom gesture recognizers.

## When to Use This Skill

Use this skill when you need to:

- Build forms with validation
- Implement text input fields with proper state management
- Detect and respond to user gestures (tap, drag, swipe, scale)
- Manage keyboard focus and navigation
- Create custom input controls and validators
- Handle complex multi-step form flows
- Implement drag-and-drop functionality
- Respond to touch, mouse, or stylus input

## Core Concepts

### Form Architecture

Flutter's form system is built on several key components that work together:

**Form Widget**: The container that manages the state of multiple form fields. It uses a `GlobalKey<FormState>()` to access validation and submission methods.

**TextFormField**: The primary input widget for forms, integrating text input with validation. It automatically registers with parent Form widgets and participates in form-wide validation.

**FormState**: The state object that provides methods like `validate()`, `save()`, and `reset()`. Access it through the form's GlobalKey.

**Validators**: Functions that return error messages for invalid input or null for valid input.

### Gesture System

Flutter's gesture system operates on two layers:

**Pointer Events**: Raw data about touch, mouse, or stylus interactions (PointerDownEvent, PointerMoveEvent, PointerUpEvent, PointerCancelEvent).

**Gestures**: Semantic actions recognized from pointer events (taps, drags, scales, swipes).

The gesture system uses a competitive arena where multiple gesture recognizers compete to claim input events. This allows sophisticated gesture handling without conflicts.

### Focus Management

The focus system directs keyboard input to specific widgets:

**FocusNode**: A long-lived object that holds focus state for a widget. Must be created in State and disposed properly.

**FocusScope**: Groups focus nodes and manages focus history within a subtree.

**Focus Widget**: Owns and manages a FocusNode, providing callbacks for focus changes and key events.

## Form Implementation Patterns

### Basic Form Structure

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Name is required';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!value!.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Process form
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Processing...')),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### Validation Strategies

**Synchronous Validation**: Immediate validation during user input or on submission. Used for format checking, required fields, and simple business rules.

**Asynchronous Validation**: Validation that requires external checks (API calls, database lookups). Implement with FutureBuilder or state management.

**Real-time vs On-Submit**: Choose `autovalidateMode` based on UX needs:
- `AutovalidateMode.disabled`: Validate only on submit (default)
- `AutovalidateMode.onUserInteraction`: Validate after first interaction
- `AutovalidateMode.always`: Validate on every change (can be annoying)

### State Management

Use `TextEditingController` to:
- Access current text value
- Listen for text changes
- Set text programmatically
- Clear fields

Always dispose controllers in the `dispose()` method to prevent memory leaks.

## Gesture Detection Patterns

### GestureDetector

```dart
GestureDetector(
  onTap: () => print('Tapped'),
  onDoubleTap: () => print('Double tapped'),
  onLongPress: () => print('Long pressed'),
  onPanUpdate: (details) {
    // Handle drag
    print('Delta: ${details.delta}');
  },
  child: Container(
    width: 200,
    height: 200,
    color: Colors.blue,
  ),
)
```

### InkWell for Material Effects

```dart
InkWell(
  onTap: () => print('Tapped with ripple'),
  splashColor: Colors.blue.withOpacity(0.3),
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Tap me'),
  ),
)
```

### Gesture Conflicts

Avoid mixing conflicting gestures:
- Cannot use `onPanUpdate` with `onVerticalDragUpdate` or `onHorizontalDragUpdate`
- Gesture arena automatically resolves competition between multiple detectors
- Only callbacks that are non-null participate in gesture detection

## Focus and Keyboard Management

### FocusNode Lifecycle

```dart
class _MyWidgetState extends State<MyWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'MyWidget');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) {
        setState(() {
          // Update UI based on focus
        });
      },
      child: TextField(),
    );
  }
}
```

### Focus Control

```dart
// Request focus
_focusNode.requestFocus();

// Remove focus
_focusNode.unfocus();

// Check focus state
bool hasFocus = _focusNode.hasFocus;

// Move to next field
FocusScope.of(context).nextFocus();

// Move to previous field
FocusScope.of(context).previousFocus();
```

### TextInputAction

Configure keyboard action buttons:

```dart
TextFormField(
  textInputAction: TextInputAction.next, // Shows "Next" button
  onFieldSubmitted: (value) {
    FocusScope.of(context).nextFocus(); // Move to next field
  },
)

TextFormField(
  textInputAction: TextInputAction.done, // Shows "Done" button
  onFieldSubmitted: (value) {
    FocusScope.of(context).unfocus(); // Close keyboard
  },
)
```

### Keyboard Types

```dart
TextFormField(
  keyboardType: TextInputType.emailAddress,
  // Other options: number, phone, url, datetime, text, multiline
)
```

## Best Practices

### Forms

1. **Always use GlobalKey**: Required for accessing FormState methods
2. **Dispose controllers**: Prevent memory leaks by disposing TextEditingController and FocusNode
3. **Provide clear feedback**: Show validation errors and submission states
4. **Handle loading states**: Disable submit buttons during processing
5. **Use TextFormField over TextField**: Better integration with Form widget
6. **Validate on submission first**: Avoid annoying users with premature validation

### Gestures

1. **Prefer Material widgets**: Use InkWell, IconButton for built-in effects
2. **Avoid gesture conflicts**: Don't mix pan with horizontal/vertical drag
3. **Provide visual feedback**: Show users their gestures are detected
4. **Consider platform**: Gestures differ on mobile vs desktop vs web
5. **Use appropriate callbacks**: Only define callbacks you need for performance

### Focus

1. **Create FocusNode in State**: Never create in build method
2. **Set debugLabel**: Makes debugging focus issues easier
3. **Dispose properly**: Call dispose() on FocusNodes
4. **Use FocusScope for navigation**: Better than manual focus changes
5. **Test keyboard navigation**: Essential for accessibility and desktop apps

## Common Patterns

### Multi-Step Forms

Use a PageView or stepper widget with separate Form widgets for each step. Validate each step before allowing progression.

### Dynamic Forms

Use ListView.builder with a list of field configurations. Add/remove fields by modifying the list and calling setState.

### Autosave Forms

Listen to controller changes and debounce saves to avoid excessive operations.

### Custom Validators

Create reusable validator functions:

```dart
String? Function(String?) combineValidators(
  List<String? Function(String?)> validators,
) {
  return (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };
}
```

### Gesture Feedback

Combine GestureDetector with AnimatedContainer or Transform widgets to provide visual feedback during gestures.

## Additional Resources

- **references/form-widgets.md**: Deep dive into Form, FormState, and TextFormField
- **references/validation-patterns.md**: Synchronous, asynchronous, and complex validation
- **references/gesture-detection.md**: Complete gesture system documentation
- **references/keyboard-management.md**: Focus, keyboard types, and input actions
- **examples/complex-forms.md**: Multi-step form implementation
- **examples/custom-gestures.md**: Custom drag-and-drop example

## Troubleshooting

**Form doesn't validate**: Ensure Form has a GlobalKey and you're calling `_formKey.currentState?.validate()`.

**TextEditingController not updating**: Make sure you're not creating a new controller in build method.

**Gestures not detected**: Check that callbacks are defined and no conflicting gestures exist.

**Focus not working**: Verify FocusNode is created in State and disposed properly.

**Keyboard doesn't show**: Ensure TextField is focusable and not blocked by canRequestFocus: false.

**Memory leaks**: Always dispose TextEditingController and FocusNode in dispose method.
