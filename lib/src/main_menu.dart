import 'package:flutter/material.dart';
import 'package:test_app/src/core/extensions/context_mq_extension.dart';
import 'package:test_app/src/data/databaserepository.dart';
import 'package:test_app/src/pages/shop_page.dart';
import 'package:test_app/src/pages/cart_page.dart';

class MainMenu extends StatefulWidget {
  final DataBaseRepository db;

  const MainMenu(this.db, {super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _index = 0;

  void _setPage(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = context.scrnIsLandscape;
    final pages = [const ShopPage(), const CartPage()];

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _setPage(0),
                child: const Text(
                  'FakeStore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () => _setPage(0),
                child: Text(
                  'Shop',
                  style: TextStyle(
                    color: _index == 0
                        ? const Color(0xFF111111)
                        : const Color(0xFF555555),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _setPage(1),
                child: Text(
                  'Cart',
                  style: TextStyle(
                    color: _index == 1
                        ? const Color(0xFF111111)
                        : const Color(0xFF555555),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isLandscape
            ? Colors.green
            : const Color.fromARGB(156, 80, 99, 255),
        child: isLandscape
            ? const Text('LANDSCAPE', style: TextStyle(fontSize: 9))
            : const Text('PORTRAIT', style: TextStyle(fontSize: 9)),
        onPressed: () {},
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: pages[_index],
        ),
      ),
    );
  }
}
