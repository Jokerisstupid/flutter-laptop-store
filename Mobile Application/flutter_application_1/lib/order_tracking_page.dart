import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  static const List<String> _statusFlow = <String>[
    'Pending',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  int _statusIndex(String raw) {
    final s = raw.trim();
    final idx = _statusFlow.indexWhere((e) => e.toLowerCase() == s.toLowerCase());
    return idx < 0 ? 0 : idx;
  }

  DateTime _parseTimestampToDate(dynamic ts) {
    try {
      if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (ts is Timestamp) return ts.toDate();
      if (ts is Map && ts['seconds'] != null) {
        final secs = ts['seconds'];
        if (secs is int) return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        if (secs is double) {
          return DateTime.fromMillisecondsSinceEpoch((secs * 1000).round());
        }
      }
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
      if (ts is String) {
        return DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("⚠️ No user logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders yet."));
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final da = a.data() as Map<String, dynamic>;
              final db = b.data() as Map<String, dynamic>;
              final ta = _parseTimestampToDate(da['timestamp']);
              final tb = _parseTimestampToDate(db['timestamp']);
              return tb.compareTo(ta);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final orderId = doc.id;

              // ✅ FIX: Read from "items" instead of "products"
              final List items = (data['items'] is List) ? data['items'] as List : [];

              final Map<String, dynamic> firstItem =
                  items.isNotEmpty ? Map<String, dynamic>.from(items.first) : {};

              final String productImage = firstItem['imageUrl']?.toString() ?? '';
              final String productName =
                  items.isNotEmpty ? firstItem['productName']?.toString() ?? '' : 'Unknown';

              final double totalPrice = (data['total'] ?? 0).toDouble();

              final status = (data['status'] ?? 'Pending').toString();
              final createdAt = _parseTimestampToDate(data['timestamp']);

              final userName = (data['userName'] ?? '').toString();
              final userMobile = (data['userMobile'] ?? '').toString();
              final userAddress = (data['userAddress'] ?? '').toString();

              final step = _statusIndex(status);
              final displayIndex = step.clamp(0, _statusFlow.length - 1);
              final isDelivered = status.toLowerCase() == 'delivered';
              final isCancelled = status.toLowerCase() == 'cancelled';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text("Order #$orderId",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDelivered
                                  ? Colors.green.withOpacity(0.15)
                                  : (isCancelled
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.blue.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDelivered
                                    ? Colors.green[700]
                                    : (isCancelled
                                        ? Colors.red[700]
                                        : Colors.blue[700]),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Product row (first item image + summary)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (productImage.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                productImage,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 64),
                              ),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image, size: 36, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(productName,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text("Placed: ${createdAt.toLocal().toString().split('.').first}",
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("Total: Rs. ${totalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // User details
                      if (userName.isNotEmpty)
                        Text("👤 Name: $userName", style: const TextStyle(fontSize: 13)),
                      if (userMobile.isNotEmpty)
                        Text("📞 Mobile: $userMobile", style: const TextStyle(fontSize: 13)),
                      if (userAddress.isNotEmpty)
                        Text("📍 Address: $userAddress", style: const TextStyle(fontSize: 13)),

                      if (items.isNotEmpty) ...[
                        const Divider(),
                        const Text("Items:",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...items.map((p) {
                          final name = p['productName'] ?? '';
                          final qty = p['quantity'] ?? 1;
                          final price = p['price'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(name, overflow: TextOverflow.ellipsis),
                                ),
                                Text("x$qty • Rs. $price"),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: 12),

                      _StatusProgressRow(currentStep: displayIndex, totalSteps: 5),
                      const SizedBox(height: 6),
                      Text("Progress: ${_statusFlow[displayIndex]}",
                          style: const TextStyle(fontSize: 12)),

                      // Cancel Button
                      if (status.toLowerCase() == 'pending') ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Cancel Order"),
                                  content: const Text(
                                      "Are you sure you want to cancel this order?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Yes, Cancel"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection("orders")
                                    .doc(orderId)
                                    .update({"status": "Cancelled"});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("❌ Order cancelled")),
                                );
                              }
                            },
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text("Cancel Order",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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

class _StatusProgressRow extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StatusProgressRow({Key? key, required this.currentStep, required this.totalSteps})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final active = currentStep.clamp(0, totalSteps).toInt();
    return Row(
      children: List.generate(totalSteps, (i) {
        final filled = i <= active && active != 5;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0.0 : 6.0),
            decoration: BoxDecoration(
              color: active == 5
                  ? Colors.red.withOpacity(0.35)
                  : (filled ? Colors.green : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}
