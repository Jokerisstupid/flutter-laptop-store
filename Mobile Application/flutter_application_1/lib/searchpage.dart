// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'details_page.dart'; // uncomment if you navigate to details

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = "";

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  num _parsePrice(dynamic priceVal) {
    if (priceVal == null) return 0;
    if (priceVal is num) return priceVal;
    final cleaned = priceVal.toString().trim().replaceAll(RegExp(r'[^0-9.]'), '');
    return num.tryParse(cleaned) ?? 0;
  }

  String _formatWithCommas(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }

  String _formatPrice(num price) {
    if (price % 1 == 0) {
      return "Rs. ${_formatWithCommas(price.toInt())}";
    } else {
      final intPart = price.floor();
      final decimals = ((price - intPart) * 100).round().toString().padLeft(2, '0');
      return "Rs. ${_formatWithCommas(intPart)}.$decimals";
    }
  }

  @override
  Widget build(BuildContext context) {
    // explicit colors for textfield
    final textColor = Colors.black;
    final hintColor = Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Laptops"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search box (in the body to avoid AppBar theming quirks)
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        cursorColor: Colors.indigo,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Search for laptops, brands or models",
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.red),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _query = "";
                                    });
                                    _focusNode.requestFocus();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          setState(() {
                            _query = v.toLowerCase().trim();
                          });
                        },
                        onSubmitted: (v) {
                          setState(() {
                            _query = v.toLowerCase().trim();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Debug box (shows controller content; remove in production)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Row(
                children: [
                  const Text("Controller text: ", style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(
                      _controller.text.isEmpty ? "<empty>" : _controller.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Results
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No products found."));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    if (_query.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    return name.contains(_query) || category.contains(_query);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No matching laptops."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final priceNum = _parsePrice(data['price']);
                      final priceText = _formatPrice(priceNum);

                      return ListTile(
                        leading: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                            ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.laptop),
                        title: Text(data['name'] ?? "Unnamed"),
                        subtitle: Text(priceText),
                        onTap: () {
                          // navigate to details if you have DetailsPage with matching constructor
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(...)));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
