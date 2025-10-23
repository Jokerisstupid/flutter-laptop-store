import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_provider.dart';

class CheckoutPage extends StatefulWidget {
  final CartProvider cart;

  const CheckoutPage({super.key, required this.cart});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  String userEmail = '';
  String userId = '';
  bool isPlacingOrder = false;
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userEmail = user.email ?? '';
      userId = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _mobileController.text = data['mobile'] ?? '';
        _addressController.text = data['address'] ?? '';
      }
    }
    if (mounted) setState(() => isLoadingUser = false);
  }

  Future<void> placeOrder() async {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all contact details.")),
      );
      return;
    }

    setState(() => isPlacingOrder = true);

    final order = {
      'items': widget.cart.items.values.map((item) => {
            'productId': item.docId,
            'productName': item.name,
            'imageUrl': item.imageUrl,
            'price': item.price,
            'quantity': item.quantity,
            'subtotal': item.price * item.quantity,
          }).toList(),
      'total': widget.cart.totalAmount,
      'userEmail': userEmail,
      'userId': userId,
      'userName': _nameController.text.trim(),
      'userMobile': _mobileController.text.trim(),
      'userAddress': _addressController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(order);

      if (!mounted) return;
      setState(() => isPlacingOrder = false);

      widget.cart.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully 🎉")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _sectionTitle("Contact Details", theme, Icons.person),
                  const SizedBox(height: 10),
                  _buildTextField(_nameController, "Full Name", theme,
                      icon: Icons.person_outline),
                  const SizedBox(height: 10),
                  _buildTextField(_mobileController, "Mobile", theme,
                      icon: Icons.phone, keyboard: TextInputType.phone),
                  const SizedBox(height: 10),
                  _buildTextField(_addressController, "Address", theme,
                      icon: Icons.home_outlined),
                  const SizedBox(height: 25),

                  _sectionTitle("Order Summary", theme, Icons.shopping_bag),
                  const SizedBox(height: 10),
                  ...widget.cart.items.values.map((item) {
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.laptop,
                                  size: 30, color: Colors.grey),
                            ),
                          ),
                        ),
                        title: Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text(
                          "Rs. ${item.price} x ${item.quantity}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Text(
                          "Rs. ${item.price * item.quantity}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "Rs. ${widget.cart.totalAmount}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isPlacingOrder ? null : placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: isPlacingOrder
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart_checkout, size: 22),
                      label: Text(
                        isPlacingOrder ? "Placing Order..." : "Place Order",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      ThemeData theme,
      {TextInputType keyboard = TextInputType.text, IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
