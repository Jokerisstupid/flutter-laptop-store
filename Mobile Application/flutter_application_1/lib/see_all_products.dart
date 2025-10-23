import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_page.dart';
import 'package:intl/intl.dart'; // ✅ for number formatting

class SeeAllProductsPage extends StatelessWidget {
  const SeeAllProductsPage({super.key});

  String formatPrice(dynamic price) {
    final formatter = NumberFormat("#,##0", "en_US");
    try {
      if (price is int) return "Rs. ${formatter.format(price)}";
      if (price is double) return "Rs. ${formatter.format(price.round())}";
      if (price is String) {
        final parsed = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return "Rs. ${formatter.format(parsed)}";
      }
    } catch (_) {}
    return "Rs. 0";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Laptop"),
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true) // ✅ Sorted by timestamp
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading products"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No laptops found"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final rawPrice = data['price'];
              final parsedPrice = int.tryParse(rawPrice.toString()) ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(
                        docId: doc.id,
                        productName: data['name'] ?? 'No Name',
                        productImage: data['imageUrl'] ?? '',
                        price: parsedPrice, // ✅ always int
                        description: data['description'] ?? 'No description',
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            height: 110,
                            width: 110,
                            child: const Icon(Icons.computer,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatPrice(rawPrice), // ✅ formatted price
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Authentic Product • 2 Year Warranty",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
