---
name: flutter-core:flutter-persistence
description: Comprehensive guide to local data persistence in Flutter covering SharedPreferences, SQLite, Hive, Drift, and file storage strategies
triggers:
  - "persist data"
  - "local storage"
  - "save data locally"
  - "SharedPreferences"
  - "SQLite"
  - "Hive"
  - "Drift"
  - "file storage"
  - "cache data"
  - "offline storage"
---

# Flutter Persistence

Master local data persistence in Flutter applications with comprehensive coverage of key-value storage, relational databases, NoSQL solutions, and file management. This skill provides practical guidance for implementing robust offline-first functionality and efficient data caching strategies.

## Core Concepts

Flutter applications require persistent storage to maintain state across app sessions, enable offline functionality, and improve performance through intelligent caching. The Flutter ecosystem provides multiple persistence solutions, each optimized for different use cases and data structures.

### Storage Solution Overview

**SharedPreferences** provides simple key-value storage ideal for user preferences, settings, and small configuration data. It wraps platform-specific storage mechanisms (NSUserDefaults on iOS, SharedPreferences on Android) with an async Dart API supporting primitives and string lists.

**SQLite (via sqflite)** offers full relational database capabilities with SQL query support, transactions, and ACID compliance. It excels at structured data with complex relationships, supporting joins, indexes, and migrations for evolving schemas.

**Hive** delivers high-performance NoSQL storage with a pure Dart implementation requiring no native dependencies. It provides type-safe box-based storage with built-in encryption, making it ideal for fast key-value access and offline-first apps across all platforms including web.

**Drift** builds on SQLite with compile-time type safety, generating Dart classes from database schemas. It provides reactive streams, DAO patterns, and fluent query builders while maintaining full SQL power for complex queries.

**File Storage** enables direct file system access through the path_provider package, supporting custom formats, large binary data, and document management with platform-agnostic directory paths.

## When to Use Each Storage Method

### SharedPreferences
Use SharedPreferences for simple, non-relational data that fits the key-value paradigm. Ideal scenarios include theme preferences, language settings, onboarding completion flags, API tokens (non-sensitive), and user interface state. It provides the fastest implementation time and lowest complexity but should not be used for critical data as writes may not be immediately persisted to disk.

**Best for**: User settings, feature flags, last sync timestamps, simple configuration
**Avoid for**: Large datasets, complex objects, sensitive data without encryption

### SQLite/sqflite
Choose SQLite when your data has clear relationships and requires complex querying. It suits applications needing ACID guarantees, transaction support, and data integrity. Use cases include todo lists with categories, messaging apps, e-commerce product catalogs, and any scenario requiring joins across multiple tables.

**Best for**: Structured relational data, complex queries, data integrity requirements
**Avoid for**: Simple key-value pairs, web platform (use Drift instead)

### Hive
Hive excels in scenarios requiring fast read/write performance with minimal setup. Its pure Dart implementation makes it perfect for cross-platform apps including web. Use Hive for caching API responses, storing user-generated content, managing app state, and implementing offline-first features.

**Best for**: Fast key-value access, cross-platform apps, offline caching, medium-sized datasets
**Avoid for**: Complex relational queries, very large datasets (millions of records)

### Drift
Select Drift when you need SQLite's power combined with Dart's type safety and modern reactive patterns. It reduces runtime errors through compile-time validation and simplifies testing with DAO abstractions. Ideal for large applications where maintainability and code quality are priorities.

**Best for**: Large-scale apps, reactive data streams, type-safe SQL, complex business logic
**Avoid for**: Simple apps, rapid prototyping, when learning curve is a concern

### File Storage
Use direct file storage for custom file formats, large binary data, documents, images, and scenarios requiring fine-grained control over serialization. Path_provider offers platform-appropriate directories for temporary files, application documents, and cached data.

**Best for**: Media files, documents, custom serialization, large binary data
**Avoid for**: Structured queries, concurrent access patterns, relational data

## Key-Value vs Database Storage

### Key-Value Storage (SharedPreferences, Hive)
Key-value storage treats data as simple pairs where each unique key maps to a single value. This model offers simplicity, predictable performance, and minimal overhead. Operations are straightforward: set a key, get a key, delete a key. There's no schema to define, no migrations to manage, and no complex query planning.

SharedPreferences handles primitives and string lists with an async API that abstracts platform differences. Hive extends this model with support for complex Dart objects through type adapters, offering better performance and richer data types while maintaining the key-value simplicity.

**Advantages**: Simple API, fast access, minimal setup, no schema changes
**Limitations**: No relationships, limited querying, linear scans for non-key lookups

### Database Storage (SQLite, Drift)
Database storage organizes data into tables with defined schemas and relationships. This structure enables complex queries joining multiple tables, filtering with WHERE clauses, and aggregating with GROUP BY. Indexes improve query performance, and transactions ensure data consistency during multi-step operations.

SQLite provides raw SQL power with full control over queries and schema. Drift adds compile-time type safety, generating Dart classes from table definitions and catching errors before runtime. Both support migrations to evolve schemas as requirements change.

