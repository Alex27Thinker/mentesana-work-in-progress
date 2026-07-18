# Authentication and Authorization

Complete guide to implementing authentication in Serverpod applications using the serverpod_auth_idp module, including email/password, Google Sign-In, Apple Sign-In, JWT tokens, and session management.

## Overview

Serverpod provides production-ready authentication through the `serverpod_auth_idp` module, supporting multiple identity providers and token management strategies.

### Authentication Module Features

**Identity Providers**:
- Email/password authentication with sign-up flows
- Google OAuth integration
- Apple Sign-In support
- Custom identity provider extensibility

**Token Management**:
- JWT (JSON Web Tokens) for stateless authentication
- Server-side sessions for traditional authentication
- Automatic token refresh and rotation

**Security Features**:
- Two-factor authentication support
- Password hashing with configurable peppers
- Secure credential storage
- Built-in UI components or custom integration

## Installation

### Server Dependencies

Add the authentication module to your server's `pubspec.yaml`:

```yaml
dependencies:
  serverpod: ^3.x.x
  serverpod_auth_idp_server: ^3.x.x
```

Install dependencies:

```bash
cd my_app_server
dart pub get
```

### Client Dependencies

Add client package to your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  my_app_client:
    path: ../my_app_client
  serverpod_auth_idp_client: ^3.x.x
```

Install:

```bash
cd my_app_flutter
flutter pub get
```

## Server Configuration

### Initialize Authentication Services

Configure authentication in your `lib/server.dart` file:

```dart
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart';

void run(List<String> args) async {
  var pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  // Initialize authentication
  pod.initializeAuthServices(
    // Token manager configuration
    tokenManager: JwtConfigFromPasswords(
      passwords: pod.passwords,
    ),
    // Identity provider configuration
    identityProviderBuilders: [
      // Email authentication
      (session) => EmailIdpConfigFromPasswords(
        passwords: session.serverpod.passwords,
      ),
      // Google Sign-In
      (session) => GoogleIdpConfigFromPasswords(
        passwords: session.serverpod.passwords,
      ),
      // Apple Sign-In
      (session) => AppleIdpConfigFromPasswords(
        passwords: session.serverpod.passwords,
      ),
    ],
  );

  await pod.start();
}
```

### Secret Management

Store authentication secrets in `config/passwords.yaml`:

```yaml
development:
  # Database password
  database: 'dev_db_password'

  # JWT configuration
  jwtRefreshTokenHashPepper: 'your_secure_pepper_min_32_bytes_recommended'
  jwtHmacSha512PrivateKey: 'your_hmac_secret_key'

  # Email provider configuration
  emailIdpSignUpEmailSenderAddress: 'noreply@yourdomain.com'

  # Google OAuth credentials
  googleIdpClientId: 'your-google-client-id.apps.googleusercontent.com'
  googleIdpClientSecret: 'your-google-client-secret'

  # Apple Sign-In credentials (optional)
  appleIdpServiceId: 'your.apple.service.id'
  appleIdpTeamId: 'YOUR_TEAM_ID'
  appleIdpKeyId: 'YOUR_KEY_ID'
  appleIdpPrivateKey: |
    -----BEGIN PRIVATE KEY-----
    Your private key here
    -----END PRIVATE KEY-----

staging:
  # Staging credentials...

production:
  # Production credentials...
```

**Security**:
- Never commit `passwords.yaml` to version control
- Use strong, randomly generated secrets (minimum 32 bytes for peppers)
- Rotate secrets periodically in production

### Environment Variables

Override secrets using environment variables:

```bash
# Format: SERVERPOD_PASSWORD_<key>='value'
export SERVERPOD_PASSWORD_JWT_REFRESH_TOKEN_HASH_PEPPER='your_pepper'
export SERVERPOD_PASSWORD_JWT_HMAC_SHA512_PRIVATE_KEY='your_key'
export SERVERPOD_PASSWORD_GOOGLE_IDP_CLIENT_ID='your_client_id'
export SERVERPOD_PASSWORD_GOOGLE_IDP_CLIENT_SECRET='your_secret'
```

Environment variables take precedence over `passwords.yaml`.

## JWT Authentication

JWT provides stateless authentication suitable for serverless deployments and distributed systems.

### JWT Configuration

Configure JWT token manager with HMAC or ECDSA algorithms:

```dart
// HMAC SHA-512 (symmetric key)
tokenManager: JwtConfig(
  refreshTokenHashPepper: 'your_secure_pepper',
  algorithm: JwtAlgorithm.hmacSha512(
    SecretKey('your_secret_key'),
  ),
  // Optional: custom token lifetimes
  accessTokenLifetime: Duration(minutes: 15),
  refreshTokenLifetime: Duration(days: 30),
),

