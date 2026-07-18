# Complex State Management Examples

This guide demonstrates implementing a shopping cart with async operations using different state management approaches. This showcases how each solution handles realistic complexity including async state, error handling, and multiple data operations.

## Table of Contents

1. [Shopping Cart Spec](#shopping-cart-spec)
2. [Data Models](#data-models)
3. [Provider Implementation](#provider-implementation)
4. [Riverpod Implementation](#riverpod-implementation)
5. [BLoC Implementation](#bloc-implementation)
6. [Comparison](#comparison)

## Shopping Cart Spec

Our shopping cart app has the following features:
- Load products from an API (async)
- Display products in a list
- Add products to cart
- Remove products from cart
- Update quantity in cart
- Calculate total price
- Handle loading and error states
- Persist cart (simulate async save)

This demonstrates:
- Async data loading
- Multiple state objects (products + cart)
- Computed values (total)
- Error handling
- Optimistic updates

## Data Models

```dart
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.price * quantity;
}

// Mock API
class ProductApi {
  static Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(seconds: 1));

    // Simulate occasional error
    if (DateTime.now().second % 10 == 0) {
      throw Exception('Network error');
    }

    return [
      const Product(
        id: '1',
        name: 'Laptop',
        price: 999.99,
        imageUrl: 'https://picsum.photos/200?random=1',
      ),
      const Product(
        id: '2',
        name: 'Mouse',
        price: 29.99,
        imageUrl: 'https://picsum.photos/200?random=2',
      ),
      const Product(
        id: '3',
        name: 'Keyboard',
        price: 79.99,
        imageUrl: 'https://picsum.photos/200?random=3',
      ),
      const Product(
        id: '4',
        name: 'Monitor',
        price: 299.99,
        imageUrl: 'https://picsum.photos/200?random=4',
      ),
    ];
  }

  static Future<void> saveCart(List<CartItem> items) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate save to backend
  }
}
```

## Provider Implementation

Using Provider with ChangeNotifier for complex async state.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class ProductRepository extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await ProductApi.fetchProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ShoppingCart extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isSaving = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isSaving => _isSaving;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

  void addItem(Product product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }

    notifyListeners();
    _saveCart();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
      _saveCart();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  Future<void> _saveCart() async {
    _isSaving = true;
    notifyListeners();

    try {
      await ProductApi.saveCart(_items);
    } catch (e) {
      // Log error but don't block UI
      debugPrint('Failed to save cart: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductRepository()..loadProducts(),
        ),
        ChangeNotifierProvider(create: (_) => ShoppingCart()),
      ],
      child: MaterialApp(
        title: 'Shopping Cart - Provider',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const ShopScreen(),
      ),
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                Positioned(
                  right: 0,
                  child: Consumer<ShoppingCart>(
                    builder: (context, cart, _) {
                      if (cart.itemCount == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductRepository>(
        builder: (context, repository, _) {
          if (repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (repository.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${repository.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: repository.loadProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (repository.products.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return ListView.builder(
            itemCount: repository.products.length,
            itemBuilder: (context, index) {
              final product = repository.products[index];
              return ProductTile(product: product);
            },
          );
        },
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final Product product;

  const ProductTile({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(product.name),
      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: const Icon(Icons.add_shopping_cart),
        onPressed: () {
          context.read<ShoppingCart>().addItem(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<ShoppingCart>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: cart.clear,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingCart>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemTile(item: item);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Checkout logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checkout not implemented'),
                          ),
                        );
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        item.product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(item.product.name),
      subtitle: Text(
        '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              context.read<ShoppingCart>().updateQuantity(
                    item.product.id,
                    item.quantity - 1,
                  );
            },
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<ShoppingCart>().updateQuantity(
                    item.product.id,
                    item.quantity + 1,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              context.read<ShoppingCart>().removeItem(item.product.id);
            },
          ),
        ],
      ),
    );
  }
}
```

## Riverpod Implementation

Using Riverpod with code generation for type-safe async state.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// Products provider
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    return await ProductApi.fetchProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ProductApi.fetchProducts());
  }
}

// Shopping cart provider
@riverpod
class ShoppingCart extends _$ShoppingCart {
  @override
  List<CartItem> build() => [];

  void addItem(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }

    _saveCart();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _saveCart();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];

    _saveCart();
  }

  void clear() {
    state = [];
    _saveCart();
  }

  Future<void> _saveCart() async {
    try {
      await ProductApi.saveCart(state);
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }
}

// Computed providers
@riverpod
int cartItemCount(CartItemCountRef ref) {
  final items = ref.watch(shoppingCartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
}

@riverpod
double cartTotal(CartTotalRef ref) {
  final items = ref.watch(shoppingCartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Cart - Riverpod',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ShopScreen(),
    );
  }
}

class ShopScreen extends ConsumerWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final itemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (itemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(productListProvider.notifier).refresh();
            },
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductTile(product: products[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(productListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductTile extends ConsumerWidget {
  final Product product;

  const ProductTile({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Image.network(
        product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(product.name),
      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: const Icon(Icons.add_shopping_cart),
        onPressed: () {
          ref.read(shoppingCartProvider.notifier).addItem(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingCartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(shoppingCartProvider.notifier).clear();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(item: items[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checkout not implemented'),
                            ),
                          );
                        },
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class CartItemTile extends ConsumerWidget {
  final CartItem item;

  const CartItemTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Image.network(
        item.product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(item.product.name),
      subtitle: Text(
        '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              ref.read(shoppingCartProvider.notifier).updateQuantity(
                    item.product.id,
                    item.quantity - 1,
                  );
            },
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(shoppingCartProvider.notifier).updateQuantity(
                    item.product.id,
                    item.quantity + 1,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(shoppingCartProvider.notifier).removeItem(
                    item.product.id,
                  );
            },
          ),
        ],
      ),
    );
  }
}
```

## BLoC Implementation

Using BLoC pattern with flutter_bloc (abbreviated for brevity—full implementation would include all events/states).

```dart
// Key components shown - full implementation would be longer

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object> get props => [];
}

class LoadProducts extends CartEvent {}
class AddToCart extends CartEvent {
  final Product product;
  const AddToCart(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  const UpdateQuantity(this.productId, this.quantity);
  @override
  List<Object> get props => [productId, quantity];
}

// States
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<Product> products;
  final List<CartItem> cartItems;

  const CartLoaded({
    required this.products,
    required this.cartItems,
  });

  double get total => cartItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

  int get itemCount => cartItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  @override
  List<Object?> get props => [products, cartItems];

  CartLoaded copyWith({
    List<Product>? products,
    List<CartItem>? cartItems,
  }) {
    return CartLoaded(
      products: products ?? this.products,
      cartItems: cartItems ?? this.cartItems,
    );
  }
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());

    try {
      final products = await ProductApi.fetchProducts();
      emit(CartLoaded(products: products, cartItems: []));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    final existingIndex = currentState.cartItems.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    List<CartItem> updatedCart;
    if (existingIndex >= 0) {
      updatedCart = [
        for (var i = 0; i < currentState.cartItems.length; i++)
          if (i == existingIndex)
            currentState.cartItems[i].copyWith(
              quantity: currentState.cartItems[i].quantity + 1,
            )
          else
            currentState.cartItems[i],
      ];
    } else {
      updatedCart = [
        ...currentState.cartItems,
        CartItem(product: event.product, quantity: 1),
      ];
    }

    emit(currentState.copyWith(cartItems: updatedCart));
    _saveCart(updatedCart);
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    final updatedCart = currentState.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();

    emit(currentState.copyWith(cartItems: updatedCart));
    _saveCart(updatedCart);
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    final updatedCart = <CartItem>[];
    for (final item in currentState.cartItems) {
      if (item.product.id == event.productId) {
        if (event.quantity > 0) {
          updatedCart.add(item.copyWith(quantity: event.quantity));
        }
        // If quantity is 0 or less, don't add to list (removes it)
      } else {
        updatedCart.add(item);
      }
    }

    emit(currentState.copyWith(cartItems: updatedCart));
    _saveCart(updatedCart);
  }

  Future<void> _saveCart(List<CartItem> items) async {
    try {
      await ProductApi.saveCart(items);
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }
}
```

## Comparison

### Code Complexity

| Aspect | Provider | Riverpod | BLoC |
|--------|----------|----------|------|
| Lines of Code | ~300 | ~280 | ~400+ |
| Number of Files | 1 | 2 (main + generated) | 1 (but could be split) |
| Boilerplate | Medium | Low (with codegen) | High |
| Type Safety | Runtime | Compile-time | Runtime |

### Async Handling

**Provider:**
- Manual loading/error states in ChangeNotifier
- Requires careful state management
- Works but verbose

**Riverpod:**
- `AsyncValue` handles loading/error/data elegantly
- `.when()` pattern is concise
- Automatic refresh and invalidation

**BLoC:**
- Events for each async operation
- Clear state transitions
- Verbose but very predictable

### Testing

All three are testable, but with different approaches:

**Provider:**
```dart
test('adds item to cart', () {
  final cart = ShoppingCart();
  cart.addItem(testProduct);
  expect(cart.items.length, 1);
  expect(cart.total, testProduct.price);
});
```

**Riverpod:**
```dart
test('adds item to cart', () {
  final container = ProviderContainer();
  container.read(shoppingCartProvider.notifier).addItem(testProduct);
  expect(container.read(shoppingCartProvider).length, 1);
  expect(container.read(cartTotalProvider), testProduct.price);
});
```

**BLoC:**
```dart
blocTest<CartBloc, CartState>(
  'adds item to cart',
  build: () => CartBloc(),
  seed: () => CartLoaded(products: [testProduct], cartItems: []),
  act: (bloc) => bloc.add(AddToCart(testProduct)),
  expect: () => [
    isA<CartLoaded>()
        .having((s) => s.cartItems.length, 'items', 1)
        .having((s) => s.total, 'total', testProduct.price),
  ],
);
```

### Real-World Considerations

**Provider:**
- ✅ Easy to understand and implement
- ✅ Good enough for most apps
- ⚠️ Async state handling is manual
- ⚠️ Can get messy with complex async flows

**Riverpod:**
- ✅ Excellent async handling with AsyncValue
- ✅ Computed providers (total, itemCount) are elegant
- ✅ Compile-time safety prevents errors
- ✅ Best developer experience for this use case
- ⚠️ Requires code generation setup

**BLoC:**
- ✅ Very clear event flow and state transitions
- ✅ Excellent for audit trails (every action is an event)
- ✅ Great for large teams with strict architecture needs
- ⚠️ Most boilerplate for this use case
- ⚠️ Overkill unless event tracking is important

## Conclusion

For a shopping cart with async operations:

**Recommended: Riverpod**
- AsyncValue makes loading/error handling elegant
- Computed providers for total and itemCount
- Code generation reduces boilerplate
- Excellent testing story

**Also Good: Provider**
- Simpler if team is already familiar
- No code generation needed
- Sufficient for most use cases

**Consider BLoC If:**
- Need event logging for analytics
- Building enterprise app with strict architecture
- Want very predictable state flow

The complexity of this example (async loading, multiple operations, computed values) is where Riverpod's advantages become clear. For simpler apps, Provider is perfectly adequate. For enterprise requirements, BLoC provides structure at the cost of more code.

