// cart_provider.dart
import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalAmount {
    int total = 0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  void addItem(String docId, String name, String imageUrl, int price) {
    if (_items.containsKey(docId)) {
      _items.update(
        docId,
        (existing) => CartItem(
          docId: existing.docId,
          name: existing.name,
          imageUrl: existing.imageUrl,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        docId,
        () => CartItem(
          docId: docId,
          name: name,
          imageUrl: imageUrl,
          price: price,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String docId) {
    if (!_items.containsKey(docId)) return;

    if (_items[docId]!.quantity > 1) {
      _items.update(
        docId,
        (existing) => CartItem(
          docId: existing.docId,
          name: existing.name,
          imageUrl: existing.imageUrl,
          price: existing.price,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(docId);
    }
    notifyListeners();
  }

  void removeItem(String docId) {
    _items.remove(docId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
