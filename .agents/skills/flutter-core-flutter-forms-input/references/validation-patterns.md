# Validation Patterns Reference

Comprehensive guide to validation strategies in Flutter forms, including synchronous validation, asynchronous validation, and complex validation rules.

## Table of Contents

- [Validation Fundamentals](#validation-fundamentals)
- [Synchronous Validation](#synchronous-validation)
- [Asynchronous Validation](#asynchronous-validation)
- [Complex Validation Rules](#complex-validation-rules)
- [Conditional Validation](#conditional-validation)
- [Cross-Field Validation](#cross-field-validation)
- [Custom Validation Classes](#custom-validation-classes)
- [Validation Timing](#validation-timing)
- [Error Handling and Display](#error-handling-and-display)

## Validation Fundamentals

Validators in Flutter are functions with the signature `String? Function(String?)`. They:
- Receive the field's current value
- Return null if the value is valid
- Return an error message string if the value is invalid

### Basic Validator Structure

```dart
String? validateField(String? value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}

// Usage
TextFormField(
  validator: validateField,
)
```

### Inline Validators

```dart
TextFormField(
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Required field';
    }
    return null;
  },
)
```

## Synchronous Validation

Synchronous validation executes immediately and returns results without delay. Use for format checking, length validation, and pattern matching.

### Required Field Validation

```dart
String? validateRequired(String? value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}
```

### Length Validation

```dart
String? Function(String?) validateMinLength(int minLength) {
  return (value) {
    if (value == null || value.isEmpty) return null; // Optional field
    if (value.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  };
}

String? Function(String?) validateMaxLength(int maxLength) {
  return (value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxLength) {
      return 'Must be at most $maxLength characters';
    }
    return null;
  };
}

String? Function(String?) validateLengthRange(int min, int max) {
  return (value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min || value.length > max) {
      return 'Must be between $min and $max characters';
    }
    return null;
  };
}
```

### Pattern Validation

```dart
// Email validation
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );

  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }

  return null;
}

// Phone number validation
String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Phone number is required';
  }

  // Remove non-numeric characters
  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

  if (digitsOnly.length < 10) {
    return 'Phone number must be at least 10 digits';
  }

  return null;
}

// URL validation
String? validateUrl(String? value) {
  if (value == null || value.isEmpty) return null; // Optional

  final urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
  );

  if (!urlRegex.hasMatch(value)) {
    return 'Please enter a valid URL';
  }

  return null;
}

// Alphanumeric validation
String? validateAlphanumeric(String? value) {
  if (value == null || value.isEmpty) return null;

  final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

  if (!alphanumericRegex.hasMatch(value)) {
    return 'Only letters and numbers are allowed';
  }

  return null;
}
```

### Numeric Validation

```dart
// Integer validation
String? validateInteger(String? value) {
  if (value == null || value.isEmpty) return null;

  final number = int.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }

  return null;
}

// Decimal validation
String? validateDecimal(String? value) {
  if (value == null || value.isEmpty) return null;

  final number = double.tryParse(value);
  if (number == null) {
    return 'Please enter a valid decimal number';
  }

  return null;
}

// Range validation
String? Function(String?) validateNumberRange(num min, num max) {
  return (value) {
    if (value == null || value.isEmpty) return null;

    final number = num.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return 'Must be between $min and $max';
    }

    return null;
  };
}

// Positive number validation
String? validatePositive(String? value) {
  if (value == null || value.isEmpty) return null;

  final number = num.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }

  if (number <= 0) {
    return 'Must be a positive number';
  }

  return null;
}
```

### Date Validation

```dart
String? validateDate(String? value) {
  if (value == null || value.isEmpty) return null;

  try {
    DateTime.parse(value);
    return null;
  } catch (e) {
    return 'Please enter a valid date';
  }
}

String? Function(String?) validateDateAfter(DateTime minDate) {
  return (value) {
    if (value == null || value.isEmpty) return null;

    try {
      final date = DateTime.parse(value);
      if (date.isBefore(minDate)) {
        return 'Date must be after ${minDate.toString().split(' ')[0]}';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  };
}

String? Function(String?) validateDateBefore(DateTime maxDate) {
  return (value) {
    if (value == null || value.isEmpty) return null;

    try {
      final date = DateTime.parse(value);
      if (date.isAfter(maxDate)) {
        return 'Date must be before ${maxDate.toString().split(' ')[0]}';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  };
}

String? validateAge(String? value, {required int minAge}) {
  if (value == null || value.isEmpty) return null;

  try {
    final birthDate = DateTime.parse(value);
    final today = DateTime.now();
    final age = today.year - birthDate.year;

    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }

    return null;
  } catch (e) {
    return 'Please enter a valid date';
  }
}
```

## Asynchronous Validation

Asynchronous validation is needed when validation requires external checks like API calls or database queries.

### Basic Async Validation Pattern

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _usernameError;
  bool _isCheckingUsername = false;

  Future<void> _checkUsername() async {
    final username = _usernameController.text;

    if (username.isEmpty) return;

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Simulate checking if username exists
      final exists = username == 'admin' || username == 'test';

      setState(() {
        _usernameError = exists ? 'Username already taken' : null;
      });
    } finally {
      setState(() => _isCheckingUsername = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _usernameError,
              suffixIcon: _isCheckingUsername
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            ),
            onChanged: (value) {
              // Debounce the check
              Future.delayed(Duration(milliseconds: 500), () {
                if (_usernameController.text == value) {
                  _checkUsername();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
```

### Debounced Async Validation

```dart
import 'dart:async';

class DebouncedValidator {
  Timer? _debounce;
  final Duration delay;

  DebouncedValidator({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback callback) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(delay, callback);
  }

  void dispose() {
    _debounce?.cancel();
  }
}

class _MyFormState extends State<MyForm> {
  final _usernameController = TextEditingController();
  final _debouncer = DebouncedValidator();
  String? _usernameError;
  bool _isChecking = false;

  Future<void> _validateUsername() async {
    setState(() => _isChecking = true);

    try {
      final isAvailable = await _checkUsernameAvailability(
        _usernameController.text,
      );

      setState(() {
        _usernameError = isAvailable ? null : 'Username already taken';
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    await Future.delayed(Duration(seconds: 1));
    return username != 'admin' && username != 'test';
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Username',
        errorText: _usernameError,
        suffixIcon: _isChecking
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      ),
      onChanged: (value) {
        _debouncer(() => _validateUsername());
      },
    );
  }
}
```

### Form Submission with Async Validation

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  Future<bool> _validateEmailWithServer(String email) async {
    // Simulate API call to check if email is already registered
    await Future.delayed(Duration(seconds: 1));
    return email != 'taken@example.com';
  }

  Future<void> _submitForm() async {
    // First, run synchronous validation
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Then run async validation
      final emailAvailable = await _validateEmailWithServer(
        _emailController.text,
      );

      if (!emailAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email already registered')),
        );
        return;
      }

      // All validation passed, submit form
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!value!.contains('@')) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
              ? CircularProgressIndicator()
              : Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

## Complex Validation Rules

### Password Strength Validation

```dart
class PasswordStrength {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final errors = <String>[];

    if (value.length < 8) {
      errors.add('at least 8 characters');
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('one uppercase letter');
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('one lowercase letter');
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('one number');
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('one special character');
    }

    if (errors.isEmpty) return null;

    return 'Password must contain ${errors.join(', ')}';
  }

  static double strength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score / 6;
  }
}

// Usage with strength indicator
class PasswordField extends StatefulWidget {
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final _controller = TextEditingController();
  double _strength = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
          validator: PasswordStrength.validate,
          onChanged: (value) {
            setState(() {
              _strength = PasswordStrength.strength(value);
            });
          },
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: _strength,
          backgroundColor: Colors.grey[300],
          color: _strength < 0.5
            ? Colors.red
            : _strength < 0.75
              ? Colors.orange
              : Colors.green,
        ),
        SizedBox(height: 4),
        Text(
          _strength < 0.5
            ? 'Weak'
            : _strength < 0.75
              ? 'Medium'
              : 'Strong',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
```

### Credit Card Validation

```dart
class CreditCardValidator {
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\s'), '');

    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Invalid card number length';
    }

    if (!_luhnCheck(digitsOnly)) {
      return 'Invalid card number';
    }

    return null;
  }

  static String? validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Invalid format (use MM/YY)';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) {
      return 'Invalid expiry date';
    }

    if (month < 1 || month > 12) {
      return 'Invalid month';
    }

    final now = DateTime.now();
    final expiry = DateTime(2000 + year, month);

    if (expiry.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'CVV must contain only numbers';
    }

    return null;
  }

  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}
```

## Conditional Validation

Validation rules that depend on other field values or application state.

### Field-Dependent Validation

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  bool _requiresPhone = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CheckboxListTile(
            title: Text('Contact me by phone'),
            value: _requiresPhone,
            onChanged: (value) {
              setState(() {
                _requiresPhone = value ?? false;
                // Revalidate form when checkbox changes
                _formKey.currentState?.validate();
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Phone Number'),
            validator: (value) {
              if (_requiresPhone && (value?.isEmpty ?? true)) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
```

### State-Dependent Validation

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  String _accountType = 'personal';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _accountType,
            items: [
              DropdownMenuItem(value: 'personal', child: Text('Personal')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
            ],
            onChanged: (value) {
              setState(() {
                _accountType = value!;
                _formKey.currentState?.validate();
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Company Name'),
            validator: (value) {
              if (_accountType == 'business' && (value?.isEmpty ?? true)) {
                return 'Company name is required for business accounts';
              }
              return null;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Tax ID'),
            validator: (value) {
              if (_accountType == 'business' && (value?.isEmpty ?? true)) {
                return 'Tax ID is required for business accounts';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
```

## Cross-Field Validation

Validating one field based on another field's value.

### Password Confirmation

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password is required';
              }
              return null;
            },
          ),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirm Password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
```

### Date Range Validation

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Start Date'),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _startDate = date;
                  _formKey.currentState?.validate();
                });
              }
            },
            validator: (value) {
              if (_startDate == null) {
                return 'Start date is required';
              }
              return null;
            },
            controller: TextEditingController(
              text: _startDate?.toString().split(' ')[0] ?? '',
            ),
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'End Date'),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: _startDate ?? DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            validator: (value) {
              if (_endDate == null) {
                return 'End date is required';
              }
              if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                return 'End date must be after start date';
              }
              return null;
            },
            controller: TextEditingController(
              text: _endDate?.toString().split(' ')[0] ?? '',
            ),
          ),
        ],
      ),
    );
  }
}
```

## Custom Validation Classes

Organizing complex validation logic into reusable classes.

### Validator Composition

```dart
class ValidatorComposer {
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

// Usage
TextFormField(
  validator: ValidatorComposer.compose([
    Validators.required,
    Validators.minLength(6),
    Validators.email,
  ]),
)
```

### Validation Result Class

```dart
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});

  factory ValidationResult.valid() {
    return ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid(String error) {
    return ValidationResult(isValid: false, error: error);
  }
}

class AdvancedValidator {
  static ValidationResult validateUsername(String value) {
    if (value.isEmpty) {
      return ValidationResult.invalid('Username is required');
    }

    if (value.length < 3) {
      return ValidationResult.invalid('Username must be at least 3 characters');
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return ValidationResult.invalid(
        'Username can only contain letters, numbers, and underscores'
      );
    }

    return ValidationResult.valid();
  }

  // Convert to Flutter validator format
  static String? Function(String?) toValidator(
    ValidationResult Function(String) validate,
  ) {
    return (value) {
      final result = validate(value ?? '');
      return result.isValid ? null : result.error;
    };
  }
}

// Usage
TextFormField(
  validator: AdvancedValidator.toValidator(
    AdvancedValidator.validateUsername,
  ),
)
```

## Validation Timing

### AutovalidateMode Options

```dart
Form(
  autovalidateMode: AutovalidateMode.disabled, // Default
  // Validate only when validate() is called
)

Form(
  autovalidateMode: AutovalidateMode.always,
  // Validate on every change (can be annoying)
)

Form(
  autovalidateMode: AutovalidateMode.onUserInteraction,
  // Validate after first interaction with field
)
```

### Dynamic AutovalidateMode

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid
    } else {
      // Enable autovalidation after first failed attempt
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: // Form fields...
    );
  }
}
```

## Error Handling and Display

### Custom Error Display

```dart
class CustomTextFormField extends StatelessWidget {
  final String label;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  const CustomTextFormField({
    required this.label,
    this.validator,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorMaxLines: 3, // Allow multi-line errors
        errorStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }
}
```

### Validation Summary

```dart
class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  List<String> _errors = [];

  void _validateForm() {
    _errors.clear();

    // Collect all validation errors
    if (!_formKey.currentState!.validate()) {
      setState(() {
        // Form.validate() already displays errors inline
        _errors.add('Please fix the errors above');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_errors.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.red[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _errors
                  .map((error) => Text('• $error'))
                  .toList(),
              ),
            ),
          // Form fields...
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Keep validators pure**: No side effects, only return validation results
2. **Provide clear error messages**: Tell users exactly what's wrong and how to fix it
3. **Validate on submit first**: Don't annoy users with premature validation
4. **Debounce async validation**: Avoid excessive API calls
5. **Use appropriate timing**: Choose AutovalidateMode based on UX needs
6. **Compose validators**: Create reusable validator functions
7. **Handle edge cases**: Test with empty strings, nulls, special characters
8. **Show loading states**: For async validation, show progress indicators
9. **Consider UX**: Balance between helpful validation and user annoyance
10. **Test thoroughly**: Validate all edge cases and error conditions
