# Multi-Layer Caching Strategy with TTL

This example demonstrates a comprehensive caching strategy combining in-memory caching, persistent storage with Hive, and network fetching with intelligent TTL (Time-To-Live) management for optimal performance and offline support.

## Architecture Overview

The caching system uses three layers:

1. **L1 Cache (Memory)** - Fastest access, volatile, limited size
2. **L2 Cache (Hive)** - Persistent, survives app restarts, larger capacity
3. **L3 Source (Network)** - Authoritative source, slowest, requires connectivity

Data flows from L3 → L2 → L1 when fetching, and is checked in reverse order (L1 → L2 → L3) when reading.

## Cache Entry Model

Define cache entries with metadata:

```dart
import 'package:hive/hive.dart';

part 'cache_entry.g.dart';

@HiveType(typeId: 0)
class CacheEntry<T> extends HiveObject {
  @HiveField(0)
  final T data;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final DateTime? expiresAt;

  @HiveField(3)
  final String? etag;

  @HiveField(4)
  final Map<String, dynamic>? metadata;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiresAt,
    this.etag,
    this.metadata,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get age => DateTime.now().difference(timestamp);

  CacheEntry<T> copyWith({
    T? data,
    DateTime? timestamp,
    DateTime? expiresAt,
    String? etag,
    Map<String, dynamic>? metadata,
  }) {
    return CacheEntry(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      etag: etag ?? this.etag,
      metadata: metadata ?? this.metadata,
    );
  }
}
```

## Multi-Layer Cache Manager

Implement the core caching logic:

```dart
import 'dart:collection';
import 'package:hive/hive.dart';

class CacheConfig {
  final Duration defaultTtl;
  final int maxMemoryEntries;
  final bool enableEtagValidation;
  final bool enableStaleWhileRevalidate;

  const CacheConfig({
    this.defaultTtl = const Duration(hours: 1),
    this.maxMemoryEntries = 100,
    this.enableEtagValidation = true,
    this.enableStaleWhileRevalidate = true,
  });
}

class MultiLayerCache<T> {
  final String namespace;
  final CacheConfig config;
  final Future<T> Function(String key) fetcher;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  // L1: In-memory cache (LRU)
  final LinkedHashMap<String, CacheEntry<T>> _memoryCache = LinkedHashMap();

  // L2: Persistent cache (Hive)
  late Box<Map<String, dynamic>> _persistentCache;

  MultiLayerCache({
    required this.namespace,
    required this.fetcher,
    required this.fromJson,
    required this.toJson,
    this.config = const CacheConfig(),
  });

  Future<void> init() async {
    _persistentCache = await Hive.openBox<Map<String, dynamic>>(
      'cache_$namespace',
    );
  }

  Future<T> get(String key, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? config.defaultTtl;

    // Check L1 (memory)
    final memoryEntry = _getFromMemory(key);
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data;
    }

    // Check L2 (persistent)
    final persistentEntry = await _getFromPersistent(key);
    if (persistentEntry != null) {
      if (!persistentEntry.isExpired) {
        // Promote to L1
        _putInMemory(key, persistentEntry);
        return persistentEntry.data;
      }

      // Stale-while-revalidate: return stale data, fetch in background
      if (config.enableStaleWhileRevalidate) {
        _revalidateInBackground(key, effectiveTtl);
        _putInMemory(key, persistentEntry);
        return persistentEntry.data;
      }
    }

    // Fetch from L3 (network)
    return await _fetchAndCache(key, effectiveTtl);
  }

  Future<T?> getIfPresent(String key) async {
    final memoryEntry = _getFromMemory(key);
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data;
    }

    final persistentEntry = await _getFromPersistent(key);
    if (persistentEntry != null && !persistentEntry.isExpired) {
      _putInMemory(key, persistentEntry);
      return persistentEntry.data;
    }

    return null;
  }

  Future<void> put(String key, T data, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? config.defaultTtl;
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(effectiveTtl),
    );

    _putInMemory(key, entry);
    await _putInPersistent(key, entry);
  }

  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _persistentCache.delete(key);
  }

  Future<void> invalidateAll() async {
    _memoryCache.clear();
    await _persistentCache.clear();
  }

  Future<void> invalidatePattern(bool Function(String key) predicate) async {
    final keysToRemove = _memoryCache.keys.where(predicate).toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    final persistentKeys = _persistentCache.keys.where(predicate).toList();
    for (final key in persistentKeys) {
      await _persistentCache.delete(key);
    }
  }

  Future<void> cleanExpired() async {
    // Clean memory cache
    final expiredMemoryKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredMemoryKeys) {
      _memoryCache.remove(key);
    }

    // Clean persistent cache
    for (final key in _persistentCache.keys) {
      final entry = await _getFromPersistent(key);
      if (entry?.isExpired ?? false) {
        await _persistentCache.delete(key);
      }
    }
  }

  CacheEntry<T>? _getFromMemory(String key) {
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      // LRU: Move to end (most recently used)
      _memoryCache[key] = entry;
    }
    return entry;
  }

  void _putInMemory(String key, CacheEntry<T> entry) {
    _memoryCache.remove(key);
    _memoryCache[key] = entry;

    // Enforce size limit (LRU eviction)
    while (_memoryCache.length > config.maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  Future<CacheEntry<T>?> _getFromPersistent(String key) async {
    final data = _persistentCache.get(key);
    if (data == null) return null;

    try {
      return CacheEntry<T>(
        data: fromJson(data['data'] as Map<String, dynamic>),
        timestamp: DateTime.parse(data['timestamp'] as String),
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'] as String)
            : null,
        etag: data['etag'] as String?,
        metadata: data['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      // Invalid cache entry, remove it
      await _persistentCache.delete(key);
      return null;
    }
  }

  Future<void> _putInPersistent(String key, CacheEntry<T> entry) async {
    await _persistentCache.put(key, {
      'data': toJson(entry.data),
      'timestamp': entry.timestamp.toIso8601String(),
      'expiresAt': entry.expiresAt?.toIso8601String(),
      'etag': entry.etag,
      'metadata': entry.metadata,
    });
  }

  Future<T> _fetchAndCache(String key, Duration ttl) async {
    final data = await fetcher(key);
    await put(key, data, ttl: ttl);
    return data;
  }

  void _revalidateInBackground(String key, Duration ttl) {
    // Don't await - fire and forget
    _fetchAndCache(key, ttl).catchError((error) {
      print('Background revalidation failed for $key: $error');
    });
  }

  Future<Map<String, dynamic>> getStats() async {
    final memorySize = _memoryCache.length;
    final persistentSize = _persistentCache.length;

    var expiredCount = 0;
    for (final key in _persistentCache.keys) {
      final entry = await _getFromPersistent(key);
      if (entry?.isExpired ?? false) {
        expiredCount++;
      }
    }

    return {
      'memory_entries': memorySize,
      'persistent_entries': persistentSize,
      'expired_entries': expiredCount,
      'max_memory_entries': config.maxMemoryEntries,
    };
  }

  Future<void> close() async {
    await _persistentCache.close();
  }
}
```

