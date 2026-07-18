# Complex Multi-Step Form Example

A complete implementation of a multi-step registration form with validation, progress tracking, and state management.

## Overview

This example demonstrates:
- Multi-step form navigation
- Per-step validation
- Progress indicator
- Form state persistence
- Final submission with all data
- Back/forward navigation
- Responsive layout

## Complete Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Step Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const MultiStepForm(),
    );
  }
}

// Main multi-step form widget
class MultiStepForm extends StatefulWidget {
  const MultiStepForm({super.key});

  @override
  State<MultiStepForm> createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  int _currentStep = 0;
  final _formData = FormData();

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      _formKeys[_currentStep].currentState!.save();

      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_formData.firstName} ${_formData.lastName}'),
            Text('Email: ${_formData.email}'),
            Text('Phone: ${_formData.phone}'),
            Text('Address: ${_formData.address}'),
            Text('City: ${_formData.city}'),
            Text('Account Type: ${_formData.accountType}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStep = 0;
                _formData.clear();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[200],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _getStepTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentStep(),
            ),
          ),
          const Divider(height: 1),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Contact Details';
      case 2:
        return 'Account Settings';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return PersonalInfoStep(
          formKey: _formKeys[0],
          formData: _formData,
        );
      case 1:
        return ContactDetailsStep(
          formKey: _formKeys[1],
          formData: _formData,
        );
      case 2:
        return AccountSettingsStep(
          formKey: _formKeys[2],
          formData: _formData,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.check),
            label: Text(_currentStep < 2 ? 'Next' : 'Submit'),
          ),
        ],
      ),
    );
  }
}

// Step 1: Personal Information
class PersonalInfoStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FormData formData;

  const PersonalInfoStep({
    super.key,
    required this.formKey,
    required this.formData,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dateOfBirthController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.formData.firstName);
    _lastNameController = TextEditingController(text: widget.formData.lastName);
    _dateOfBirthController = TextEditingController(text: widget.formData.dateOfBirth);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'First name is required';
              }
              return null;
            },
            onSaved: (value) => widget.formData.firstName = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Last name is required';
              }
              return null;
            },
            onSaved: (value) => widget.formData.lastName = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateOfBirthController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.calendar_today),
              hintText: 'YYYY-MM-DD',
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _dateOfBirthController.text = date.toString().split(' ')[0];
              }
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Date of birth is required';
              }
              final date = DateTime.tryParse(value!);
              if (date == null) {
                return 'Invalid date';
              }
              final age = DateTime.now().difference(date).inDays ~/ 365;
              if (age < 18) {
                return 'You must be at least 18 years old';
              }
              return null;
            },
            onSaved: (value) => widget.formData.dateOfBirth = value,
          ),
        ],
      ),
    );
  }
}

// Step 2: Contact Details
class ContactDetailsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FormData formData;

  const ContactDetailsStep({
    super.key,
    required this.formKey,
    required this.formData,
  });

  @override
  State<ContactDetailsStep> createState() => _ContactDetailsStepState();
}

class _ContactDetailsStepState extends State<ContactDetailsStep> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.formData.email);
    _phoneController = TextEditingController(text: widget.formData.phone);
    _addressController = TextEditingController(text: widget.formData.address);
    _cityController = TextEditingController(text: widget.formData.city);
    _zipController = TextEditingController(text: widget.formData.zipCode);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value!)) {
                return 'Invalid email address';
              }
              return null;
            },
            onSaved: (value) => widget.formData.email = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Phone number is required';
              }
              if (value!.length < 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
            onSaved: (value) => widget.formData.phone = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              prefixIcon: Icon(Icons.home),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Address is required';
              }
              return null;
            },
            onSaved: (value) => widget.formData.address = value,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'City is required';
                    }
                    return null;
                  },
                  onSaved: (value) => widget.formData.city = value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'ZIP required';
                    }
                    if (value!.length != 5) {
                      return 'Invalid ZIP';
                    }
                    return null;
                  },
                  onSaved: (value) => widget.formData.zipCode = value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 3: Account Settings
class AccountSettingsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FormData formData;

  const AccountSettingsStep({
    super.key,
    required this.formKey,
    required this.formData,
  });

  @override
  State<AccountSettingsStep> createState() => _AccountSettingsStepState();
}

class _AccountSettingsStepState extends State<AccountSettingsStep> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.formData.username);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: widget.formData.accountType.isEmpty
                ? null
                : widget.formData.accountType,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              prefixIcon: Icon(Icons.account_box),
            ),
            items: const [
              DropdownMenuItem(value: 'personal', child: Text('Personal')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
              DropdownMenuItem(value: 'premium', child: Text('Premium')),
            ],
            validator: (value) {
              if (value == null) {
                return 'Please select an account type';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                widget.formData.accountType = value ?? '';
              });
            },
            onSaved: (value) => widget.formData.accountType = value ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Username is required';
              }
              if (value!.length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Username can only contain letters, numbers, and underscores';
              }
              return null;
            },
            onSaved: (value) => widget.formData.username = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password is required';
              }
              if (value!.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!value.contains(RegExp(r'[A-Z]'))) {
                return 'Password must contain an uppercase letter';
              }
              if (!value.contains(RegExp(r'[0-9]'))) {
                return 'Password must contain a number';
              }
              return null;
            },
            onSaved: (value) => widget.formData.password = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: widget.formData.agreeToTerms,
            onChanged: (value) {
              setState(() {
                widget.formData.agreeToTerms = value ?? false;
              });
            },
            title: const Text('I agree to the Terms and Conditions'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!widget.formData.agreeToTerms)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'You must agree to the terms and conditions',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Data model to hold form data
class FormData {
  String? firstName;
  String? lastName;
  String? dateOfBirth;
  String? email;
  String? phone;
  String? address;
  String? city;
  String? zipCode;
  String accountType = '';
  String? username;
  String? password;
  bool agreeToTerms = false;

  void clear() {
    firstName = null;
    lastName = null;
    dateOfBirth = null;
    email = null;
    phone = null;
    address = null;
    city = null;
    zipCode = null;
    accountType = '';
    username = null;
    password = null;
    agreeToTerms = false;
  }
}
```

## Key Features Demonstrated

### 1. Multi-Step Navigation
- Progress indicator shows completion percentage
- Step counter displays current step
- Back/Next buttons for navigation
- Final step shows "Submit" instead of "Next"

### 2. Per-Step Validation
- Each step has its own FormKey
- Validation occurs before advancing
- Form state is saved when validation passes
- Invalid steps cannot be skipped

### 3. State Persistence
- FormData object holds all field values
- Controllers initialized with saved values
- Users can navigate back without losing data
- Data persists across rebuilds

### 4. Advanced Validation
- Age validation (must be 18+)
- Email format validation
- Password strength requirements
- Password confirmation matching
- Terms and conditions checkbox

### 5. User Experience
- Visual feedback with icons
- Password visibility toggle
- Date picker for date of birth
- Input formatters for phone and ZIP
- Loading dialog during submission
- Success dialog with summary

## Customization Options

### Add More Steps
```dart
// Add to _formKeys list
final List<GlobalKey<FormState>> _formKeys = [
  GlobalKey<FormState>(),
  GlobalKey<FormState>(),
  GlobalKey<FormState>(),
  GlobalKey<FormState>(), // New step
];

// Add case in _buildCurrentStep
case 3:
  return AdditionalInfoStep(
    formKey: _formKeys[3],
    formData: _formData,
  );
```

### Persistent Storage
```dart
import 'package:shared_preferences/shared_preferences.dart';

// Save to storage
Future<void> _saveToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('firstName', _formData.firstName ?? '');
  // Save other fields...
}

// Load from storage
Future<void> _loadFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  _formData.firstName = prefs.getString('firstName');
  // Load other fields...
}
```

### Skip Optional Steps
```dart
bool _isStepRequired(int step) {
  // Step 2 is optional if business account
  if (step == 2 && _formData.accountType != 'business') {
    return false;
  }
  return true;
}
```

This example provides a solid foundation for building complex, production-ready multi-step forms in Flutter.
