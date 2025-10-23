// details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'checkout_page.dart';
import 'package:intl/intl.dart'; // for number formatting

class DetailsPage extends StatefulWidget {
  final String docId;
  final String productName;
  final String productImage;
  final dynamic price; // Accept dynamic to handle int, double, or string
  final String description;

  const DetailsPage({
    super.key,
    required this.docId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.description,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int _quantity = 1;

  int get priceValue {
    try {
      if (widget.price is int) return widget.price;
      if (widget.price is double) return widget.price.round();
      if (widget.price is String) {
        // Clean string (remove Rs, commas, spaces)
        return int.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  String get formattedPrice {
    final formatter = NumberFormat("#,##0", "en_US");
    return "Rs. ${formatter.format(priceValue)}";
  }

  void addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    for (int i = 0; i < _quantity; i++) {
      cart.addItem(
        widget.docId,
        widget.productName,
        widget.productImage,
        priceValue,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$_quantity × ${widget.productName} added to cart"),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: "Checkout",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutPage(cart: cart),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: widget.docId,
              child: Image.network(
                widget.productImage,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.watch, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.productName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              formattedPrice, // ✅ Now shows formatted price with commas
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  _quantity.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addToCart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
