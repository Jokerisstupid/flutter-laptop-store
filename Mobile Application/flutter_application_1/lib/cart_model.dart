// cart_model.dart
class ProductModel {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  ProductModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  // Convert ProductModel to a Map (for Firestore storage)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  // Convert Map to ProductModel (for Firestore retrieval)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    double parsedPrice;
    if (map['price'] is double) {
      parsedPrice = map['price'];
    } else {
      parsedPrice = double.tryParse(map['price']?.toString() ?? '0') ?? 0.0;
    }

    return ProductModel(
      productId: map['productId'] ?? map['docId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: parsedPrice,
      quantity: (map['quantity'] is int)
          ? map['quantity']
          : int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}
