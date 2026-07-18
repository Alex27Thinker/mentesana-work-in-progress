# Serverpod Installation and Project Setup

Complete guide to installing Serverpod, creating your first project, understanding the project structure, and configuring your development environment for full-stack Dart/Flutter development.

## Prerequisites

Before installing Serverpod, ensure your development environment meets these requirements:

### Flutter SDK

Serverpod requires a working Flutter installation. Verify your Flutter setup:

```bash
flutter --version
flutter doctor
```

Ensure Flutter is properly configured for your target platforms (iOS, Android, Web, or Desktop). Serverpod works with any Flutter-supported platform.

### PostgreSQL Database

Serverpod uses PostgreSQL as its database engine. For local development, Docker is the recommended approach as Serverpod projects include pre-configured Docker Compose files.

**Install Docker Desktop** (includes Docker Compose):
- **macOS**: Download from docker.com and install the DMG
- **Windows**: Install Docker Desktop for Windows with WSL 2 backend
- **Linux**: Install Docker Engine and Docker Compose from your distribution's repository

Verify installation:

```bash
docker --version
docker compose version
```

Alternatively, install PostgreSQL directly:
- **macOS**: `brew install postgresql@14`
- **Windows**: Download installer from postgresql.org
- **Linux**: `apt install postgresql-14` or equivalent

### Development Tools

**Required**:
- Git for version control
- Any code editor (VS Code, IntelliJ, Android Studio)

**Recommended**:
- **Serverpod VS Code Extension**: Provides syntax highlighting for `.spy.yaml` files, snippets, and validation
- **Serverpod Insights**: Native macOS/Windows desktop application for monitoring, debugging, and database inspection

## Installing Serverpod CLI

The Serverpod command-line interface provides project creation, code generation, and migration management.

### Installation Command

Install globally via Dart's package manager:

```bash
dart pub global activate serverpod_cli
```

This installs the `serverpod` command globally on your system.

### Path Configuration

Ensure Dart global executables are in your PATH. If `serverpod` isn't recognized, add this to your shell configuration:

**macOS/Linux (Bash)**:
```bash
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

**macOS (Zsh)**:
```bash
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Windows**:
Add `%USERPROFILE%\AppData\Local\Pub\Cache\bin` to your system PATH environment variable.

### Verification

Confirm successful installation:

```bash
serverpod --version
serverpod help
```

You should see version information and available commands.

### Updating Serverpod

Keep your CLI up to date to access latest features and bug fixes:

```bash
dart pub global activate serverpod_cli
```

This command upgrades to the newest version.

## Creating Your First Project

Serverpod's project creation generates a complete development environment including server, client library, and Flutter application.

### Project Creation Command

Create a new project with:

```bash
serverpod create my_app
```

Replace `my_app` with your project name (use snake_case).

### Project Structure

The command generates three interconnected packages:

```
my_app/
├── my_app_server/          # Backend server package
├── my_app_client/          # Generated client library
├── my_app_flutter/         # Flutter application
└── docker-compose.yaml     # Local database configuration
```

**Server Package** (`my_app_server/`):
- Contains endpoint definitions in `lib/src/endpoints/`
- Model definitions in YAML files
- Configuration files in `config/`
- Database migrations in `migrations/`
- Server entry point at `bin/main.dart`

**Client Package** (`my_app_client/`):
- Auto-generated code (never edit manually)
- Synchronized with server models and endpoints
- Used by Flutter and other Dart clients

**Flutter Package** (`my_app_flutter/`):
- Standard Flutter project structure
- Pre-configured to connect to local server
- Example UI demonstrating endpoint calls

### Generated Files

Key files created during project setup:

**docker-compose.yaml**: Defines PostgreSQL and Redis services for local development

**my_app_server/config/development.yaml**: Development environment configuration including database connection settings

**my_app_server/config/passwords.yaml**: Stores secrets (excluded from version control)

**my_app_server/lib/src/endpoints/example_endpoint.dart**: Sample endpoint demonstrating basic functionality

**my_app_flutter/lib/main.dart**: Flutter app configured to connect to your server

### Monorepo Considerations

Serverpod projects use a monorepo structure by default, keeping server, client, and Flutter app in the same repository. This approach:

- Simplifies version synchronization
- Enables atomic commits across frontend and backend
- Facilitates code sharing between packages

For larger teams, consider separate repositories with version pinning between client and server packages.

