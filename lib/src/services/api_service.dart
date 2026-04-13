import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test_app/src/models/product.dart';

class ApiService {
  static const _baseUrl = 'https://fakestoreapi.com';

  Future<List<Product>> getProducts() async {
    final res = await http.get(Uri.parse('$_baseUrl/products'));
    if (res.statusCode == 200) {
      final List<dynamic> list = json.decode(res.body) as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load products: ${res.statusCode}');
  }
}
