# Optimization Patterns: Real-World Examples

This guide demonstrates practical optimization patterns through real-world scenarios. Each pattern includes the problem, diagnosis, solution, and measurable results.

## Pattern 1: Optimizing List Scrolling

### Problem

Product list scrolls at 40fps instead of 60fps on mid-range devices.

### Diagnosis

```dart
// DevTools Performance View findings:
// - Frame time: 21ms average (target: 16ms)
// - Build phase: 15ms (excessive)
// - ProductCard.build called 60 times per second

// Original implementation
class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList(this.products);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(products[index]); // Rebuilds every frame
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard(this.product); // No const constructor

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Expensive lookup every build

    return Card(
      child: Column(
        children: [
          Image.network(product.imageUrl), // No caching
          Text(product.name),
          Text('\$${product.price}'),
          Row(
            children: [
              Icon(Icons.star), // Not const
              Text('${product.rating}'),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Solution

```dart
class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList(this.products);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      // Add RepaintBoundary to isolate repaints
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: ProductCard(products[index]),
        );
      },
      // Optimize cache extent
      cacheExtent: 100,
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  // Add const constructor
  const ProductCard(this.product);

  @override
  Widget build(BuildContext context) {
    // Extract theme once
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          // Use cached network image
          CachedNetworkImage(
            imageUrl: product.imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            // Resize during decoding
            memCacheWidth: 300,
          ),
          Text(product.name),
          Text('\$${product.price}'),
          // Use const constructors
          const Row(
            children: [
              Icon(Icons.star),
              SizedBox(width: 4),
            ],
          ),
          Text('${product.rating}'),
        ],
      ),
    );
  }
}
```

### Results

```
Before Optimization:
- Frame time: 21ms (40fps)
- Build time: 15ms
- Memory: 180MB

After Optimization:
- Frame time: 12ms (60fps+)
- Build time: 6ms
- Memory: 120MB

Improvements:
- 43% faster frame time
- 60% faster build time
- 33% less memory usage
```

## Pattern 2: Fixing Memory Leak in Navigation

### Problem

App crashes after navigating between screens 15-20 times. Memory usage grows continuously.

### Diagnosis

```dart
// DevTools Memory View findings:
// - Memory growth: 15MB per navigation cycle
// - Leaked instances: DetailScreen (10 instances after 10 navigations)
// - Retained by: _ProductController listeners

// Original implementation
class DetailScreen extends StatefulWidget {
  final Product product;

  const DetailScreen(this.product);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late ProductController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _controller = ProductController(widget.product);
    _controller.addListener(_onControllerUpdate);

    // Timer never cancelled
    _refreshTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _controller.refresh(),
    );
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProductDetails(_controller.product),
    );
  }

  // No dispose method - LEAK!
}

class ProductController extends ChangeNotifier {
  Product product;

  ProductController(this.product);

  Future<void> refresh() async {
    product = await fetchProduct(product.id);
    notifyListeners();
  }
}
```

### Solution

```dart
class _DetailScreenState extends State<DetailScreen> {
  late ProductController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _controller = ProductController(widget.product);
    _controller.addListener(_onControllerUpdate);

    _refreshTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) {
        // Check if still mounted
        if (mounted) {
          _controller.refresh();
        }
      },
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _refreshTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProductDetails(_controller.product),
    );
  }
}

class ProductController extends ChangeNotifier {
  Product product;

  ProductController(this.product);

  Future<void> refresh() async {
    product = await fetchProduct(product.id);
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up controller resources
    super.dispose();
  }
}
```

### Results

```
Before Fix:
- Memory growth: 15MB per cycle
- Crashes after: 15-20 navigations
- Leaked instances: 10+ DetailScreen

After Fix:
- Memory growth: 2MB per cycle (normal caching)
- No crashes: Tested 100+ navigations
- Leaked instances: 0

Improvements:
- 87% reduction in memory growth
- Crash eliminated
- Stable long-term usage
```

## Pattern 3: Optimizing JSON Parsing

### Problem

App freezes for 2-3 seconds when loading product catalog (1000+ items).

### Diagnosis

```dart
// DevTools CPU Profiler findings:
// - jsonDecode(): 1800ms on UI thread
// - Product.fromJson() called 1000 times: 1200ms
// - Total blocking time: 3000ms

