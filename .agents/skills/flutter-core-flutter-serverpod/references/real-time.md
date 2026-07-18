# Real-Time Communication with Streams

Comprehensive guide to implementing real-time features in Serverpod using streaming methods, WebSocket connections, bidirectional communication, and real-time data synchronization.

## Overview

Serverpod provides first-class support for real-time communication through Dart's native `Stream` API, automatically managing WebSocket connections and handling network failures.

### Real-Time Capabilities

**Streaming Methods**: Return `Stream` from endpoint methods or accept `Stream` parameters, with Serverpod handling the WebSocket connection automatically.

**Bidirectional Communication**: Push data from server to client, send data from client to server, or both simultaneously over a single connection.

**Automatic Management**: Connection lifecycle, reconnection logic, and stream multiplexing are handled transparently.

**Type Safety**: Full type safety for streamed data using generated serializable models.

## Streaming Methods

The modern approach to real-time communication in Serverpod using streaming endpoint methods.

### Server-to-Client Streaming

Push data from server to client by returning a `Stream`:

```dart
// lib/src/endpoints/notification_endpoint.dart
import 'package:serverpod/serverpod.dart';

class NotificationEndpoint extends Endpoint {
  /// Stream notifications for a specific user
  Stream<Notification> watchNotifications(
    Session session,
    int userId,
  ) async* {
    // Authenticate user
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    // Subscribe to notification stream
    await for (var notification in _notificationStreamForUser(userId)) {
      yield notification;
    }
  }

  /// Stream live price updates for a stock
  Stream<StockPrice> watchStock(Session session, String symbol) async* {
    // Emit current price immediately
    var currentPrice = await _getCurrentPrice(symbol);
    yield currentPrice;

    // Then stream updates
    await for (var price in _priceUpdateStream(symbol)) {
      yield price;
    }
  }

  /// Countdown timer stream
  Stream<int> countdown(Session session, int seconds) async* {
    for (var i = seconds; i >= 0; i--) {
      await Future.delayed(Duration(seconds: 1));
      yield i;
    }
  }
}
```

**Key Points**:
- Use `async*` generator functions
- `yield` emits values to the stream
- Stream continues until function completes or client disconnects
- Each client connection creates a new `Session`

### Client-Side Consumption

Subscribe to server streams from Flutter:

```dart
import 'package:my_app_client/my_app_client.dart';

class NotificationWidget extends StatefulWidget {
  final Client client;

  const NotificationWidget({required this.client});

  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  StreamSubscription<Notification>? _subscription;
  List<Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // Subscribe to notification stream
    _subscription = widget.client.notification
        .watchNotifications(userId: 123)
        .listen(
      (notification) {
        setState(() {
          _notifications.insert(0, notification);
        });
      },
      onError: (error) {
        print('Stream error: $error');
      },
      onDone: () {
        print('Stream completed');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        var notification = _notifications[index];
        return ListTile(
          title: Text(notification.title),
          subtitle: Text(notification.message),
        );
      },
    );
  }
}
```

**StreamBuilder Alternative**:

```dart
class StockPriceWidget extends StatelessWidget {
  final Client client;
  final String symbol;

  const StockPriceWidget({
    required this.client,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StockPrice>(
      stream: client.stock.watchStock(symbol),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        var price = snapshot.data!;
        return Column(
          children: [
            Text(symbol, style: Theme.of(context).textTheme.headlineSmall),
            Text('\$${price.value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium),
            Text(
              '${price.change >= 0 ? '+' : ''}${price.change.toStringAsFixed(2)}',
              style: TextStyle(
                color: price.change >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Client-to-Server Streaming

Send stream of data from client to server:

```dart
// Server endpoint accepting stream
class DataEndpoint extends Endpoint {
  Future<UploadResult> uploadDataStream(
    Session session,
    Stream<DataChunk> dataStream,
  ) async {
    var totalBytes = 0;
    var chunkCount = 0;

    await for (var chunk in dataStream) {
      // Process each chunk
      await _processChunk(session, chunk);

      totalBytes += chunk.data.length;
      chunkCount++;

      // Log progress
      if (chunkCount % 100 == 0) {
        session.log('Processed $chunkCount chunks, $totalBytes bytes');
      }
    }

    return UploadResult(
      bytesReceived: totalBytes,
      chunksReceived: chunkCount,
    );
  }

