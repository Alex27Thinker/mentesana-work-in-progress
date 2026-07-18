# Keyboard and Focus Management Reference

Comprehensive guide to keyboard input, focus management, and navigation in Flutter applications.

## Table of Contents

- [Focus System Overview](#focus-system-overview)
- [FocusNode](#focusnode)
- [Focus Widget](#focus-widget)
- [FocusScope](#focusscope)
- [Focus Traversal](#focus-traversal)
- [Keyboard Input](#keyboard-input)
- [TextInputAction](#textinputaction)
- [Keyboard Types](#keyboard-types)
- [Input Formatters](#input-formatters)
- [Key Event Handling](#key-event-handling)

## Focus System Overview

Flutter's focus system directs keyboard input to specific parts of your application. It's essential for:
- Keyboard navigation (especially on desktop/web)
- Accessibility
- Form field management
- Text input handling

### Core Concepts

**FocusNode**: A long-lived object representing focus state for a widget. Must be created in State and disposed properly.

**FocusScope**: Groups FocusNodes and manages focus history within a subtree.

**Focus Widget**: Owns and manages a FocusNode, providing callbacks and integration.

**Primary Focus**: The currently focused node that receives keyboard input.

### Focus Lifecycle

```
1. FocusNode created in State.initState()
2. Focus widget associates node with widget tree
3. Node can request/release focus
4. Focus changes trigger callbacks
5. FocusNode disposed in State.dispose()
```

## FocusNode

FocusNode is the fundamental building block of the focus system.

### Creating and Managing FocusNode

```dart
class _MyWidgetState extends State<MyWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: 'MyWidget', // Helpful for debugging
      descendantsAreFocusable: true, // Default
      skipTraversal: false, // Default
    );

    // Listen for focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        print('Gained focus');
      } else {
        print('Lost focus');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Always dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: TextField(),
    );
  }
}
```

### FocusNode Methods

**requestFocus()**: Request focus for this node.

```dart
_focusNode.requestFocus();
```

**unfocus()**: Remove focus from this node (and descendants).

```dart
_focusNode.unfocus();
```

**nextFocus()**: Move focus to next node in traversal order.

```dart
_focusNode.nextFocus();
```

**previousFocus()**: Move focus to previous node in traversal order.

```dart
_focusNode.previousFocus();
```

**hasFocus**: Check if this node has focus.

```dart
if (_focusNode.hasFocus) {
  print('Has focus');
}
```

**hasPrimaryFocus**: Check if this node has primary focus.

```dart
if (_focusNode.hasPrimaryFocus) {
  print('Has primary focus');
}
```

### FocusNode Listeners

```dart
@override
void initState() {
  super.initState();
  _focusNode = FocusNode();

  // Listen for focus changes
  _focusNode.addListener(_onFocusChange);
}

void _onFocusChange() {
  setState(() {
    // Update UI based on focus state
  });
}

@override
void dispose() {
  _focusNode.removeListener(_onFocusChange);
  _focusNode.dispose();
  super.dispose();
}
```

### FocusNode Properties

**canRequestFocus**: Whether this node can receive focus.

```dart
_focusNode = FocusNode(canRequestFocus: false);
```

**skipTraversal**: Skip this node in tab traversal but allow explicit focus.

```dart
_focusNode = FocusNode(skipTraversal: true);
```

**descendantsAreFocusable**: Control whether descendants can be focused.

```dart
_focusNode = FocusNode(descendantsAreFocusable: false);
```

## Focus Widget

The Focus widget owns and manages a FocusNode, integrating it with the widget tree.

### Basic Focus Widget

```dart
Focus(
  focusNode: _focusNode, // Optional - creates one if not provided
  autofocus: false, // Request focus on first build
  onFocusChange: (hasFocus) {
    print('Focus changed: $hasFocus');
  },
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent) {
      print('Key pressed: ${event.logicalKey}');
    }
    return KeyEventResult.ignored;
  },
  child: Container(
    width: 200,
    height: 100,
    color: Colors.blue,
  ),
)
```

### Focus with Visual Feedback

```dart
class FocusableContainer extends StatefulWidget {
  @override
  State<FocusableContainer> createState() => _FocusableContainerState();
}

class _FocusableContainerState extends State<FocusableContainer> {
  late FocusNode _focusNode;
  Color _color = Colors.white;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'FocusableContainer');
    _focusNode.addListener(() {
      setState(() {
        _color = _focusNode.hasFocus ? Colors.blue[100]! : Colors.white;
      });
    });
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
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          width: 200,
          height: 100,
          color: _color,
          alignment: Alignment.center,
          child: Text(
            _focusNode.hasFocus ? 'Focused' : 'Unfocused',
          ),
        ),
      ),
    );
  }
}
```

### Autofocus

```dart
Focus(
  autofocus: true, // Request focus when first built
  child: TextField(),
)
```

**Important**: Only one widget should have autofocus: true in a route. If multiple widgets request autofocus, the last one wins.

### Obtaining Focus Information

```dart
@override
Widget build(BuildContext context) {
  return Focus(
    child: Builder(
      builder: (context) {
        final focusNode = Focus.of(context);
        final hasFocus = focusNode.hasFocus;
        final hasPrimaryFocus = focusNode.hasPrimaryFocus;

        return Container(
          color: hasFocus ? Colors.blue : Colors.grey,
          child: Text('Has focus: $hasFocus'),
        );
      },
    ),
  );
}
```

## FocusScope

FocusScope groups focus nodes and manages focus history within a subtree.

### Basic FocusScope

```dart
FocusScope(
  child: Column(
    children: [
      TextField(),
      TextField(),
      TextField(),
      // Focus traversal stays within this scope
      // unless explicitly focused outside
    ],
  ),
)
```

### FocusScope Methods

Access FocusScope methods through the context:

```dart
// Move to next field
FocusScope.of(context).nextFocus();

// Move to previous field
FocusScope.of(context).previousFocus();

// Unfocus all fields in scope
FocusScope.of(context).unfocus();

// Request focus for a specific node
FocusScope.of(context).requestFocus(_focusNode);
```

### Scoped Focus Management

```dart
class FormWithScope extends StatefulWidget {
  @override
  State<FormWithScope> createState() => _FormWithScopeState();
}

class _FormWithScopeState extends State<FormWithScope> {
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Column(
        children: [
          TextField(
            focusNode: _nameFocus,
            decoration: InputDecoration(labelText: 'Name'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          TextField(
            focusNode: _emailFocus,
            decoration: InputDecoration(labelText: 'Email'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          TextField(
            focusNode: _phoneFocus,
            decoration: InputDecoration(labelText: 'Phone'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }
}
```

## Focus Traversal

Control the order in which widgets receive focus when user presses Tab.

### FocusTraversalGroup

```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1),
        child: TextField(),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(3),
        child: TextField(),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2),
        child: TextField(),
      ),
    ],
  ),
)
```

### Traversal Policies

**OrderedTraversalPolicy**: Use explicit FocusOrder objects.

```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: // ...
)
```

**ReadingOrderTraversalPolicy**: Traverse in reading order (left-to-right, top-to-bottom).

```dart
FocusTraversalGroup(
  policy: ReadingOrderTraversalPolicy(),
  child: // ...
)
```

**WidgetOrderTraversalPolicy**: Traverse in widget tree order (default).

```dart
FocusTraversalGroup(
  policy: WidgetOrderTraversalPolicy(),
  child: // ...
)
```

### Custom Focus Order

```dart
class CustomFocusOrder extends FocusOrder {
  final int value;

  const CustomFocusOrder(this.value);

  @override
  int compareTo(FocusOrder other) {
    if (other is CustomFocusOrder) {
      return value.compareTo(other.value);
    }
    return -1;
  }
}

// Usage
FocusTraversalOrder(
  order: CustomFocusOrder(5),
  child: TextField(),
)
```

## Keyboard Input

### TextInputAction

Configure the keyboard action button (e.g., "Next", "Done", "Search").

```dart
TextField(
  textInputAction: TextInputAction.next,
  onSubmitted: (value) {
    FocusScope.of(context).nextFocus();
  },
)
```

### Available TextInputAction Values

```dart
TextInputAction.none          // No action button
TextInputAction.unspecified   // Default platform action
TextInputAction.done          // "Done" button
TextInputAction.go            // "Go" button
TextInputAction.search        // "Search" button
TextInputAction.send          // "Send" button
TextInputAction.next          // "Next" button
TextInputAction.previous      // "Previous" button
TextInputAction.continueAction // "Continue" button
TextInputAction.join          // "Join" button
TextInputAction.route         // "Route" button
TextInputAction.emergencyCall // "Emergency Call" button
TextInputAction.newline       // "New line" button
```

### Practical Form with TextInputAction

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    print('Login submitted');
    FocusScope.of(context).unfocus(); // Close keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          focusNode: _emailFocus,
          decoration: InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        TextField(
          focusNode: _passwordFocus,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
        ),
        ElevatedButton(
          onPressed: _login,
          child: Text('Login'),
        ),
      ],
    );
  }
}
```

## Keyboard Types

Control which keyboard layout is shown to the user.

### Available Keyboard Types

```dart
// Text keyboard (default)
TextField(
  keyboardType: TextInputType.text,
)

// Multiline text with newline button
TextField(
  keyboardType: TextInputType.multiline,
  maxLines: null,
)

// Number keyboard
TextField(
  keyboardType: TextInputType.number,
)

// Phone number keyboard
TextField(
  keyboardType: TextInputType.phone,
)

// Date/time keyboard
TextField(
  keyboardType: TextInputType.datetime,
)

// Email keyboard (includes @ and .)
TextField(
  keyboardType: TextInputType.emailAddress,
)

// URL keyboard (includes / and .)
TextField(
  keyboardType: TextInputType.url,
)

// Visible password keyboard
TextField(
  keyboardType: TextInputType.visiblePassword,
)
```

### Number Keyboard with Decimal

```dart
TextField(
  keyboardType: TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  ),
)
```

## Input Formatters

TextInputFormatter restricts and formats user input.

### Built-in Formatters

**FilteringTextInputFormatter**: Allow or deny specific characters.

```dart
// Allow only digits
TextField(
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
)

// Allow only letters
TextField(
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
  ],
)

// Deny specific characters
TextField(
  inputFormatters: [
    FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
  ],
)
```

**LengthLimitingTextInputFormatter**: Limit input length.

```dart
TextField(
  inputFormatters: [
    LengthLimitingTextInputFormatter(10),
  ],
)
```

**UpperCaseTextFormatter / LowerCaseTextFormatter**: Force case.

```dart
TextField(
  inputFormatters: [
    UpperCaseTextFormatter(),
  ],
)

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
```

### Custom Input Formatters

**Phone Number Formatter**:

```dart
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Format as (XXX) XXX-XXXX
    String formatted = '';
    if (digitsOnly.length > 0) {
      formatted = '(${digitsOnly.substring(0, min(3, digitsOnly.length))}';
    }
    if (digitsOnly.length > 3) {
      formatted += ') ${digitsOnly.substring(3, min(6, digitsOnly.length))}';
    }
    if (digitsOnly.length > 6) {
      formatted += '-${digitsOnly.substring(6, min(10, digitsOnly.length))}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Usage
TextField(
  keyboardType: TextInputType.phone,
  inputFormatters: [
    PhoneNumberFormatter(),
  ],
)
```

**Credit Card Formatter**:

```dart
class CreditCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Limit to 16 digits
    final limitedDigits = digitsOnly.substring(
      0,
      min(16, digitsOnly.length),
    );

    // Format as XXXX XXXX XXXX XXXX
    String formatted = '';
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += limitedDigits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

**Currency Formatter**:

```dart
class CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Convert to cents
    final cents = int.parse(digitsOnly);
    final dollars = cents / 100;

    // Format as currency
    final formatted = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(dollars);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

### Combining Multiple Formatters

```dart
TextField(
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
    PhoneNumberFormatter(),
  ],
)
```

## Key Event Handling

Handle keyboard events at the Focus widget level.

### Basic Key Event Handling

```dart
Focus(
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        print('Enter pressed');
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: TextField(),
)
```

### Key Event Results

**KeyEventResult.handled**: Event was handled, stop propagation.

**KeyEventResult.ignored**: Event not handled, continue propagation.

**KeyEventResult.skipRemainingHandlers**: Skip siblings but allow parent handlers.

### Blocking Specific Keys

```dart
Focus(
  onKeyEvent: (node, event) {
    // Block letter 'A'
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: TextField(),
)
```

### Keyboard Shortcuts

```dart
class ShortcutHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl+S or Cmd+S
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              (HardwareKeyboard.instance.isControlPressed ||
               HardwareKeyboard.instance.isMetaPressed)) {
            print('Save shortcut');
            return KeyEventResult.handled;
          }

          // Ctrl+Z or Cmd+Z
          if (event.logicalKey == LogicalKeyboardKey.keyZ &&
              (HardwareKeyboard.instance.isControlPressed ||
               HardwareKeyboard.instance.isMetaPressed)) {
            print('Undo shortcut');
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(),
    );
  }
}
```

### Arrow Key Navigation

```dart
Focus(
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        print('Navigate up');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        print('Navigate down');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        print('Navigate left');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        print('Navigate right');
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: Container(),
)
```

## Best Practices

1. **Always dispose FocusNode**: Create in initState, dispose in dispose
2. **Use debugLabel**: Makes debugging focus issues much easier
3. **Don't create FocusNode in build**: Causes memory leaks and unexpected behavior
4. **Use FocusScope.of(context)**: Better than manual focus management
5. **Implement proper TextInputAction**: Improves UX, especially on mobile
6. **Choose appropriate keyboard types**: Show the right keyboard for the input
7. **Use input formatters wisely**: Format as user types for better UX
8. **Test keyboard navigation**: Essential for desktop/web applications
9. **Provide visual focus indicators**: Users need to see what's focused
10. **Handle focus changes**: Update UI appropriately when focus changes
11. **Consider autofocus carefully**: Only one widget should autofocus per route
12. **Test on multiple platforms**: Focus behavior varies across platforms
