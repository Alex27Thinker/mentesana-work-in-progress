---
name: flutter-core:flutter-serverpod
description: Comprehensive Serverpod backend framework expertise for full-stack Dart/Flutter development. Use when building server-side applications with Serverpod, implementing backends for Flutter apps, working with type-safe ORMs, creating real-time features, managing authentication, or deploying production Dart servers. Covers installation, project setup, endpoints, database operations, authentication, real-time communication, file uploads, deployment, and testing.
skill_version: 1.0.0
skill_type: reference
triggered_by:
  - serverpod
  - backend Dart
  - full-stack Flutter
  - Flutter server
  - Dart backend framework
references:
  - references/serverpod-setup.md
  - references/endpoints.md
  - references/database-orm.md
  - references/authentication.md
  - references/real-time.md
  - references/file-uploads.md
  - references/deployment.md
  - examples/full-stack-app.md
  - examples/api-integration.md
---

# Serverpod Backend Framework

Build production-ready, full-stack Flutter applications using Dart for both frontend and backend with Serverpod, the next-generation app server explicitly designed for the Flutter and Dart ecosystem.

## Overview

Serverpod is an open-source, scalable backend framework that enables developers to write complete applications—frontend and backend—using only Dart. It eliminates context-switching between programming languages and provides a streamlined development experience with automated code generation, type-safe database operations, and built-in real-time capabilities.

### Core Philosophy

**Single Language Stack**: Write your entire application in Dart, from Flutter UI to server-side business logic, reducing cognitive load and maintaining consistent patterns across your codebase.

**Type Safety Throughout**: Serverpod's code generation ensures type safety from database queries through API endpoints to client applications, catching errors at compile time rather than runtime.

**Developer Productivity**: Automated code generation, hot reload support, and intuitive APIs enable rapid development without sacrificing code quality or maintainability.

## Key Capabilities

### Type-Safe ORM

Serverpod provides a sophisticated ORM that translates Dart code into optimized PostgreSQL queries. Define your data models in YAML, and Serverpod generates fully typed database operations with support for complex queries, relations, and migrations.

**Benefits**: No SQL injection vulnerabilities, compile-time query validation, auto-completion for database operations, and seamless integration with your Dart types.

### Real-Time Communication

Built-in WebSocket support enables streaming data between server and client through Dart's native Stream API. Serverpod automatically manages connections, handles failures, and pipes multiple concurrent streams through a single WebSocket connection.

**Use Cases**: Live chat, real-time notifications, multiplayer games, collaborative editing, and any feature requiring instant data synchronization.

### Integrated Authentication

Production-ready authentication supporting email/password, Google Sign-In, and Apple Sign-In out of the box. Choose between JWT-based stateless authentication or traditional server-side sessions based on your architecture needs.

**Features**: Two-factor authentication, custom identity providers, automatic token refresh, and beautiful pre-built UI components that can be customized or replaced.

### File Upload Management

Handle file uploads with configurable storage backends including Amazon S3, Google Cloud Storage, or PostgreSQL. Serverpod manages upload permissions, file verification, and provides convenient access methods.

**Configuration**: Set file size limits, validate MIME types, generate signed URLs for secure access, and seamlessly switch between storage providers.

### Scheduled Tasks

Replace complex cron jobs with type-safe future calls. Schedule method invocations at specific times or after delays, with automatic persistence across server restarts.

**Reliability**: Failed calls can be retried automatically, execution status is monitored, and scheduled tasks integrate seamlessly with your existing endpoint methods.

## Development Workflow

### Project Initialization

Creating a Serverpod project generates three integrated packages:

1. **Server Package**: Contains your backend code including endpoints, business logic, database models, and configuration
2. **Client Package**: Auto-generated typed API client for communicating with your server from any Dart application
3. **Flutter Package**: Pre-configured Flutter application ready to connect to your local development server

This structure supports monorepo workflows and makes it easy to share types and validation logic across your stack.

### Code Generation

Serverpod's CLI analyzes your YAML model definitions and endpoint implementations, generating:

