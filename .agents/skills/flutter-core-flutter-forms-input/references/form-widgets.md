# Form Widgets Reference

Comprehensive guide to Flutter's form widgets, including Form, FormState, TextFormField, and related components for building robust input interfaces.

## Table of Contents

- [Form Widget](#form-widget)
- [FormState](#formstate)
- [TextFormField](#textformfield)
- [Validators](#validators)
- [TextEditingController](#texteditingcontroller)
- [InputDecoration](#inputdecoration)
- [Form Submission Patterns](#form-submission-patterns)

## Form Widget

The Form widget is a container that groups and manages multiple form fields, providing unified validation, saving, and reset functionality.

### Basic Structure

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Form fields go here
        ],
      ),
    );
  }
}
```

### Form Properties

**key**: A `GlobalKey<FormState>()` that provides access to the form's state.

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: // ...
)
```

**autovalidateMode**: Controls when validation occurs.

```dart
Form(
  autovalidateMode: AutovalidateMode.disabled, // Default
  // AutovalidateMode.onUserInteraction - After first interaction
  // AutovalidateMode.always - On every change
  child: // ...
)
```

**onWillPop**: Called when user attempts to navigate away. Return false to prevent navigation.

```dart
Form(
  onWillPop: () async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('You have unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  },
  child: // ...
)
```

**onChanged**: Called whenever any child form field changes.

```dart
Form(
  onChanged: () {
    print('Form changed');
    // Auto-save logic could go here
  },
  child: // ...
)
```

## FormState

FormState provides methods to validate, save, and reset all form fields at once.

### Validation

```dart
bool isValid = _formKey.currentState!.validate();

if (isValid) {
  // Process form
}
```

The `validate()` method:
- Calls the validator of every TextFormField in the form
- Returns true if all validators return null
- Returns false if any validator returns an error message
- Displays error messages automatically

### Saving

```dart
_formKey.currentState!.save();
```

The `save()` method:
- Calls the onSaved callback of every TextFormField
- Use this to extract values when not using controllers
- Typically called after successful validation

```dart
String? _name;
String? _email;

// In TextFormField
TextFormField(
  onSaved: (value) => _name = value,
)

// On submit
if (_formKey.currentState!.validate()) {
  _formKey.currentState!.save();
  print('Name: $_name, Email: $_email');
}
```

### Reset

```dart
_formKey.currentState!.reset();
```

The `reset()` method:
- Clears all form fields
- Removes validation error messages
- Resets to initial values if provided

## TextFormField

TextFormField is the primary input widget for forms, combining TextField functionality with form integration.

### Basic Usage

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    return null;
  },
)
```

### Key Properties

**controller**: TextEditingController for accessing and controlling the text.

```dart
final _controller = TextEditingController(text: 'Initial value');

TextFormField(
  controller: _controller,
)

// Access value
String value = _controller.text;
```

**initialValue**: Initial text value (cannot be used with controller).

```dart
TextFormField(
  initialValue: 'John Doe',
)
```

**validator**: Function that validates the input.

```dart
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 6) {
      return 'Must be at least 6 characters';
    }
    return null;
  },
)
```

**onSaved**: Called when form.save() is invoked.

```dart
String? _username;

TextFormField(
  onSaved: (value) {
    _username = value;
  },
)
```

**onChanged**: Called whenever the text changes.

```dart
TextFormField(
  onChanged: (value) {
    print('Current value: $value');
  },
)
```

**onFieldSubmitted**: Called when user submits (presses enter/done).

```dart
TextFormField(
  textInputAction: TextInputAction.next,
  onFieldSubmitted: (value) {
    FocusScope.of(context).nextFocus();
  },
)
```

**keyboardType**: Specifies the type of keyboard to show.

```dart
TextFormField(
  keyboardType: TextInputType.emailAddress,
  // number, phone, url, datetime, multiline, text
)
```

**textInputAction**: Configures the keyboard action button.

```dart
TextFormField(
  textInputAction: TextInputAction.done,
  // next, previous, search, send, go, done
)
```

**obscureText**: Hides the text (for passwords).

```dart
TextFormField(
  obscureText: true,
  decoration: InputDecoration(labelText: 'Password'),
)
```

**maxLength**: Limits the number of characters.

```dart
TextFormField(
  maxLength: 100,
  decoration: InputDecoration(
    labelText: 'Bio',
    counterText: '', // Hide counter if desired
  ),
)
```

**maxLines**: Number of lines (for multiline input).

```dart
TextFormField(
  maxLines: 5,
  keyboardType: TextInputType.multiline,
)
```

**enabled**: Controls whether the field is editable.

```dart
TextFormField(
  enabled: false, // Read-only
)
```

**readOnly**: Makes field read-only but still focusable.

```dart
TextFormField(
  readOnly: true,
  onTap: () {
    // Show date picker, for example
  },
)
```

**autovalidateMode**: Controls when validation occurs for this field.

```dart
TextFormField(
  autovalidateMode: AutovalidateMode.onUserInteraction,
  validator: // ...
)
```

## Validators

Validators are functions that return null for valid input or an error message string for invalid input.

### Built-in Validator Patterns

**Required Field**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}
```