// Original implementation
class ProductService {
  Future<List<Product>> loadProducts() async {
    final response = await http.get(Uri.parse('$apiUrl/products'));
    final String jsonString = response.body;

    // Blocking UI thread for 3 seconds!
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
```

### Solution

```dart
// Using isolate for heavy parsing
class ProductService {
  Future<List<Product>> loadProducts() async {
    final response = await http.get(Uri.parse('$apiUrl/products'));
    final String jsonString = response.body;

    // Parse in background isolate
    return await Isolate.run(() {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((json) => Product.fromJson(json)).toList();
    });
  }
}

// For repeated parsing, use long-lived isolate
class ProductParserIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  Future<void> start() async {
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
    _sendPort = await _receivePort.first as SendPort;
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      final String jsonString = message['data'];
      final int id = message['id'];

      // Parse in isolate
      final List<dynamic> data = jsonDecode(jsonString);
      final products = data.map((json) => Product.fromJson(json)).toList();

      sendPort.send({'id': id, 'result': products});
    });
  }

  Future<List<Product>> parse(String jsonString) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final completer = Completer<List<Product>>();

    // Set up one-time listener
    StreamSubscription? subscription;
    subscription = _receivePort.listen((message) {
      if (message['id'] == id) {
        completer.complete(message['result']);
        subscription?.cancel();
      }
    });

    _sendPort!.send({'id': id, 'data': jsonString});

    return await completer.future;
  }

  void dispose() {
    _isolate?.kill();
    _receivePort.close();
  }
}
```

### Results

```
Before Optimization:
- UI blocking time: 3000ms
- User experience: Frozen UI
- Frame drops: 180 frames

After Optimization:
- UI blocking time: 0ms
- User experience: Smooth loading indicator
- Frame drops: 0 frames

Improvements:
- 100% elimination of UI blocking
- Smooth 60fps during parsing
- Better user experience
```

## Pattern 4: Reducing Build Overhead

### Problem

Settings screen rebuilds all widgets when any single setting changes.

### Diagnosis

```dart
// DevTools Performance findings:
// - SettingsScreen.build: 45ms
// - Called on every setting toggle
// - All 20 setting widgets rebuild unnecessarily

// Original implementation
class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool notifications = true;
  bool soundEffects = true;
  // ... 17 more settings

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // All rebuild on any setState()
        SwitchListTile(
          title: Text('Dark Mode'),
          value: darkMode,
          onChanged: (value) => setState(() => darkMode = value),
        ),
        SwitchListTile(
          title: Text('Notifications'),
          value: notifications,
          onChanged: (value) => setState(() => notifications = value),
        ),
        SwitchListTile(
          title: Text('Sound Effects'),
          value: soundEffects,
          onChanged: (value) => setState(() => soundEffects = value),
        ),
        // ... 17 more settings
      ],
    );
  }
}
```

### Solution

```dart
// Option 1: Extract individual settings into separate widgets
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        DarkModeSetting(),
        NotificationsSetting(),
        SoundEffectsSetting(),
        // ... more settings
      ],
    );
  }
}

class DarkModeSetting extends StatefulWidget {
  const DarkModeSetting();

  @override
  State<DarkModeSetting> createState() => _DarkModeSettingState();
}

class _DarkModeSettingState extends State<DarkModeSetting> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: darkMode,
      onChanged: (value) => setState(() => darkMode = value),
    );
  }
}

// Option 2: Use state management for better control
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Only rebuilds when darkMode changes
        Selector<SettingsModel, bool>(
          selector: (_, settings) => settings.darkMode,
          builder: (context, darkMode, child) {
            return SwitchListTile(
              title: const Text('Dark Mode'),
              value: darkMode,
              onChanged: (value) {
                context.read<SettingsModel>().setDarkMode(value);
              },
            );
          },
        ),
        Selector<SettingsModel, bool>(
          selector: (_, settings) => settings.notifications,
          builder: (context, notifications, child) {
            return SwitchListTile(
              title: const Text('Notifications'),
              value: notifications,
              onChanged: (value) {
                context.read<SettingsModel>().setNotifications(value);
              },
            );
          },
        ),
        // ... more settings
      ],
    );
  }
}
```

### Results

```
Before Optimization:
- Build time per toggle: 45ms
- Widgets rebuilt per toggle: 20
- User-perceived lag: Noticeable

After Optimization:
- Build time per toggle: 3ms
- Widgets rebuilt per toggle: 1
- User-perceived lag: None

Improvements:
- 93% faster build time
- 95% fewer rebuilds
- Instant UI updates
```

## Pattern 5: Image Loading Optimization

### Problem

Gallery screen loads slowly and consumes 400MB of memory with 50 images.

### Diagnosis

```dart
// DevTools Memory findings:
// - Memory usage: 400MB
// - Image cache: 50 full-resolution images (8MB each)
// - All images loaded at once

// Original implementation
class GalleryScreen extends StatelessWidget {
  final List<String> imageUrls;

  const GalleryScreen(this.imageUrls);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          // Loads full 4000x3000 image even though displayed at 120x120
        );
      },
    );
  }
}
```

### Solution

```dart
class GalleryScreen extends StatelessWidget {
  final List<String> imageUrls;

  const GalleryScreen(this.imageUrls);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            // Resize during decoding
            memCacheWidth: 400,
            memCacheHeight: 400,
            // Placeholder during load
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
            ),
            // Error handling
            errorWidget: (context, url, error) => const Icon(Icons.error),
            // Fade in animation
            fadeInDuration: const Duration(milliseconds: 200),
          ),
        );
      },
      // Cache a few offscreen items
      cacheExtent: 200,
    );
  }
}

