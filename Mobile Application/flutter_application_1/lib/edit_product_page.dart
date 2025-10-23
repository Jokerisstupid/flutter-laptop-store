import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditProductPage({super.key, required this.item});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;

  String? _docId;
  String? _imageUrl;
  bool _isUploading = false;
  File? _pickedFile; // for mobile

  @override
  void initState() {
    super.initState();
    final data = widget.item;

    // Accept both 'docId' or 'id'
    _docId = data['docId'] ?? data['id'];
    _nameController = TextEditingController(text: data['name'] ?? data['title'] ?? '');
    _priceController = TextEditingController(text: data['price']?.toString() ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _categoryController = TextEditingController(text: data['category'] ?? '');
    _imageUrl = data['imageUrl'] ?? data['image'] ?? '';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _pickedFile = File(picked.path);
    });

    try {
      final cloudinaryUrl = Uri.parse("https://api.cloudinary.com/v1_1/df1sgdor0/image/upload");
      const uploadPreset = "Image_Adding";

      final request = http.MultipartRequest('POST', cloudinaryUrl)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', _pickedFile!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResp = jsonDecode(responseData);
        setState(() {
          _imageUrl = jsonResp['secure_url'];
          _isUploading = false;
        });
      } else {
        final responseData = await response.stream.bytesToString();
        throw Exception("Upload failed: ${response.statusCode} - $responseData");
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed: $e")),
      );
    }
  }

  void _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields including image")),
      );
      return;
    }
    if (_docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing product ID")),
      );
      return;
    }
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an image")),
      );
      return;
    }

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'imageUrl': _imageUrl!,
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('products')
          .doc(_docId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Name", _nameController),
              _buildTextField("Price", _priceController, isNumber: true),
              _buildTextField("Description", _descriptionController, maxLines: 3),
              _buildTextField("Category", _categoryController),
              const SizedBox(height: 12),
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_imageUrl!, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height:180, color:Colors.grey[300], child: const Icon(Icons.broken_image))),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: Text(_isUploading ? "Uploading..." : "Change Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Update Product", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