**Minimum Length**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  if (value.length < 6) {
    return 'Must be at least 6 characters';
  }
  return null;
}
```

**Email Format**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Invalid email address';
  }
  return null;
}
```

**Phone Number**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Phone number is required';
  }
  final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');
  if (!phoneRegex.hasMatch(value)) {
    return 'Invalid phone number';
  }
  return null;
}
```

**URL Format**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) return null; // Optional

  final urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b'
  );
  if (!urlRegex.hasMatch(value)) {
    return 'Invalid URL';
  }
  return null;
}
```

**Number Range**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  final number = int.tryParse(value);
  if (number == null) {
    return 'Must be a number';
  }
  if (number < 1 || number > 100) {
    return 'Must be between 1 and 100';
  }
  return null;
}
```

**Password Strength**:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain an uppercase letter';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Password must contain a lowercase letter';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain a number';
  }
  return null;
}
```

**Matching Fields** (e.g., confirm password):

```dart
final _passwordController = TextEditingController();

// Password field
TextFormField(
  controller: _passwordController,
  obscureText: true,
  decoration: InputDecoration(labelText: 'Password'),
)

// Confirm password field
TextFormField(
  obscureText: true,
  decoration: InputDecoration(labelText: 'Confirm Password'),
  validator: (value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  },
)
```

### Custom Validator Functions

Create reusable validators:

```dart
class Validators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? Function(String?) minLength(int min) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value.length < min) {
        return 'Must be at least $min characters';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int max) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value.length > max) {
        return 'Must be at most $max characters';
      }
      return null;
    };
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  static String? Function(String?) combine(
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
}

// Usage
TextFormField(
  validator: Validators.combine([
    Validators.required,
    Validators.minLength(6),
    Validators.email,
  ]),
)
```

## TextEditingController

TextEditingController manages the text being edited and provides methods to manipulate it.

### Basic Usage

```dart
class _MyFormState extends State<MyForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // Always dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
    );
  }
}
```

### Controller Methods

**Get text**:

```dart
String value = _controller.text;
```

**Set text**:

```dart
_controller.text = 'New value';
```

**Clear text**:

```dart
_controller.clear();
```

**Listen for changes**:

```dart
@override
void initState() {
  super.initState();
  _controller.addListener(() {
    print('Current value: ${_controller.text}');
  });
}
```

**Set selection**:

```dart
_controller.selection = TextSelection(
  baseOffset: 0,
  extentOffset: _controller.text.length,
);
```

### Initial Value

```dart
final _controller = TextEditingController(text: 'Initial value');
```

## InputDecoration

InputDecoration configures the visual appearance of TextFormField.

### Common Properties

```dart
TextFormField(
  decoration: InputDecoration(
    // Labels
    labelText: 'Email',
    hintText: 'Enter your email',
    helperText: 'We will never share your email',

    // Icons
    prefixIcon: Icon(Icons.email),
    suffixIcon: Icon(Icons.check),

    // Borders
    border: OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red),
    ),

    // Styling
    filled: true,
    fillColor: Colors.grey[100],

    // Counter
    counterText: '0/100',

    // Error handling
    errorMaxLines: 2,
  ),
)
```

### Decoration Themes

Define app-wide input decoration:

```dart
MaterialApp(
  theme: ThemeData(
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
  ),
)
```

## Form Submission Patterns

### Basic Submission

```dart
void _submitForm() {
  if (_formKey.currentState!.validate()) {
    // Form is valid, process it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing...')),
    );
  }
}

ElevatedButton(
  onPressed: _submitForm,
  child: Text('Submit'),
)
```

### With Loading State

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Form fields...

          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### Using onSaved

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _email;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Name: $_name');
      print('Email: $_email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            onSaved: (value) => _name = value,
            validator: (value) =>
              value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            onSaved: (value) => _email = value,
            validator: (value) =>
              value?.isEmpty ?? true ? 'Required' : null,
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### Autosave Pattern

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  Timer? _debounce;

  void _autoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(seconds: 1), () {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        // Save to local storage or send to API
        print('Auto-saved');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _autoSave,
      child: // Form fields...
    );
  }
}
```

## Best Practices

1. **Always use GlobalKey**: Required for accessing FormState methods
2. **Dispose controllers**: Prevent memory leaks
3. **Use TextFormField with Form**: Better than TextField for forms
4. **Validate before save**: Always call validate() before save()
5. **Provide clear feedback**: Show validation errors and loading states
6. **Use autovalidateMode wisely**: Default (disabled) is usually best
7. **Create reusable validators**: Avoid duplicating validation logic
8. **Handle async operations**: Disable submit button during loading
9. **Consider UX**: Don't over-validate or annoy users
10. **Test edge cases**: Empty strings, null values, special characters
