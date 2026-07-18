# API Integration Patterns

Practical examples of integrating Serverpod with external APIs, handling third-party services, caching responses, and building API aggregation layers.

## Weather Service Integration

Build a weather service that aggregates data from external weather APIs and caches results.

### Weather Models

```yaml
# weather_server/lib/src/models/weather_data.spy.yaml
class: WeatherData
fields:
  city: String
  temperature: double
  condition: String
  humidity: int
  windSpeed: double
  timestamp: DateTime

  # Not stored in database, just for API responses
```

```yaml
# weather_server/lib/src/models/weather_cache.spy.yaml
class: WeatherCache
table: weather_cache
fields:
  city: String, !dbindex
  data: String  # JSON stored as string
  expiresAt: DateTime, !dbindex
  createdAt: DateTime, defaultModel=DateTime.now()
```

### Weather API Client

```dart
// weather_server/lib/src/services/weather_api_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherApiClient {
  final String apiKey;
  final String baseUrl;

  WeatherApiClient({
    required this.apiKey,
    this.baseUrl = 'https://api.openweathermap.org/data/2.5',
  });

  Future<WeatherData> fetchWeather(String city) async {
    final url = Uri.parse('$baseUrl/weather').replace(
      queryParameters: {
        'q': city,
        'appid': apiKey,
        'units': 'metric',
      },
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Failed to fetch weather: ${response.statusCode}',
      );
    }

    final data = json.decode(response.body);

    return WeatherData(
      city: city,
      temperature: data['main']['temp'].toDouble(),
      condition: data['weather'][0]['main'],
      humidity: data['main']['humidity'],
      windSpeed: data['wind']['speed'].toDouble(),
      timestamp: DateTime.now(),
    );
  }

  Future<List<WeatherData>> fetchForecast(
    String city,
    {int days = 5}
  ) async {
    final url = Uri.parse('$baseUrl/forecast').replace(
      queryParameters: {
        'q': city,
        'appid': apiKey,
        'units': 'metric',
        'cnt': (days * 8).toString(), // 3-hour intervals
      },
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Failed to fetch forecast: ${response.statusCode}',
      );
    }

    final data = json.decode(response.body);
    final list = data['list'] as List;

    return list.map((item) {
      return WeatherData(
        city: city,
        temperature: item['main']['temp'].toDouble(),
        condition: item['weather'][0]['main'],
        humidity: item['main']['humidity'],
        windSpeed: item['wind']['speed'].toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          item['dt'] * 1000,
        ),
      );
    }).toList();
  }
}

class WeatherApiException implements Exception {
  final String message;
  WeatherApiException(this.message);
  @override
  String toString() => message;
}
```

### Weather Endpoint with Caching