  Future<Statistics> aggregateMetrics(
    Session session,
    Stream<Metric> metricStream,
  ) async {
    var metrics = <Metric>[];

    await for (var metric in metricStream) {
      metrics.add(metric);
    }

    return _calculateStatistics(metrics);
  }
}
```

**Client Implementation**:

```dart
// Generate stream of data chunks
Stream<DataChunk> generateDataStream() async* {
  for (var i = 0; i < 1000; i++) {
    // Generate or read chunk
    var data = await _generateChunk(i);

    yield DataChunk(
      sequence: i,
      data: data,
      timestamp: DateTime.now(),
    );

    // Optional: delay between chunks
    await Future.delayed(Duration(milliseconds: 10));
  }
}

// Upload to server
Future<void> uploadData() async {
  try {
    var result = await client.data.uploadDataStream(generateDataStream());

    print('Upload complete: ${result.bytesReceived} bytes, '
        '${result.chunksReceived} chunks');
  } catch (e) {
    print('Upload failed: $e');
  }
}
```

### Bidirectional Streaming

Both server and client stream data simultaneously:

```dart
// Server: Chat room with bidirectional streaming
class ChatEndpoint extends Endpoint {
  Stream<ChatMessage> chatRoom(
    Session session,
    String roomId,
    Stream<ChatMessage> outgoingMessages,
  ) async* {
    // Authenticate
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    var userId = session.auth!.userId!;

    // Subscribe to room's message broadcast
    var broadcastController = StreamController<ChatMessage>();
    var broadcastSubscription = _roomBroadcasts[roomId]?.listen(
      (message) => broadcastController.add(message),
    );

    // Process outgoing messages from this client
    outgoingMessages.listen(
      (message) {
        // Validate and broadcast message
        message.userId = userId;
        message.timestamp = DateTime.now();
        _broadcastToRoom(roomId, message);
      },
      onDone: () {
        session.log('User $userId left room $roomId');
      },
    );

    // Yield incoming messages to this client
    await for (var message in broadcastController.stream) {
      yield message;
    }

    // Cleanup
    await broadcastSubscription?.cancel();
    await broadcastController.close();
  }
}
```

**Client Implementation**:

```dart
class ChatRoomWidget extends StatefulWidget {
  final Client client;
  final String roomId;

  const ChatRoomWidget({
    required this.client,
    required this.roomId,
  });

  @override
  _ChatRoomWidgetState createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  final _messageController = TextEditingController();
  final _outgoingController = StreamController<ChatMessage>();
  StreamSubscription<ChatMessage>? _subscription;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  void _joinRoom() {
    _subscription = widget.client.chat
        .chatRoom(widget.roomId, _outgoingController.stream)
        .listen(
      (message) {
        setState(() {
          _messages.add(message);
        });
      },
      onError: (error) {
        print('Chat error: $error');
      },
    );
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    var message = ChatMessage(
      text: _messageController.text,
      timestamp: DateTime.now(),
    );

    _outgoingController.add(message);
    _messageController.clear();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _outgoingController.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              var message = _messages[index];
              return ListTile(
                title: Text(message.text),
                subtitle: Text(message.timestamp.toString()),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(hintText: 'Type message...'),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ],
    );
  }
}
```

## Stream Lifecycle

Understanding how Serverpod manages streaming connections.

### Session Creation

Each streaming method call creates a new `Session`:

```dart
Stream<Data> streamData(Session session, int userId) async* {
  // New session created for this stream
  session.log('Stream started for user $userId');

  try {
    await for (var data in dataSource) {
      yield data;
    }
  } finally {
    // Session closes when stream ends
    session.log('Stream ended for user $userId');
  }
}
```

### Connection Management

Serverpod handles WebSocket lifecycle:

- **Automatic Connection**: WebSocket established on first stream subscription
- **Multiplexing**: Multiple streams share a single WebSocket connection
- **Reconnection**: Automatic reconnection on network failures
- **Cleanup**: Session and resources cleaned up when stream closes

### Stream Termination

Streams close under these conditions:

**Normal Completion**:
```dart
Stream<int> finiteStream(Session session) async* {
  for (var i = 0; i < 10; i++) {
    yield i;
  }
  // Stream completes normally
}
```

**Client Cancellation**:
```dart
// Client cancels subscription
await subscription.cancel();
// Server stream is terminated
```

**Error Thrown**:
```dart
Stream<Data> errorStream(Session session) async* {
  yield data1;

  if (errorCondition) {
    // Closes stream with error
    throw ServerException('Something went wrong');
  }
}
```

**Connection Loss**:
- WebSocket disconnection terminates all active streams
- Client receives error on stream subscription
- Server sessions are cleaned up

### Authentication Lifecycle

Authentication is checked when establishing the stream:

```dart
Stream<SecureData> secureStream(Session session) async* {
  // Check authentication at stream start
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  // Stream data while authenticated
  await for (var data in dataSource) {
    // If authentication is revoked, stream closes with exception
    yield data;
  }
}
```

If authentication is revoked during streaming, the stream closes immediately with an exception.

## Broadcasting Patterns

Common patterns for broadcasting data to multiple clients.

### In-Memory Broadcast

Use `StreamController` for simple broadcasting:

```dart
class BroadcastService {
  // Map of room ID to broadcast controllers
  static final _roomBroadcasts = <String, StreamController<Message>>{};

