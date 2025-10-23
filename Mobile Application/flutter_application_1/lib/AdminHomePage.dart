// admin_home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_product_form.dart';
import 'edit_product_page.dart';
import 'admin_reviews_page.dart';
import 'package:intl/intl.dart'; // for price & time formatting

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final products = FirebaseFirestore.instance.collection('products');
  final orders = FirebaseFirestore.instance.collection('orders');

  /* ───────────── Delete Product ───────────── */
  void _deleteProduct(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await products.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted")),
        );
      }
    }
  }

  /* ───────────── Delete Order ───────────── */
  void _deleteOrder(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Order"),
        content: const Text(
            "Are you sure you want to delete this order permanently?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await orders.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order deleted")),
        );
      }
    }
  }

  /* ───────────── Dashboard Summary ───────────── */
  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard(Icons.shopping_cart, "Orders", orders, Colors.teal),
        _summaryCard(Icons.laptop, "Products", products, Colors.indigo),
        _summaryCard(Icons.reviews, "Reviews",
            FirebaseFirestore.instance.collection('reviews'), Colors.orange),
      ],
    );
  }

  Widget _summaryCard(
      IconData icon, String label, CollectionReference ref, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          color: color.withOpacity(0.1),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 6),
                Text(
                  "$count",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(label,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ───────────── Helpers: price/time/fields ───────────── */
  String formatPrice(dynamic price) {
    final formatter = NumberFormat("#,##0", "en_US");
    try {
      if (price == null) return "Rs. 0";
      if (price is int) return "Rs. ${formatter.format(price)}";
      if (price is double) return "Rs. ${formatter.format(price.round())}";
      if (price is String) {
        final parsed =
            int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return "Rs. ${formatter.format(parsed)}";
      }
      if (price is num) return "Rs. ${formatter.format(price.toInt())}";
    } catch (_) {}
    return "Rs. 0";
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return 'Unknown';
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }
      if (ts is Map && ts['seconds'] != null) {
        final dt =
            DateTime.fromMillisecondsSinceEpoch((ts['seconds'] * 1000).toInt());
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }
      if (ts is int) {
        if (ts > 9999999999) {
          return DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.fromMillisecondsSinceEpoch(ts));
        } else {
          return DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
        }
      }
      return ts.toString();
    } catch (_) {
      return ts.toString();
    }
  }

  // robust helpers for item fields (items may use different keys)
  String _imageFromItem(Map<String, dynamic> item,
      [Map<String, dynamic>? orderData]) {
    final candidates = [
      item['imageUrl'],
      item['image'],
      item['img'],
      item['productImage'],
      item['product_image'],
      orderData?['imageUrl'],
      orderData?['productImage'],
    ];
    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) return c.toString();
    }
    return "";
  }

  String _nameFromItem(Map<String, dynamic> item,
      [Map<String, dynamic>? orderData]) {
    final candidates = [
      item['productName'],
      item['name'],
      item['title'],
      orderData?['productName'],
      orderData?['name'],
    ];
    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) return c.toString();
    }
    return "No Product Name";
  }

  num _priceFromItem(Map<String, dynamic> item) {
    final p = item['price'] ?? item['productPrice'] ?? item['amount'] ?? 0;
    if (p is num) return p;
    if (p is String) {
      return num.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  int _qtyFromItem(Map<String, dynamic> item) {
    final q = item['quantity'] ?? item['qty'] ?? 1;
    if (q is int) return q;
    if (q is num) return q.toInt();
    if (q is String) return int.tryParse(q) ?? 1;
    return 1;
  }

  /* ───────────── User Orders (robust: accepts items OR cartItems and fallbacks) ───────────── */
  Widget _buildUserOrders() {
    const statusOptions = [
      'Pending',
      'Processing',
      'Shipped',
      'Out for Delivery',
      'Delivered',
      'Cancelled',
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: orders.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading orders");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final orderDocs = snapshot.data?.docs ?? [];
        if (orderDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No orders yet."),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderDocs.length,
          itemBuilder: (context, index) {
            final doc = orderDocs[index];
            final orderData =
                (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

            // Accept both 'items' (your CheckoutPage) or 'cartItems' (older naming)
            final List<Map<String, dynamic>> items = [];
            final dynamic rawItemsA = orderData['items'];
            final dynamic rawItemsB = orderData['cartItems'];

            if (rawItemsA is List) {
              for (final it in rawItemsA) {
                if (it is Map<String, dynamic>) {
                  items.add(it);
                } else if (it is Map) {
                  items.add(Map<String, dynamic>.from(it));
                }
              }
            } else if (rawItemsB is List) {
              for (final it in rawItemsB) {
                if (it is Map<String, dynamic>) {
                  items.add(it);
                } else if (it is Map) {
                  items.add(Map<String, dynamic>.from(it));
                }
              }
            }

            // fallback: if no items array, try to craft one from top-level fields
            if (items.isEmpty) {
              final topName =
                  (orderData['productName'] ?? orderData['name'] ?? '')
                      .toString();
              final topImg =
                  (orderData['productImage'] ?? orderData['imageUrl'] ?? '')
                      .toString();
              final topPrice =
                  orderData['price'] ?? orderData['productPrice'] ?? 0;
              final topQty = orderData['quantity'] ?? 1;
              if (topName.isNotEmpty ||
                  topImg.isNotEmpty ||
                  (topPrice != null && topPrice != 0)) {
                items.add({
                  'productName': topName,
                  'imageUrl': topImg,
                  'price': topPrice,
                  'quantity': topQty,
                  'subtotal': (topPrice is num)
                      ? topPrice *
                          (int.tryParse(topQty?.toString() ?? '1') ?? 1)
                      : topPrice,
                });
              }
            }

            final firstItem = items.isNotEmpty ? items[0] : <String, dynamic>{};
            final imageUrl = _imageFromItem(firstItem, orderData);
            final titleName = _nameFromItem(firstItem, orderData);

            final totalRaw = orderData['total'] ??
                orderData['totalAmount'] ??
                orderData['orderTotal'] ??
                0;
            final totalString = formatPrice(totalRaw);

            final timeString = _formatTimestamp(orderData['timestamp']);
            final currentStatusRaw =
                (orderData['status'] ?? 'Pending').toString();
            final displayedStatus = statusOptions.contains(currentStatusRaw)
                ? currentStatusRaw
                : 'Pending';

            final userName =
                orderData['userName'] ?? orderData['name'] ?? 'Unknown';
            final userEmail =
                orderData['userEmail'] ?? orderData['email'] ?? '';
            final userMobile =
                orderData['userMobile'] ?? orderData['mobile'] ?? '';
            final userAddress =
                orderData['userAddress'] ?? orderData['address'] ?? '';

            // If totalRaw is zero, try to compute from items
            String computedTotalString = totalString;
            if ((totalRaw == null || totalRaw == 0) && items.isNotEmpty) {
              num sum = 0;
              for (final it in items) {
                final price = _priceFromItem(it);
                final qty = _qtyFromItem(it);
                sum += price * qty;
              }
              computedTotalString = formatPrice(sum);
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: thumbnail + basic info + delete
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 50),
                                )
                              : const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Icon(Icons.image, size: 50),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleName.isNotEmpty
                                    ? titleName
                                    : "Order ${doc.id}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text("Order ID: ${doc.id}",
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Text("Total: $computedTotalString",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              if (userName != null) Text("Name: $userName"),
                              if (userEmail != null &&
                                  userEmail.toString().isNotEmpty)
                                Text("Email: $userEmail"),
                              if (userMobile != null &&
                                  userMobile.toString().isNotEmpty)
                                Text("Mobile: $userMobile"),
                              if (userAddress != null &&
                                  userAddress.toString().isNotEmpty)
                                Text("Address: $userAddress"),
                              Text("Time: $timeString"),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOrder(doc.id),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(),

                    // Per-item breakdown (or "No items")
                    if (items.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Items:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...items.map((it) {
                            final name = _nameFromItem(it, orderData);
                            final qty = _qtyFromItem(it);
                            final priceRaw = _priceFromItem(it);
                            final subtotalRaw =
                                it['subtotal'] ?? (priceRaw * qty);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text("$name x $qty",
                                          style:
                                              const TextStyle(fontSize: 14))),
                                  Text(formatPrice(priceRaw),
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 12),
                                  Text(formatPrice(subtotalRaw),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("No items found for this order."),
                      ),

                    const SizedBox(height: 12),

                    // Status row (update)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Status:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: displayedStatus,
                            underline: const SizedBox(),
                            items: statusOptions.map((status) {
                              return DropdownMenuItem(
                                  value: status, child: Text(status));
                            }).toList(),
                            onChanged: (newStatus) async {
                              if (newStatus == null) return;
                              try {
                                await orders
                                    .doc(doc.id)
                                    .update({'status': newStatus});
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Order updated to $newStatus")),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Failed to update status: $e")),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* ───────────── UI ───────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.indigo.shade800,
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.reviews, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductForm()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            const Text("📦 Product List",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  products.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Error loading products");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final productList = snapshot.data?.docs ?? [];
                if (productList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No products found."),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final doc = productList[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (data['imageUrl'] != null &&
                                  data['imageUrl'] != "")
                              ? Image.network(data['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image))
                              : const Icon(Icons.image),
                        ),
                        title: Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatPrice(data['price'] ?? 0)),
                            if (data['category'] != null &&
                                data['category'].toString().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  data['category'],
                                  style: TextStyle(
                                      color: Colors.indigo.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProductPage(item: {
                                      'docId': doc.id,
                                      'name': data['name'],
                                      'price': data['price'],
                                      'category': data['category'],
                                      'description': data['description'],
                                      'imageUrl': data['imageUrl'],
                                    }),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            const Text("🛒 User Orders",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildUserOrders(),
          ],
        ),
      ),
    );
  }
}