// Configure image cache size
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Limit image cache
    PaintingBinding.instance.imageCache
      ..maximumSize = 100 // Max 100 images
      ..maximumSizeBytes = 50 * 1024 * 1024; // 50 MB max

    return MaterialApp(home: HomeScreen());
  }
}
```

### Results

```
Before Optimization:
- Initial load time: 8 seconds
- Memory usage: 400MB
- Images loaded: 50 (full resolution)

After Optimization:
- Initial load time: 1 second
- Memory usage: 65MB
- Images loaded: 12 (visible + cache, resized)

Improvements:
- 87% faster load time
- 84% less memory
- 75% fewer network requests
```

## Pattern 6: Animation Performance

### Problem

Custom animation stutters during playback (45fps instead of 60fps).

### Diagnosis

```dart
// DevTools Performance findings:
// - Frame time: 22ms
// - Paint time: 18ms (excessive)
// - Opacity widget causing saveLayer

// Original implementation
class AnimatedCard extends StatefulWidget {
  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _controller.value * 0.1,
          child: Opacity(
            opacity: 0.5 + _controller.value * 0.5,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              child: CustomPaint(
                painter: ComplexPainter(), // Expensive
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Solution

```dart
class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // Provide child to avoid rebuilding static content
      child: Container(
        width: 200,
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        // Wrap expensive paint in RepaintBoundary
        child: RepaintBoundary(
          child: CustomPaint(
            painter: ComplexPainter(),
          ),
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          // Use FadeTransition instead of Opacity
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Results

```
Before Optimization:
- Frame time: 22ms (45fps)
- Paint time: 18ms
- saveLayer calls: 60/second

After Optimization:
- Frame time: 13ms (60fps+)
- Paint time: 6ms
- saveLayer calls: 0/second

Improvements:
- 41% faster frame time
- 67% faster paint time
- Smooth 60fps animation
```

## Pattern 7: Network Request Batching

### Problem

Home screen makes 15 separate API calls on load, taking 8 seconds total.

### Diagnosis

```dart
// DevTools Network findings:
// - 15 sequential requests
// - Total time: 8 seconds
// - Average request time: 500ms
// - Network waterfall shows serial loading

// Original implementation
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<Product> featuredProducts = [];
  List<Category> categories = [];
  List<Banner> banners = [];
  User? currentUser;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Serial requests - slow!
    featuredProducts = await api.getFeaturedProducts();
    categories = await api.getCategories();
    banners = await api.getBanners();
    currentUser = await api.getCurrentUser();
    // ... 11 more requests

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();

    return HomeContent(
      products: featuredProducts,
      categories: categories,
      banners: banners,
      user: currentUser,
    );
  }
}
```

### Solution

```dart
class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  late HomeData data;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Option 1: Parallel requests
    final results = await Future.wait([
      api.getFeaturedProducts(),
      api.getCategories(),
      api.getBanners(),
      api.getCurrentUser(),
      // ... more requests
    ]);

    setState(() {
      data = HomeData(
        featuredProducts: results[0],
        categories: results[1],
        banners: results[2],
        currentUser: results[3],
      );
      isLoading = false;
    });

    // Option 2: Single batched API call (better)
    // Backend combines all data
    final homeData = await api.getHomeData();

    setState(() {
      data = homeData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return HomeContent(data: data);
  }
}

// API implementation with batching
class ApiService {
  Future<HomeData> getHomeData() async {
    // Single request gets all home screen data
    final response = await http.get(Uri.parse('$baseUrl/home'));
    return HomeData.fromJson(jsonDecode(response.body));
  }
}
```

### Results

```
Before Optimization:
- Total load time: 8 seconds (serial)
- API requests: 15
- User wait time: 8 seconds

After Optimization (Parallel):
- Total load time: 1.2 seconds
- API requests: 15 (parallel)
- User wait time: 1.2 seconds

After Optimization (Batched):
- Total load time: 0.6 seconds
- API requests: 1
- User wait time: 0.6 seconds

Improvements:
- 92% faster load time (batched)
- 93% fewer requests
- Better perceived performance
```

## Common Pattern Summary

### Quick Reference

| Problem | Pattern | Key Techniques |
|---------|---------|----------------|
| Slow scrolling | List optimization | RepaintBoundary, const, caching |
| Memory leaks | Disposal | dispose(), cancel timers, remove listeners |
| UI freezing | Isolates | Isolate.run(), background parsing |
| Excessive rebuilds | Widget splitting | Localize setState, extract widgets |
| High memory (images) | Image optimization | Cache limits, resize, lazy load |
| Janky animations | Animation optimization | FadeTransition, RepaintBoundary |
| Slow API loads | Request batching | Parallel requests, batch endpoints |

### Optimization Workflow

1. **Profile first**: Use DevTools to identify actual bottleneck
2. **Measure baseline**: Record metrics before changes
3. **Apply pattern**: Implement appropriate optimization
4. **Verify improvement**: Measure again, confirm gains
5. **Monitor regression**: Add performance tests

These real-world optimization patterns demonstrate systematic approaches to common Flutter performance challenges. Each pattern is measurable, repeatable, and validated through profiling data. Apply these patterns when facing similar scenarios in your applications.