## Development Environment Setup

### Starting the Database

Navigate to your project root and start PostgreSQL via Docker:

```bash
cd my_app
docker compose up -d
```

The `-d` flag runs containers in detached mode (background). Initial startup downloads PostgreSQL images (one-time operation).

**Verify Database**:
```bash
docker compose ps
```

You should see the PostgreSQL container running on port 5432.

**Database Credentials** (from docker-compose.yaml):
- Host: localhost
- Port: 5432
- Database: my_app
- Username: postgres
- Password: (specified in development.yaml or docker-compose.yaml)

### Running the Server

Open a terminal in the server package directory:

```bash
cd my_app_server
```

Install dependencies (first time only):

```bash
dart pub get
```

Start the server with automatic migration application:

```bash
dart run bin/main.dart --apply-migrations
```

The `--apply-migrations` flag ensures database schema stays synchronized with your models.

**Server Ports**:
- **8080**: API endpoint (HTTP/WebSocket)
- **8081**: Serverpod Insights connection
- **8082**: Web server (if enabled)

**Successful Startup Indicators**:
- "Server successfully started" message
- No connection errors to PostgreSQL
- Migrations applied successfully

### Running the Flutter App

Open a new terminal in the Flutter package directory:

```bash
cd my_app_flutter
```

Install dependencies:

```bash
flutter pub get
```

Launch on your preferred platform:

```bash
# Web (Chrome)
flutter run -d chrome

# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# macOS Desktop
flutter run -d macos
```

The app connects to `http://localhost:8080` by default (configured in `lib/main.dart`).

### Hot Reload Workflow

Both server and Flutter support hot reload:

**Server Changes**:
1. Modify endpoint code
2. Server automatically reloads (no restart needed)
3. For model changes, run `serverpod generate` and restart server

**Flutter Changes**:
1. Modify UI code
2. Press `r` in the terminal for hot reload
3. Press `R` for hot restart

## Configuration Files

Serverpod uses environment-specific configuration files in the `config/` directory.

### Environment Configurations

Three configuration files support different deployment stages:

**development.yaml**: Local development settings (default)
- Database: localhost:5432
- Logging: verbose
- Auto-reload: enabled

**staging.yaml**: Pre-production testing environment
- Database: staging database server
- Logging: moderate
- Similar configuration to production for testing

**production.yaml**: Production deployment settings
- Database: production database server
- Logging: errors and warnings only
- Optimized for performance

### Configuration Structure

Example `development.yaml`:

```yaml
apiServer:
  port: 8080
  publicHost: localhost
  publicPort: 8080
  publicScheme: http

insights:
  port: 8081
  publicHost: localhost
  publicPort: 8081
  publicScheme: http

webServer:
  port: 8082
  publicHost: localhost
  publicPort: 8082
  publicScheme: http

database:
  host: localhost
  port: 5432
  name: my_app
  user: postgres

redis:
  enabled: false  # Enable for distributed caching
  host: localhost
  port: 6379
```

### Passwords and Secrets

The `config/passwords.yaml` file stores sensitive information:

```yaml
development:
  database: 'your_database_password'

staging:
  database: 'staging_database_password'

production:
  database: 'production_database_password'
```

**Security**:
- Add `config/passwords.yaml` to `.gitignore` (done automatically)
- Never commit passwords to version control
- Use environment variables in production (alternative to passwords.yaml)

### Environment Variable Override

Override configuration using environment variables:

```bash
# Database password
export SERVERPOD_PASSWORD_DATABASE='my_secure_password'

# Run mode
export SERVERPOD_RUN_MODE='production'

# Start server
dart run bin/main.dart
```

Environment variables follow the pattern: `SERVERPOD_PASSWORD_<key>='value'`

Variables take precedence over passwords.yaml values.

## VS Code Extension

Install the Serverpod extension for enhanced development experience.

### Installation

1. Open VS Code Extensions (Cmd/Ctrl + Shift + X)
2. Search for "Serverpod"
3. Click Install on the official Serverpod extension

### Features

**Syntax Highlighting**: `.spy.yaml` model files get proper syntax highlighting and indentation

**Code Snippets**:
- `serverpod-class`: Generate model class boilerplate
- `serverpod-endpoint`: Create endpoint class structure
- `serverpod-exception`: Define custom exception

**Validation**: Real-time YAML validation for model definitions, showing errors before code generation