**Advantages**: Complex queries, relationships, data integrity, transaction support
**Limitations**: Higher complexity, schema management, potential migration challenges

### Hybrid Approaches
Many production apps combine multiple storage solutions. A common pattern uses SharedPreferences for user settings, SQLite/Drift for primary application data, and Hive for caching API responses with TTL-based invalidation. This leverages each tool's strengths while maintaining clear separation of concerns.

## Implementation Patterns

### Layered Architecture
Separate persistence logic from business logic through repository patterns. Repositories abstract storage implementation details, making it easy to swap persistence mechanisms or combine multiple storage solutions. This pattern improves testability and maintains flexibility as requirements evolve.

### Offline-First Strategy
Design apps to work offline by default, syncing when connectivity is available. Use local persistence as the source of truth, implementing sync logic that handles conflicts and maintains consistency. This approach dramatically improves perceived performance and user experience.

### Cache Management
Implement intelligent caching with Time-To-Live (TTL) policies, size limits, and eviction strategies. Combine in-memory caches for frequently accessed data with persistent storage for offline access. Use cache keys that include version information to handle schema changes gracefully.

### Migration Strategies
Plan for schema evolution from the start. Version your database schemas and implement migration paths that preserve user data. Test migrations thoroughly, especially multi-version upgrades where users skip intermediate releases.

## Performance Considerations

### SharedPreferences Performance
SharedPreferences loads the entire preference file into memory on first access, making subsequent reads fast but initial load potentially slow for large preference files. The legacy API requires waiting for initialization; newer APIs like SharedPreferencesAsync and SharedPreferencesWithCache offer better performance characteristics.

### Hive Performance
Hive achieves excellent performance through lazy loading and efficient binary serialization. Boxes can be opened in lazy mode to defer loading values until accessed. For maximum performance, keep boxes focused on specific data domains rather than storing all data in a single box.

### SQLite Performance
SQLite performance depends heavily on proper indexing and query optimization. Create indexes on frequently queried columns, use EXPLAIN QUERY PLAN to understand query execution, and leverage transactions for batch operations. Database size and complexity of queries significantly impact performance.

### Drift Performance
Drift adds minimal overhead to SQLite while providing reactive streams that automatically update when underlying data changes. Use DAOs to organize related queries and leverage Drift's query builder for compile-time optimization. The reactive nature eliminates manual polling, improving both performance and code clarity.

## Security Considerations

Never store sensitive data in SharedPreferences without encryption, as it persists as plain text. For sensitive data, use flutter_secure_storage or Hive's encrypted boxes with proper key management. Store encryption keys in platform-specific secure storage (Keychain on iOS, KeyStore on Android).

When using SQLite, remember that database files are accessible on rooted/jailbroken devices. Implement encryption through packages like sqlcipher if storing sensitive information. Always validate and sanitize data before storage to prevent injection attacks and data corruption.

## Testing Strategies

Test persistence logic separately from UI code using repository abstractions. Mock storage implementations during unit tests to verify business logic without actual I/O. For integration tests, use in-memory databases or temporary directories that clean up automatically.

Drift's DAO pattern significantly improves testability by isolating database operations. Hive offers in-memory box implementations for testing. SharedPreferences can be tested using mock implementations available in the shared_preferences package.

## Migration and Versioning

Database migrations require careful planning and testing. Implement migrations that preserve user data while updating schema structure. Version databases explicitly and maintain migration paths across multiple versions. Test migrations with real user data to catch edge cases.

For Hive, handle schema changes by implementing custom TypeAdapters that support multiple versions. For SharedPreferences, use version keys to detect and handle preference format changes. Always provide fallback values for missing or corrupt data.

## Platform Considerations

SharedPreferences, sqflite, and Hive support mobile platforms natively. For desktop (Windows, Linux), sqflite requires sqflite_common_ffi. Hive and SharedPreferences work across all platforms including web. Drift provides unified support across all platforms through appropriate database implementations.

File storage paths differ significantly across platforms. Use path_provider to access platform-appropriate directories rather than hardcoding paths. Test file operations on all target platforms to ensure consistent behavior.

## When You're Done

After implementing persistence in your Flutter app:

1. **Verify offline functionality** - Test app behavior without network connectivity
2. **Check performance** - Profile app startup time and data access patterns
3. **Test migrations** - Verify schema updates work across different versions
4. **Validate security** - Ensure sensitive data is properly encrypted
5. **Review storage usage** - Monitor disk space consumption and implement cleanup strategies

## References

- **[shared-preferences.md](references/shared-preferences.md)** - Key-value storage with SharedPreferences
- **[sqflite.md](references/sqflite.md)** - SQLite database implementation
- **[hive.md](references/hive.md)** - NoSQL box storage with Hive
- **[drift.md](references/drift.md)** - Type-safe SQL with Drift ORM
- **[file-storage.md](references/file-storage.md)** - Direct file system access

## Examples

- **[local-database.md](examples/local-database.md)** - Complete SQLite implementation with migrations
- **[cache-strategy.md](examples/cache-strategy.md)** - Multi-layer caching with TTL management