## API Response Cache Example

Use the cache for API responses:

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

class UserCache {
  late MultiLayerCache<User> _cache;

  Future<void> init() async {
    _cache = MultiLayerCache<User>(
      namespace: 'users',
      fetcher: (key) async {
        // Fetch from API
        final response = await http.get(
          Uri.parse('https://api.example.com/users/$key'),
        );
        return User.fromJson(jsonDecode(response.body));
      },
      fromJson: User.fromJson,
      toJson: (user) => user.toJson(),
      config: const CacheConfig(
        defaultTtl: Duration(minutes: 15),
        maxMemoryEntries: 50,
        enableStaleWhileRevalidate: true,
      ),
    );

    await _cache.init();
  }

  Future<User> getUser(int userId) async {
    return await _cache.get(userId.toString());
  }

  Future<User?> getUserIfCached(int userId) async {
    return await _cache.getIfPresent(userId.toString());
  }

  Future<void> updateUser(User user) async {
    await _cache.put(user.id.toString(), user);
  }

  Future<void> invalidateUser(int userId) async {
    await _cache.invalidate(userId.toString());
  }

  Future<void> close() async {
    await _cache.close();
  }
}
```

## List Data Cache with Pagination

Handle paginated list caching:

```dart
class PaginatedData<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalItems;

  PaginatedData({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PaginatedData(
      items: (json['items'] as List)
          .map((item) => itemFromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      totalPages: json['total_pages'] as int,
      totalItems: json['total_items'] as int,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) itemToJson) {
    return {
      'items': items.map(itemToJson).toList(),
      'page': page,
      'total_pages': totalPages,
      'total_items': totalItems,
    };
  }
}

class PostsCache {
  late MultiLayerCache<PaginatedData<Post>> _cache;

  Future<void> init() async {
    _cache = MultiLayerCache<PaginatedData<Post>>(
      namespace: 'posts',
      fetcher: (key) async {
        final page = int.parse(key.split('_')[1]);
        final response = await http.get(
          Uri.parse('https://api.example.com/posts?page=$page'),
        );
        return PaginatedData.fromJson(
          jsonDecode(response.body),
          Post.fromJson,
        );
      },
      fromJson: (json) => PaginatedData.fromJson(json, Post.fromJson),
      toJson: (data) => data.toJson((post) => post.toJson()),
      config: const CacheConfig(
        defaultTtl: Duration(minutes: 5),
        maxMemoryEntries: 20, // Cache 20 pages
        enableStaleWhileRevalidate: true,
      ),
    );

    await _cache.init();
  }

  Future<PaginatedData<Post>> getPosts(int page) async {
    return await _cache.get('page_$page');
  }

  Future<void> invalidatePage(int page) async {
    await _cache.invalidate('page_$page');
  }

  Future<void> invalidateAllPages() async {
    await _cache.invalidatePattern(
      (key) => key.startsWith('page_'),
    );
  }

  Future<void> close() async {
    await _cache.close();
  }
}

class Post {
  final int id;
  final String title;
  final String content;

  Post({required this.id, required this.title, required this.content});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'content': content};
  }
}
```

## Cache Warming Strategy

Pre-populate cache with frequently accessed data:

```dart
class CacheWarmer {
  final UserCache userCache;
  final PostsCache postsCache;