**Navigation**: Jump to definition for related models and classes

### Configuration

Access extension settings via Preferences > Extensions > Serverpod:

- **Auto-generate on save**: Automatically run `serverpod generate` when saving `.spy.yaml` files (optional)
- **Serverpod CLI path**: Specify custom CLI location if not in PATH

## Serverpod Insights

The Serverpod Insights desktop application provides monitoring, debugging, and database management.

### Installation

Download from [serverpod.dev](https://serverpod.dev) for macOS or Windows.

**macOS**:
1. Download DMG file
2. Drag to Applications folder
3. Grant permissions if prompted

**Windows**:
1. Download installer
2. Run installation wizard
3. Launch from Start menu

### Connecting to Server

1. Start your Serverpod server
2. Open Serverpod Insights
3. Enter connection details:
   - **Host**: localhost
   - **Port**: 8081 (Insights port from config)
   - **Password**: (if configured)

### Features

**Database Browser**:
- View all tables and data
- Edit records directly
- Execute custom SQL queries
- Export data to CSV

**Log Viewer**:
- Real-time log streaming
- Filter by severity level
- Search log messages
- View exception stack traces

**Performance Monitoring**:
- Endpoint call frequency and duration
- Database query performance
- Slow query identification
- Resource utilization graphs

**Connection Management**:
- Save multiple server configurations
- Switch between development/staging/production
- Secure credential storage

## Project Customization

### Renaming Package

If you want to rename your project after creation:

1. Rename project directories
2. Update `pubspec.yaml` name fields in all three packages
3. Update import statements throughout codebase
4. Update `docker-compose.yaml` database name
5. Regenerate code: `serverpod generate`

### Adding Dependencies

Add server dependencies to `my_app_server/pubspec.yaml`:

```yaml
dependencies:
  serverpod: ^3.x.x
  your_package: ^1.0.0
```

Then run:

```bash
cd my_app_server
dart pub get
```

Client dependencies go in `my_app_flutter/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  my_app_client:
    path: ../my_app_client
  your_flutter_package: ^1.0.0
```

### Module Integration

Serverpod supports modules for reusable functionality. Add modules to your server:

```yaml
dependencies:
  serverpod: ^3.x.x
  serverpod_auth_idp_server: ^3.x.x  # Authentication module
```

Modules automatically integrate with code generation and migrations.

## Common Setup Issues

### Database Connection Failures

**Symptom**: Server fails to start with PostgreSQL connection errors

**Solutions**:
- Verify Docker container is running: `docker compose ps`
- Check port 5432 isn't used by another process: `lsof -i :5432` (macOS/Linux)
- Ensure credentials in `development.yaml` match `docker-compose.yaml`
- Reset database: `docker compose down -v` then `docker compose up -d`

### Port Already in Use

**Symptom**: "Port 8080 already in use" error

**Solutions**:
- Kill process using port: `lsof -ti:8080 | xargs kill` (macOS/Linux)
- Change server port in `config/development.yaml`
- Update Flutter app to match new port in client initialization

### Code Generation Errors

**Symptom**: `serverpod generate` fails with errors

**Solutions**:
- Ensure you're in the server package directory
- Validate YAML syntax in model files
- Check model field types are supported
- Update Serverpod CLI to latest version

### Flutter Connection Issues

**Symptom**: Flutter app can't reach server

**Solutions**:
- Verify server is running on port 8080
- Check client initialization in Flutter app matches server URL
- For mobile emulators, use `10.0.2.2` (Android) or `localhost` (iOS) instead of localhost
- For physical devices, use your machine's IP address

### Migration Failures

**Symptom**: Migrations fail to apply during server startup

**Solutions**:
- Check migration SQL for syntax errors in `migrations/` directory
- Verify database connection is working
- Drop database and recreate if in development: `docker compose down -v && docker compose up -d`
- Review migration logs for specific error messages

## Next Steps

With your development environment configured, you're ready to:

1. **Define Models**: Create `.spy.yaml` files describing your data structures
2. **Build Endpoints**: Implement server-side business logic and API methods
3. **Integrate Flutter**: Call endpoints from your Flutter application
4. **Add Features**: Implement authentication, real-time updates, or file uploads
5. **Deploy**: Prepare for production deployment to cloud platforms

The foundation is set for building scalable, type-safe, full-stack Dart applications with Serverpod.