```dart
// weather_server/lib/src/endpoints/weather_endpoint.dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/weather_api_client.dart';
import 'dart:convert';

class WeatherEndpoint extends Endpoint {
  late final WeatherApiClient _weatherApi;

  @override
  Future<void> initialize(Server server, SerializationManager serializationManager) async {
    await super.initialize(server, serializationManager);

    // Initialize weather API client
    _weatherApi = WeatherApiClient(
      apiKey: server.passwords['weatherApiKey']!,
    );
  }

  /// Get current weather with caching
  Future<WeatherData> getCurrentWeather(
    Session session,
    String city,
  ) async {
    // Normalize city name
    city = city.trim().toLowerCase();

    // Try cache first
    var cached = await _getCachedWeather(session, city);
    if (cached != null) {
      session.log('Weather cache hit for: $city');
      return cached;
    }

    // Fetch from API
    session.log('Weather cache miss for: $city, fetching from API');

    try {
      var weather = await _weatherApi.fetchWeather(city);

      // Cache result for 30 minutes
      await _cacheWeather(session, city, weather, Duration(minutes: 30));

      return weather;
    } on WeatherApiException catch (e) {
      throw NotFoundException('City not found: $city');
    }
  }

  /// Get forecast
  Future<List<WeatherData>> getForecast(
    Session session,
    String city,
    int days,
  ) async {
    city = city.trim().toLowerCase();

    // Check cache (use different cache key for forecasts)
    var cacheKey = '$city:forecast:$days';
    var cachedJson = await session.caches.local.get<String>(cacheKey);

    if (cachedJson != null) {
      session.log('Forecast cache hit for: $cacheKey');

      var jsonList = json.decode(cachedJson) as List;
      return jsonList
          .map((item) => WeatherData.fromJson(item))
          .toList();
    }

    // Fetch from API
    session.log('Forecast cache miss, fetching from API');

    try {
      var forecast = await _weatherApi.fetchForecast(city, days: days);

      // Cache for 1 hour
      await session.caches.local.put(
        cacheKey,
        json.encode(forecast.map((w) => w.toJson()).toList()),
        lifetime: Duration(hours: 1),
      );

      return forecast;
    } on WeatherApiException {
      throw NotFoundException('City not found: $city');
    }
  }

  /// Search cities
  Future<List<String>> searchCities(Session session, String query) async {
    // In real app, would query a cities database or API
    // Simplified for example
    var commonCities = [
      'London',
      'Paris',
      'New York',
      'Tokyo',
      'Sydney',
      'Berlin',
      'Madrid',
      'Rome',
    ];

    return commonCities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Cache helpers
  Future<WeatherData?> _getCachedWeather(
    Session session,
    String city,
  ) async {
    var cached = await WeatherCache.db.findFirstRow(
      session,
      where: (t) =>
          t.city.equals(city) &
          t.expiresAt > DateTime.now(),
    );

    if (cached == null) return null;

    var jsonData = json.decode(cached.data);
    return WeatherData.fromJson(jsonData);
  }

  Future<void> _cacheWeather(
    Session session,
    String city,
    WeatherData weather,
    Duration lifetime,
  ) async {
    // Delete old cache entries for this city
    await WeatherCache.db.deleteWhere(
      session,
      where: (t) => t.city.equals(city),
    );

    // Insert new cache entry
    await WeatherCache.db.insertRow(
      session,
      WeatherCache(
        city: city,
        data: json.encode(weather.toJson()),
        expiresAt: DateTime.now().add(lifetime),
      ),
    );
  }
}
```

## Payment Processing Integration

Integrate with Stripe for payment processing.

### Payment Models

```yaml
# payments_server/lib/src/models/payment.spy.yaml
class: Payment
table: payment
fields:
  userId: int, !dbindex
  amount: double
  currency: String, default='usd'
  status: String  # 'pending', 'succeeded', 'failed'
  stripePaymentIntentId: String?, !dbindex
  description: String?
  createdAt: DateTime, defaultModel=DateTime.now()
  updatedAt: DateTime, defaultModel=DateTime.now()
```

### Stripe Service

```dart
// payments_server/lib/src/services/stripe_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  final String secretKey;
  final String apiVersion;

  StripeService({
    required this.secretKey,
    this.apiVersion = '2023-10-16',
  });

  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,  // Amount in cents
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Stripe-Version': apiVersion,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount.toString(),
        'currency': currency,
        if (customerId != null) 'customer': customerId,
        if (metadata != null)
          ...metadata.map((k, v) => MapEntry('metadata[$k]', v.toString())),
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw StripeException(error['error']['message']);
    }

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> retrievePaymentIntent(
    String paymentIntentId,
  ) async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Stripe-Version': apiVersion,
      },
    );

    if (response.statusCode != 200) {
      throw StripeException('Failed to retrieve payment intent');
    }

    return json.decode(response.body);
  }

  Future<void> cancelPaymentIntent(String paymentIntentId) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/cancel'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Stripe-Version': apiVersion,
      },
    );

    if (response.statusCode != 200) {
      throw StripeException('Failed to cancel payment intent');
    }
  }
}

class StripeException implements Exception {
  final String message;
  StripeException(this.message);
  @override
  String toString() => message;
}
```

### Payment Endpoint

