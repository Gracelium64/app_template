import 'package:flutter/material.dart';
import 'package:test_app/src/services/cart_storage.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartEntry> _cart = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cart = await CartStorage.getCart();
    if (!mounted) return;
    setState(() {
      _cart = cart;
      _loading = false;
    });
  }

  double get _total =>
      _cart.fold(0.0, (s, e) => s + e.product.price * e.quantity);

  int get _totalItems => _cart.fold(0, (s, e) => s + e.quantity);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isSmall = MediaQuery.of(context).size.width < 600;
    final padding = EdgeInsets.symmetric(
      horizontal: isSmall ? 16 : 40,
      vertical: isSmall ? 20 : 40,
    );

    if (_cart.isEmpty) {
      return const Center(child: Text('Your cart is empty.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: padding,
            itemCount: _cart.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _cart[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.network(
                          item.product.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${item.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () async {
                              final newQty = item.quantity - 1;
                              await CartStorage.updateQuantity(
                                item.product.id,
                                newQty,
                              );
                              if (!mounted) return;
                              await _load();
                            },
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              await CartStorage.updateQuantity(
                                item.product.id,
                                item.quantity + 1,
                              );
                              if (!mounted) return;
                              await _load();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await CartStorage.removeFromCart(item.product.id);
                              if (!mounted) return;
                              await _load();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 40,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total items: $_totalItems', textAlign: TextAlign.right),
              Text(
                'Total price: \$${_total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order confirmed')),
                  );
                  await CartStorage.clearCart();
                  await _load();
                },
                child: const Text('Place Order'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