- Serializable Dart classes for both server and client
- Database table schemas and migration scripts
- Type-safe database query builders
- Client-side API methods that mirror your endpoints
- Protocol definitions for network communication

Run `serverpod generate` after modifying models or endpoints to keep everything synchronized.

### Local Development

The development environment uses Docker Compose to provide PostgreSQL and optional Redis services. Start the database with `docker compose up`, launch your server with `dart run bin/main.dart --apply-migrations`, and run your Flutter app with `flutter run`.

Changes to endpoints are immediately available after code generation. Database schema changes are managed through migrations, ensuring data integrity during development.

## Architecture Patterns

### Endpoint Organization

Structure endpoints by feature or domain rather than technical concerns. Each endpoint extends the `Endpoint` base class and contains related method groups. Use abstract endpoints to share common logic across multiple concrete endpoints.

**Naming**: Serverpod automatically removes the "Endpoint" suffix when generating client code, so `UserEndpoint` becomes `client.user` in the client application.

### Model Design

Define models in `.spy.yaml` files within your server's `lib` directory. Models support inheritance, sealed classes for exhaustive type checking, and field visibility control for sensitive data.

**Database Mapping**: Add a `table` property to persist models to PostgreSQL. Serverpod handles index creation, foreign keys, and schema migrations automatically.

### Separation of Concerns

Keep business logic in separate classes that endpoints call, making code testable independent of the network layer. Use dependency injection to provide database sessions, external API clients, or configuration to your business logic.

**Testing**: Serverpod's test framework provides the `withServerpod` helper for integration tests, automatically handling database transactions and cleanup.

## Database Best Practices

### Query Optimization

Use `include` methods to eagerly load related data in a single query rather than making multiple database round trips. Apply filters before includes to reduce data transfer.

**Pagination**: Always use `limit` and `offset` for large result sets. Consider cursor-based pagination for real-time feeds or infinite scroll interfaces.

### Migration Strategy

Create migrations after model changes with `serverpod create-migration`, review the generated SQL, and apply migrations during server startup with the `--apply-migrations` flag.

**Production**: Use maintenance mode for zero-downtime deployments, applying migrations before switching traffic to new server instances.

### Indexing

Serverpod automatically creates indexes for foreign keys and fields marked with `!dbindex`. For complex queries, add custom indexes through migration SQL or use database-specific features.

## Authentication Architecture

### Token Management

Choose JWT for stateless authentication suitable for serverless deployments or server-side sessions for traditional architectures. JWTs reduce database queries but require careful key management, while sessions provide easier revocation but add database overhead.

**Configuration**: Store secrets in `config/passwords.yaml` (excluded from version control) or environment variables following the `SERVERPOD_PASSWORD_<key>` pattern.

### Identity Providers

Implement identity providers by extending abstract endpoint classes and configuring provider-specific settings. Each provider handles its own OAuth flow, token exchange, and user profile retrieval.

**Custom Providers**: Create custom identity providers for enterprise SSO, SAML, or proprietary authentication systems by implementing the identity provider interface.

## Deployment Considerations

### Docker Containers

Serverpod projects include Dockerfiles configured for production deployment. Build containers with `docker build`, configure runtime behavior through environment variables, and deploy to any container orchestration platform.

**Environment Variables**: Control run mode (development/staging/production), server role (monolith/serverless/maintenance), and logging verbosity through container environment configuration.

### Cloud Platforms

Deploy to AWS using provided Terraform scripts that configure autoscaling EC2 clusters, RDS PostgreSQL, ElastiCache Redis, S3 storage, CloudFront CDN, and Route 53 DNS. Google Cloud Platform deployment follows similar patterns with GCP-specific resources.

**Managed Services**: Serverpod Cloud (currently in private beta) provides fully managed hosting with automatic scaling, monitoring, and zero-configuration deployment.

### Monitoring and Observability

Serverpod Insights provides real-time monitoring of database queries, endpoint performance, and error logs. Integrate with external services like Sentry, Datadog, or Highlight using diagnostic event handlers.

