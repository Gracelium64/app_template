import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/src/models/product.dart';

class CartEntry {
  final Product product;
  int quantity;

  CartEntry({required this.product, required this.quantity});

  factory CartEntry.fromJson(Map<String, dynamic> json) {
    return CartEntry(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
}

class CartStorage {
  static const _key = 'cart';

  static Future<List<CartEntry>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    final list = json.decode(s) as List<dynamic>;
    return list
        .map((e) => CartEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _save(List<CartEntry> cart) async {
    final prefs = await SharedPreferences.getInstance();
    final s = json.encode(cart.map((e) => e.toJson()).toList());
    await prefs.setString(_key, s);
  }

  static Future<void> addToCart(Product p) async {
    final cart = await getCart();
    final idx = cart.indexWhere((e) => e.product.id == p.id);
    if (idx >= 0) {
      cart[idx].quantity++;
    } else {
      cart.add(CartEntry(product: p, quantity: 1));
    }
    await _save(cart);
  }

  static Future<void> removeFromCart(int productId) async {
    final cart = await getCart();
    cart.removeWhere((e) => e.product.id == productId);
    await _save(cart);
  }

  static Future<void> updateQuantity(int productId, int quantity) async {
    final cart = await getCart();
    final idx = cart.indexWhere((e) => e.product.id == productId);
    if (idx >= 0) {
      if (quantity <= 0) {
        cart.removeAt(idx);
      } else {
        cart[idx].quantity = quantity;
      }
    }
    await _save(cart);
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
