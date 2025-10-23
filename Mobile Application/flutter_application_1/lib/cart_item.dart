// cart_item.dart
class CartItem {
  final String docId; // Keep consistent naming across provider & UI
  final String name;
  final String imageUrl;
  final int price; // Keep as int since you're using Rs. price
  int quantity;

  CartItem({
    required this.docId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  // Convert CartItem to a Map (for Firestore storage)
  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  // Convert Map to CartItem (for Firestore retrieval)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      docId: map['docId'] ?? map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] is int)
          ? map['price']
          : int.tryParse(map['price']?.toString() ?? '0') ?? 0,
      quantity: (map['quantity'] is int)
          ? map['quantity']
          : int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}