**Custom Logging**: Use `session.log()` for application-specific logging with configurable severity levels. Logs persist to the database and are searchable through Serverpod Insights.

## Performance Optimization

### Caching Strategies

Serverpod provides three cache types: local cache for single-server deployments, priority cache for frequently accessed items, and distributed Redis cache for multi-server clusters.

**Cache Miss Handlers**: Automatically populate cache on misses by providing handler functions that load from the database and store results with configurable TTL.

### Connection Pooling

Database connections are pooled automatically. Configure pool sizes in your environment's config file based on expected concurrent load and database server capacity.

**Redis**: Optional Redis integration provides distributed locking, pub/sub messaging, and cluster-wide caching. Enable through configuration without code changes.

## Testing Strategy

### Integration Tests

Use `withServerpod` to create isolated test environments with automatic database cleanup. Each test runs in a transaction that rolls back after completion, ensuring tests don't interfere with each other.

**Authentication Testing**: Override authentication state using `AuthenticationOverride.authenticationInfo()` to test protected endpoints without requiring actual login flows.

### Unit Tests

Test business logic independently of Serverpod infrastructure by injecting mock sessions or database connections. Separate unit tests (testing pure logic) from integration tests (testing with real database).

**Organization**: Place unit tests in `test/unit` and integration tests in `test/integration`, using test tags to run them separately during CI/CD pipelines.

## When to Use Serverpod

### Ideal Scenarios

**Flutter-First Development**: When building applications where Flutter is the primary or only client, Serverpod's Dart-to-Dart communication eliminates friction and maintains type safety across the entire stack.

**Real-Time Applications**: Games, chat systems, collaborative tools, or live dashboards benefit from Serverpod's built-in streaming capabilities and efficient WebSocket management.

**Rapid Prototyping**: The combination of code generation, type safety, and integrated development tools enables faster iteration than traditional backend frameworks.

**Team Consistency**: Teams already proficient in Dart can immediately contribute to backend code without learning new languages, frameworks, or paradigms.

### Limitations to Consider

**Non-Dart Clients**: While Serverpod can serve generic HTTP/WebSocket clients, the generated client libraries and type safety benefits are Dart-specific. Consider GraphQL or REST frameworks if supporting diverse client platforms.

**Database Support**: Serverpod currently supports only PostgreSQL. Applications requiring MySQL, MongoDB, or other databases need to use them through custom integrations without ORM benefits.

**Ecosystem Maturity**: Compared to established frameworks like Django, Rails, or Express, Serverpod has fewer third-party integrations, examples, and community resources, though the ecosystem is growing rapidly.

## Learning Path

1. **Installation and Setup**: Follow the getting started guide to install the CLI, create your first project, and understand the generated structure
2. **Endpoints and Models**: Learn to define YAML models, create endpoints, and call them from Flutter applications
3. **Database Operations**: Master CRUD operations, filtering, relations, and migrations for data persistence
4. **Authentication**: Implement user registration and login with built-in identity providers
5. **Real-Time Features**: Add streaming endpoints for live data updates and notifications
6. **Deployment**: Deploy to production using Docker and cloud platform integrations
7. **Advanced Patterns**: Explore caching, scheduled tasks, file uploads, and performance optimization

## Resources

- **Official Documentation**: [docs.serverpod.dev](https://docs.serverpod.dev) - Comprehensive guides, API references, and tutorials
- **GitHub Repository**: [github.com/serverpod/serverpod](https://github.com/serverpod/serverpod) - Source code, examples, and issue tracking
- **Community**: Discord server for real-time help, GitHub Discussions for Q&A, and regular hackathons
- **Serverpod Insights**: Native macOS/Windows application for monitoring, debugging, and database inspection

Serverpod represents a paradigm shift for Flutter developers, enabling true full-stack development with a single language and unified tooling. By leveraging Dart throughout your application stack, you can build faster, maintain easier, and deploy with confidence.