// ECDSA SHA-512 (asymmetric keys)
tokenManager: JwtConfig(
  refreshTokenHashPepper: 'your_secure_pepper',
  algorithm: JwtAlgorithm.ecdsaSha512(
    privateKey: privateECKey,
    publicKey: publicECKey,
  ),
),
```

### Algorithm Selection

**HMAC SHA-512** (Recommended for most cases):
- Uses symmetric secret key
- Faster to compute
- Simpler key management
- Suitable when server validates all tokens

**ECDSA SHA-512**:
- Uses asymmetric key pair
- Public key can be shared for validation
- Better for microservices needing independent validation
- Slightly slower computation

### Token Lifetimes

Configure token expiration:

```dart
tokenManager: JwtConfig(
  refreshTokenHashPepper: 'pepper',
  algorithm: algorithm,
  // Access tokens expire quickly (default: 15 minutes)
  accessTokenLifetime: Duration(minutes: 10),
  // Refresh tokens last longer (default: 30 days)
  refreshTokenLifetime: Duration(days: 90),
),
```

**Best Practices**:
- Short access token lifetime (5-15 minutes) limits exposure
- Longer refresh token lifetime reduces login frequency
- Balance security with user experience

### Custom Claims

Add custom data to JWT tokens:

```dart
tokenManager: JwtConfig(
  refreshTokenHashPepper: 'pepper',
  algorithm: algorithm,
  // Add custom claims to access tokens
  extraClaimsProvider: (session, auth) async {
    var user = await User.db.findById(session, auth.userId);
    return {
      'role': user.role,
      'organizationId': user.organizationId,
      'permissions': user.permissions,
    };
  },
),
```

Access claims in endpoints:

```dart
Future<void> adminOnly(Session session) async {
  var claims = session.auth?.claims;
  var role = claims?['role'];

  if (role != 'admin') {
    throw ForbiddenException('Admin access required');
  }

  // Admin operation
}
```

### Extending Token Refresh Endpoint

Expose token refresh to clients:

```dart
// lib/src/endpoints/auth_endpoint.dart
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart' as core;

class AuthEndpoint extends core.RefreshJwtTokensEndpoint {
  // Inherits refreshJwtTokens method
}
```

Generate client code:

```bash
serverpod generate
```

Client usage:

```dart
// Client automatically refreshes tokens when needed
// Manual refresh if needed:
await client.auth.refreshJwtTokens();
```

## Server-Side Sessions

Traditional session-based authentication with server-side state storage.

### Session Configuration

Use server-side sessions instead of JWT:

```dart
tokenManager: ServerSideSessionsConfigFromPasswords(
  passwords: pod.passwords,
  // Optional: custom session lifetime
  sessionLifetime: Duration(hours: 24),
),
```

**Advantages**:
- Immediate token revocation
- Simpler key management
- No token expiration complexity

**Disadvantages**:
- Requires database query per request
- Not suitable for serverless
- Harder to scale horizontally

### Session Storage

Sessions stored in the database automatically. Clean up expired sessions periodically:

```dart
// In a scheduled task or maintenance endpoint
Future<void> cleanupExpiredSessions(Session session) async {
  var cutoff = DateTime.now().subtract(Duration(days: 30));

  await AuthSession.db.deleteWhere(
    session,
    where: (t) => t.expiresAt < cutoff,
  );
}
```

## Email Authentication

Email/password authentication with sign-up and sign-in flows.

### Email Provider Setup

Configure email identity provider:

```dart
identityProviderBuilders: [
  (session) => EmailIdpConfigFromPasswords(
    passwords: session.serverpod.passwords,
    // Optional: custom email sender
    sendSignUpEmail: (session, email, code) async {
      // Custom email sending logic
      await yourEmailService.send(
        to: email,
        subject: 'Verify your email',
        body: 'Verification code: $code',
      );
    },
  ),
],
```

### Extending Email Endpoints

Create server endpoints for email authentication:

```dart
// lib/src/endpoints/email_auth_endpoint.dart
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/email.dart' as email;

class EmailAuthEndpoint extends email.EmailAuthEndpoint {
  // Inherits:
  // - signUp(email, password)
  // - verifySignUp(email, code)
  // - signIn(email, password)
  // - resetPassword(email)
  // - verifyPasswordReset(email, code, newPassword)
}
```

Generate and use:

```bash
serverpod generate
```

### Email Sign-Up Flow

**Client Implementation**:

```dart
// Step 1: Initiate sign-up
try {
  await client.emailAuth.signUp(
    email: 'user@example.com',
    password: 'SecurePassword123!',
  );

  // Email sent with verification code
  print('Check your email for verification code');
} on EmailAlreadyExistsException {
  print('Email already registered');
} on WeakPasswordException {
  print('Password too weak');
}