  static StreamController<Message> _getOrCreateBroadcast(String roomId) {
    return _roomBroadcasts.putIfAbsent(
      roomId,
      () => StreamController<Message>.broadcast(),
    );
  }

  static void broadcast(String roomId, Message message) {
    _getOrCreateBroadcast(roomId).add(message);
  }

  static Stream<Message> subscribe(String roomId) {
    return _getOrCreateBroadcast(roomId).stream;
  }

  static void cleanup(String roomId) {
    _roomBroadcasts[roomId]?.close();
    _roomBroadcasts.remove(roomId);
  }
}

// Endpoint using broadcast
class MessageEndpoint extends Endpoint {
  Stream<Message> watchRoom(Session session, String roomId) async* {
    await for (var message in BroadcastService.subscribe(roomId)) {
      yield message;
    }
  }

  Future<void> sendMessage(Session session, String roomId, Message message) async {
    // Save to database
    await Message.db.insertRow(session, message);

    // Broadcast to all subscribers
    BroadcastService.broadcast(roomId, message);
  }
}
```

### Redis Pub/Sub

For multi-server deployments, use Redis:

```dart
import 'package:redis/redis.dart';

class RedisBroadcastService {
  final RedisConnection _connection;
  late Command _command;
  late PubSub _pubsub;

  RedisBroadcastService(String host, int port) : _connection = RedisConnection() {
    _connection.connect(host, port).then((command) {
      _command = command;
    });
  }

  Future<void> broadcast(String channel, Message message) async {
    await _command.send_object(['PUBLISH', channel, message.toJson()]);
  }

  Stream<Message> subscribe(String channel) async* {
    _pubsub = PubSub(_command);
    var subscription = _pubsub.subscribe([channel]);

    await for (var message in subscription.stream) {
      if (message is List && message.length >= 3) {
        yield Message.fromJson(message[2]);
      }
    }
  }
}

// Endpoint using Redis
class DistributedMessageEndpoint extends Endpoint {
  final RedisBroadcastService _broadcast;

  DistributedMessageEndpoint(this._broadcast);

  Stream<Message> watchRoom(Session session, String roomId) async* {
    await for (var message in _broadcast.subscribe('room:$roomId')) {
      yield message;
    }
  }