```dart
// payments_server/lib/src/endpoints/payment_endpoint.dart
class PaymentEndpoint extends Endpoint {
  late final StripeService _stripe;

  @override
  Future<void> initialize(Server server, SerializationManager serializationManager) async {
    await super.initialize(server, serializationManager);

    _stripe = StripeService(
      secretKey: server.passwords['stripeSecretKey']!,
    );
  }

  /// Create payment
  Future<PaymentIntent> createPayment(
    Session session,
    double amount,
    String currency,
    String description,
  ) async {
    // Authenticate
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    var userId = session.auth!.userId!;

    // Validate amount
    if (amount <= 0) {
      throw ValidationException('Amount must be positive');
    }

    if (amount > 10000) {
      throw ValidationException('Amount too large');
    }

    // Create payment record
    var payment = Payment(
      userId: userId,
      amount: amount,
      currency: currency,
      status: 'pending',
      description: description,
    );

    payment = await Payment.db.insertRow(session, payment);

    try {
      // Create Stripe payment intent
      var intent = await _stripe.createPaymentIntent(
        amount: (amount * 100).toInt(), // Convert to cents
        currency: currency,
        metadata: {
          'payment_id': payment.id.toString(),
          'user_id': userId.toString(),
        },
      );

      // Update payment with Stripe ID
      payment = payment.copyWith(
        stripePaymentIntentId: intent['id'],
      );
      payment = await Payment.db.updateRow(session, payment);

      return PaymentIntent(
        paymentId: payment.id!,
        clientSecret: intent['client_secret'],
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      // Update payment status to failed
      payment = payment.copyWith(status: 'failed');
      await Payment.db.updateRow(session, payment);

      throw PaymentException('Failed to create payment: $e');
    }
  }

  /// Handle Stripe webhook
  Future<void> handleWebhook(
    Session session,
    String payload,
    String signature,
  ) async {
    // Verify webhook signature
    // (Simplified - use stripe package in production)

    var event = json.decode(payload);
    var eventType = event['type'];

    if (eventType == 'payment_intent.succeeded') {
      var paymentIntentId = event['data']['object']['id'];

      // Find payment by Stripe ID
      var payment = await Payment.db.findFirstRow(
        session,
        where: (t) => t.stripePaymentIntentId.equals(paymentIntentId),
      );

      if (payment != null) {
        // Update status
        payment = payment.copyWith(
          status: 'succeeded',
          updatedAt: DateTime.now(),
        );
        await Payment.db.updateRow(session, payment);

        // Trigger fulfillment
        await _fulfillPayment(session, payment);
      }
    } else if (eventType == 'payment_intent.payment_failed') {
      var paymentIntentId = event['data']['object']['id'];

      var payment = await Payment.db.findFirstRow(
        session,
        where: (t) => t.stripePaymentIntentId.equals(paymentIntentId),
      );

      if (payment != null) {
        payment = payment.copyWith(
          status: 'failed',
          updatedAt: DateTime.now(),
        );
        await Payment.db.updateRow(session, payment);
      }
    }
  }

  /// Get user's payment history
  Future<List<Payment>> getPaymentHistory(Session session) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Must be signed in');
    }

    return await Payment.db.find(
      session,
      where: (t) => t.userId.equals(session.auth!.userId!),
      orderBy: (t) => -t.createdAt,
      limit: 50,
    );
  }

  Future<void> _fulfillPayment(Session session, Payment payment) async {
    // Implement your fulfillment logic
    // E.g., grant subscription, deliver digital goods, etc.
    session.log('Fulfilling payment: ${payment.id}');
  }
}
```

## Multi-API Aggregation

Aggregate data from multiple APIs into a unified response.

### News Aggregation Service