// Step 2: Verify email with code
try {
  await client.emailAuth.verifySignUp(
    email: 'user@example.com',
    code: '123456',
  );

  print('Sign-up complete! Please sign in.');
} on InvalidVerificationCodeException {
  print('Invalid or expired code');
}

// Step 3: Sign in
var authResponse = await client.emailAuth.signIn(
  email: 'user@example.com',
  password: 'SecurePassword123!',
);

// Store tokens
await sessionManager.updateFromAuthResponse(authResponse);
```

### Password Reset Flow

```dart
// Request password reset
await client.emailAuth.resetPassword(
  email: 'user@example.com',
);

// Email sent with reset code

// Verify and set new password
await client.emailAuth.verifyPasswordReset(
  email: 'user@example.com',
  code: '123456',
  newPassword: 'NewSecurePassword456!',
);
```

## Google Sign-In

OAuth integration with Google for social authentication.

### Google Cloud Setup

1. Create project in Google Cloud Console
2. Enable Google Sign-In API
3. Create OAuth 2.0 credentials:
   - **Web client ID** for server
   - **iOS client ID** for iOS app
   - **Android client ID** for Android app
4. Configure authorized redirect URIs

### Server Configuration

```dart
identityProviderBuilders: [
  (session) => GoogleIdpConfigFromPasswords(
    passwords: session.serverpod.passwords,
    // Optionally customize scopes
    scopes: ['email', 'profile', 'openid'],
  ),
],
```

Add to `passwords.yaml`:

```yaml
development:
  googleIdpClientId: 'your-client-id.apps.googleusercontent.com'
  googleIdpClientSecret: 'your-client-secret'
```

### Extending Google Endpoint

```dart
// lib/src/endpoints/google_auth_endpoint.dart
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/google.dart' as google;

class GoogleAuthEndpoint extends google.GoogleAuthEndpoint {
  // Inherits:
  // - signInWithGoogle(idToken, serverAuthCode)
}
```

### Flutter Integration

Add Google Sign-In package:

```yaml
dependencies:
  google_sign_in: ^6.1.0
```

Implement sign-in:

```dart
import 'package:google_sign_in/google_sign_in.dart';

Future<void> signInWithGoogle() async {
  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use your web client ID
    serverClientId: 'your-web-client-id.apps.googleusercontent.com',
  );

  try {
    final account = await googleSignIn.signIn();
    if (account == null) {
      print('Sign in cancelled');
      return;
    }

    final googleAuth = await account.authentication;

    // Send to server
    final authResponse = await client.googleAuth.signInWithGoogle(
      idToken: googleAuth.idToken!,
      serverAuthCode: googleAuth.serverAuthCode,
    );

    // Store tokens
    await sessionManager.updateFromAuthResponse(authResponse);

    print('Signed in as: ${account.email}');
  } catch (e) {
    print('Google sign-in failed: $e');
  }
}
```

## Apple Sign-In

Apple authentication for iOS, macOS, and web applications.

### Apple Developer Setup

1. Register App ID with Sign in with Apple capability
2. Create Services ID for web/Android
3. Generate private key for Sign in with Apple
4. Configure return URLs

### Server Configuration

```dart
identityProviderBuilders: [
  (session) => AppleIdpConfigFromPasswords(
    passwords: session.serverpod.passwords,
  ),
],
```

Add credentials to `passwords.yaml`:

```yaml
development:
  appleIdpServiceId: 'com.yourcompany.yourapp'
  appleIdpTeamId: 'TEAM_ID'
  appleIdpKeyId: 'KEY_ID'
  appleIdpPrivateKey: |
    -----BEGIN PRIVATE KEY-----
    Your P8 private key content
    -----END PRIVATE KEY-----
```

### Extending Apple Endpoint

```dart
// lib/src/endpoints/apple_auth_endpoint.dart
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/apple.dart' as apple;

class AppleAuthEndpoint extends apple.AppleAuthEndpoint {
  // Inherits:
  // - signInWithApple(idToken, authorizationCode)
}
```

### Flutter Integration

Add Sign in with Apple package:

```yaml
dependencies:
  sign_in_with_apple: ^5.0.0