  Future<void> sendMessage(Session session, String roomId, Message message) async {
    await Message.db.insertRow(session, message);
    await _broadcast.broadcast('room:$roomId', message);
  }
}
```

## Error Handling

Properly handle errors in streaming methods.

### Throwing Exceptions

Exceptions close the stream and notify the client:

```dart
Stream<Data> validatedStream(Session session, int userId) async* {
  // Validate access
  if (!await hasAccess(session, userId)) {
    throw ForbiddenException('Access denied');
  }

  try {
    await for (var data in dataSource) {
      // Validate each item
      if (!data.isValid) {
        throw ValidationException('Invalid data encountered');
      }

      yield data;
    }
  } catch (e) {
    session.log('Stream error', level: LogLevel.error, exception: e);
    rethrow;
  }
}
```

**Client Handling**:

```dart
_subscription = client.data.validatedStream(userId).listen(
  (data) {
    // Handle data
  },
  onError: (error) {
    if (error is ForbiddenException) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      showError('Stream error: $error');
    }
  },
);
```

### Graceful Error Recovery

Continue streaming despite errors:

```dart
Stream<Result> resilientStream(Session session) async* {
  await for (var item in dataSource) {
    try {
      var result = await processItem(item);
      yield result;
    } catch (e) {
      // Log error but continue stream
      session.log('Item processing failed', exception: e);

      // Optionally yield error result
      yield Result.error(e.toString());
    }
  }
}
```

## Performance Optimization

Strategies for efficient real-time communication.

### Throttling

Limit update frequency:

```dart
Stream<Location> locationStream(Session session, int userId) async* {
  var lastEmit = DateTime.now();
  const minInterval = Duration(seconds: 1);

  await for (var location in _locationUpdates(userId)) {
    var now = DateTime.now();

    if (now.difference(lastEmit) >= minInterval) {
      yield location;
      lastEmit = now;
    }
  }
}
```

### Debouncing

Wait for activity to settle:

```dart
Stream<SearchResults> searchStream(
  Session session,
  Stream<String> queryStream,
) async* {
  var lastQuery = '';
  var debounceTimer = Timer(Duration.zero, () {});

  await for (var query in queryStream) {
    debounceTimer.cancel();

    debounceTimer = Timer(Duration(milliseconds: 300), () async {
      if (query != lastQuery) {
        var results = await _search(query);
        yield results;
        lastQuery = query;
      }
    });
  }
}
```

### Batching

Group updates for efficiency:

```dart
Stream<List<Notification>> batchedNotifications(
  Session session,
  int userId,
) async* {
  var buffer = <Notification>[];
  var timer = Timer.periodic(Duration(seconds: 5), (_) {});

  await for (var notification in _notificationSource(userId)) {
    buffer.add(notification);

    // Emit batch when full or on timer
    if (buffer.length >= 10) {
      yield List.from(buffer);
      buffer.clear();
      timer.cancel();
      timer = Timer.periodic(Duration(seconds: 5), (_) {});
    }
  }

  // Emit remaining
  if (buffer.isNotEmpty) {
    yield buffer;
  }

  timer.cancel();
}
```

## Real-World Examples

### Live Dashboard

```dart
// Server: Stream dashboard metrics
Stream<DashboardMetrics> dashboardStream(Session session) async* {
  while (true) {
    var metrics = await _calculateMetrics(session);
    yield metrics;

    await Future.delayed(Duration(seconds: 5));
  }
}

// Client: Display live dashboard
class DashboardWidget extends StatelessWidget {
  final Client client;

  const DashboardWidget({required this.client});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DashboardMetrics>(
      stream: client.dashboard.dashboardStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        var metrics = snapshot.data!;
        return Column(
          children: [
            MetricCard(
              title: 'Active Users',
              value: metrics.activeUsers.toString(),
            ),
            MetricCard(
              title: 'Revenue',
              value: '\$${metrics.revenue.toStringAsFixed(2)}',
            ),
            MetricCard(
              title: 'Requests/sec',
              value: metrics.requestsPerSecond.toStringAsFixed(1),
            ),
          ],
        );
      },
    );
  }
}
```

### Multiplayer Game State

```dart
// Server: Game room stream
Stream<GameState> gameRoom(
  Session session,
  String roomId,
  Stream<PlayerAction> actionStream,
) async* {
  var game = await GameRoom.load(session, roomId);

  // Process player actions
  actionStream.listen((action) {
    game.processAction(action);
    _broadcastGameState(roomId, game.state);
  });

  // Stream game state updates
  await for (var state in _gameStateStream(roomId)) {
    yield state;
  }
}

// Client: Game UI
class GameWidget extends StatefulWidget {
  final Client client;
  final String roomId;

  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  final _actionController = StreamController<PlayerAction>();
  GameState? _currentState;

  @override
  void initState() {
    super.initState();

    widget.client.game.gameRoom(widget.roomId, _actionController.stream)
        .listen((state) {
      setState(() {
        _currentState = state;
      });
    });
  }

  void _performAction(PlayerAction action) {
    _actionController.add(action);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == null) {
      return CircularProgressIndicator();
    }

    return GameBoard(
      state: _currentState!,
      onAction: _performAction,
    );
  }
}
```

Serverpod's streaming capabilities enable rich real-time features with minimal boilerplate, making it ideal for chat applications, live dashboards, multiplayer games, and collaborative tools.