```dart
// news_server/lib/src/services/news_aggregator.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsAggregator {
  final Map<String, String> apiKeys;

  NewsAggregator({required this.apiKeys});

  Future<List<NewsArticle>> getTopHeadlines({
    String? category,
    int limit = 20,
  }) async {
    // Fetch from multiple sources in parallel
    var results = await Future.wait([
      _fetchFromNewsApi(category: category, limit: limit ~/ 2),
      _fetchFromGuardianApi(category: category, limit: limit ~/ 2),
    ]);

    // Combine and sort by publish date
    var allArticles = [...results[0], ...results[1]];
    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return allArticles.take(limit).toList();
  }

  Future<List<NewsArticle>> _fetchFromNewsApi({
    String? category,
    required int limit,
  }) async {
    final url = Uri.parse('https://newsapi.org/v2/top-headlines').replace(
      queryParameters: {
        'apiKey': apiKeys['newsapi']!,
        'pageSize': limit.toString(),
        if (category != null) 'category': category,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final articles = data['articles'] as List;

      return articles.map((article) {
        return NewsArticle(
          title: article['title'],
          description: article['description'] ?? '',
          url: article['url'],
          imageUrl: article['urlToImage'],
          source: article['source']['name'],
          publishedAt: DateTime.parse(article['publishedAt']),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<NewsArticle>> _fetchFromGuardianApi({
    String? category,
    required int limit,
  }) async {
    final url = Uri.parse('https://content.guardianapis.com/search').replace(
      queryParameters: {
        'api-key': apiKeys['guardian']!,
        'page-size': limit.toString(),
        'show-fields': 'thumbnail,trailText',
        if (category != null) 'section': category,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final results = data['response']['results'] as List;

      return results.map((result) {
        return NewsArticle(
          title: result['webTitle'],
          description: result['fields']?['trailText'] ?? '',
          url: result['webUrl'],
          imageUrl: result['fields']?['thumbnail'],
          source: 'The Guardian',
          publishedAt: DateTime.parse(result['webPublicationDate']),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
```

### News Endpoint

```dart
// news_server/lib/src/endpoints/news_endpoint.dart
class NewsEndpoint extends Endpoint {
  late final NewsAggregator _aggregator;

  @override
  Future<void> initialize(Server server, SerializationManager serializationManager) async {
    await super.initialize(server, serializationManager);

    _aggregator = NewsAggregator(
      apiKeys: {
        'newsapi': server.passwords['newsApiKey']!,
        'guardian': server.passwords['guardianApiKey']!,
      },
    );
  }

  Future<List<NewsArticle>> getHeadlines(
    Session session,
    {String? category}
  ) async {
    // Check cache
    var cacheKey = 'headlines:${category ?? 'all'}';
    var cached = await session.caches.local.get<List<NewsArticle>>(cacheKey);

    if (cached != null) {
      session.log('News cache hit');
      return cached;
    }

    // Fetch from aggregator
    session.log('News cache miss, aggregating from APIs');

    var articles = await _aggregator.getTopHeadlines(
      category: category,
      limit: 20,
    );

    // Cache for 15 minutes
    await session.caches.local.put(
      cacheKey,
      articles,
      lifetime: Duration(minutes: 15),
    );

    return articles;
  }
}
```

## Rate Limiting External APIs

Implement rate limiting to respect API quotas.

```dart
// api_server/lib/src/services/rate_limiter.dart
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, List<DateTime>> _requests = {};

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  Future<void> checkLimit(String key) async {
    final now = DateTime.now();
    final cutoff = now.subtract(window);

    // Clean old requests
    _requests[key]?.removeWhere((time) => time.isBefore(cutoff));

    // Check limit
    final count = _requests[key]?.length ?? 0;
    if (count >= maxRequests) {
      final oldestRequest = _requests[key]!.first;
      final resetTime = oldestRequest.add(window);
      final waitDuration = resetTime.difference(now);

      throw RateLimitException(
        'Rate limit exceeded. Retry after ${waitDuration.inSeconds}s',
      );
    }

    // Record request
    _requests[key] = [...?_requests[key], now];
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => message;
}
```

Usage in endpoint:

```dart
class ExternalApiEndpoint extends Endpoint {
  final _rateLimiter = RateLimiter(
    maxRequests: 100,
    window: Duration(hours: 1),
  );

  Future<ExternalData> fetchData(Session session, String query) async {
    // Check rate limit
    await _rateLimiter.checkLimit('external-api');

    // Make API call
    var data = await _externalApiClient.fetch(query);

    return data;
  }
}
```

These examples demonstrate production-ready patterns for integrating Serverpod with external APIs, implementing caching strategies, aggregating multiple data sources, and handling payment processing.