```

Implement:

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<void> signInWithApple() async {
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // Send to server
    final authResponse = await client.appleAuth.signInWithApple(
      idToken: credential.identityToken!,
      authorizationCode: credential.authorizationCode,
    );

    // Store tokens
    await sessionManager.updateFromAuthResponse(authResponse);

    print('Signed in with Apple');
  } catch (e) {
    print('Apple sign-in failed: $e');
  }
}
```

## Flutter Client Setup

### Session Manager

Initialize authentication session manager in your Flutter app:

```dart
// lib/main.dart
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create client
  final client = Client('http://localhost:8080/');

  // Create session manager
  final sessionManager = FlutterAuthSessionManager(
    caller: client.caller,
  );
  client.authSessionManager = sessionManager;

  // Restore existing session
  await sessionManager.initialize();

  runApp(MyApp(client: client, sessionManager: sessionManager));
}
```

### Monitoring Authentication State

Listen to authentication changes:

```dart
class AuthProvider extends ChangeNotifier {
  final FlutterAuthSessionManager _sessionManager;

  AuthProvider(this._sessionManager) {
    _sessionManager.addListener(_onAuthChanged);
  }

  bool get isSignedIn => _sessionManager.signedInUser != null;
  AuthenticationInfo? get user => _sessionManager.signedInUser;

  void _onAuthChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionManager.removeListener(_onAuthChanged);
    super.dispose();
  }
}
```

### Sign-In UI Widget

Use the built-in sign-in widget:

```dart
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';

class SignInScreen extends StatelessWidget {
  final Client client;
  final FlutterAuthSessionManager sessionManager;

  const SignInScreen({
    required this.client,
    required this.sessionManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignInWidget(
        client: client,
        sessionManager: sessionManager,
        // Customize which providers to show
        enabledProviders: {
          SignInProvider.email,
          SignInProvider.google,
          SignInProvider.apple,
        },
        // Optional: custom branding
        logo: Image.asset('assets/logo.png'),
        // Optional: callbacks
        onSignedIn: () {
          Navigator.of(context).pushReplacementNamed('/home');
        },
      ),
    );
  }
}
```

### Custom Sign-In UI

Build custom UI instead of using the widget:

```dart
class CustomSignInScreen extends StatefulWidget {
  @override
  _CustomSignInScreenState createState() => _CustomSignInScreenState();
}

class _CustomSignInScreenState extends State<CustomSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      final authResponse = await widget.client.emailAuth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await widget.sessionManager.updateFromAuthResponse(authResponse);

      Navigator.of(context).pushReplacementNamed('/home');
    } on InvalidCredentialsException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email or password')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signIn,
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Server-Side Authorization

Check authentication and permissions in endpoints.

### Requiring Authentication

```dart
Future<UserProfile> getMyProfile(Session session) async {
  // Check if user is signed in
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  var userId = session.auth!.userId!;
  return await UserProfile.db.findById(session, userId);
}
```

### Role-Based Access Control

Store roles in your user model:

```yaml
class: User
table: user
fields:
  email: String
  name: String
  role: String  # 'user', 'admin', 'moderator'
```

Check roles in endpoints:

```dart
Future<void> adminOnly(Session session) async {
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  var userId = session.auth!.userId!;
  var user = await User.db.findById(session, userId);

  if (user.role != 'admin') {
    throw ForbiddenException('Admin access required');
  }

  // Admin operation
}
```

### Permission-Based Access

More granular permissions:

```yaml
class: User
table: user
fields:
  email: String
  permissions: List<String>  # ['read:posts', 'write:posts', 'delete:posts']
```

Check permissions:

```dart
Future<bool> hasPermission(Session session, String permission) async {
  if (!session.isUserSignedIn) return false;

  var userId = session.auth!.userId!;
  var user = await User.db.findById(session, userId);

  return user.permissions?.contains(permission) ?? false;
}

Future<void> deletePost(Session session, int postId) async {
  if (!await hasPermission(session, 'delete:posts')) {
    throw ForbiddenException('Permission denied');
  }

  // Delete post
}
```

## Sign-Out

Sign out users and revoke tokens.

### Client-Side Sign-Out

```dart
Future<void> signOut() async {
  // Clear session on server (for server-side sessions)
  try {
    await client.auth.signOut();
  } catch (e) {
    print('Server sign-out failed: $e');
  }

  // Clear local session
  await sessionManager.signOut();

  // Navigate to sign-in screen
  Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
}
```

### Server-Side Sign-Out Endpoint

```dart
Future<void> signOut(Session session) async {
  if (session.auth != null) {
    // Revoke tokens/sessions in database
    await AuthToken.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(session.auth!.userId!),
    );
  }
}
```

Serverpod's authentication system provides enterprise-grade security with minimal configuration, enabling rapid development of secure applications.