  CacheWarmer({
    required this.userCache,
    required this.postsCache,
  });

  Future<void> warmCriticalData() async {
    // Warm user cache with current user
    final currentUserId = await getCurrentUserId();
    await userCache.getUser(currentUserId);

    // Warm posts cache with first page
    await postsCache.getPosts(1);
  }

  Future<void> warmUserFeed(List<int> userIds) async {
    // Fetch users in parallel
    await Future.wait(
      userIds.map((id) => userCache.getUser(id)),
    );
  }

  Future<int> getCurrentUserId() async {
    // Get from secure storage or API
    return 1;
  }
}
```

## Background Cache Maintenance

Implement periodic cache cleanup:

```dart
import 'dart:async';

class CacheMaintenanceService {
  final List<MultiLayerCache> caches;
  Timer? _cleanupTimer;

  CacheMaintenanceService(this.caches);

  void startPeriodicCleanup({
    Duration interval = const Duration(hours: 1),
  }) {
    _cleanupTimer = Timer.periodic(interval, (_) async {
      await cleanupExpiredEntries();
    });
  }

  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  Future<void> cleanupExpiredEntries() async {
    for (final cache in caches) {
      await cache.cleanExpired();
    }
  }

  Future<Map<String, dynamic>> getAllStats() async {
    final stats = <String, dynamic>{};

    for (final cache in caches) {
      stats[cache.namespace] = await cache.getStats();
    }

    return stats;
  }

  Future<void> closeAll() async {
    stopPeriodicCleanup();
    for (final cache in caches) {
      await cache.close();
    }
  }
}
```

## Usage Example

Putting it all together:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize caches
  final userCache = UserCache();
  await userCache.init();

  final postsCache = PostsCache();
  await postsCache.init();

  // Set up maintenance
  final maintenance = CacheMaintenanceService([
    userCache._cache,
    postsCache._cache,
  ]);
  maintenance.startPeriodicCleanup();

  // Warm critical data
  final warmer = CacheWarmer(
    userCache: userCache,
    postsCache: postsCache,
  );
  await warmer.warmCriticalData();

  runApp(MyApp(
    userCache: userCache,
    postsCache: postsCache,
    maintenance: maintenance,
  ));
}

class MyApp extends StatelessWidget {
  final UserCache userCache;
  final PostsCache postsCache;
  final CacheMaintenanceService maintenance;

  const MyApp({
    required this.userCache,
    required this.postsCache,
    required this.maintenance,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(userCache: userCache, postsCache: postsCache),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final UserCache userCache;
  final PostsCache postsCache;

  const HomeScreen({
    required this.userCache,
    required this.postsCache,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<PaginatedData<Post>> _postsFuture;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _postsFuture = widget.postsCache.getPosts(_currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cached Posts')),
      body: FutureBuilder<PaginatedData<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final post = data.items[index];
                    return ListTile(
                      title: Text(post.title),
                      subtitle: Text(post.content),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadPosts();
                          }
                        : null,
                    child: Text('Previous'),
                  ),
                  Text('Page $_currentPage of ${data.totalPages}'),
                  ElevatedButton(
                    onPressed: _currentPage < data.totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadPosts();
                          }
                        : null,
                    child: Text('Next'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Force refresh current page
          await widget.postsCache.invalidatePage(_currentPage);
          _loadPosts();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

This example demonstrates a production-ready caching strategy with multiple layers, TTL management, stale-while-revalidate pattern, and automatic cleanup for optimal performance and offline support.
