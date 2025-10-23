import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart'; // ✅ For Web/Laptop

class AddProductForm extends StatefulWidget {
  const AddProductForm({Key? key}) : super(key: key);

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<String> categories = [
    'Gaming',
    'Business',
    'Student',
    'Ultrabook',
    'MacBook',
  ];
  String? selectedCategory;

  Uint8List? _imageBytes;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  // Upload to Cloudinary
  Future<String> uploadImageToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'df1sgdor0'; 
    const uploadPreset = 'Image_Adding'; 

    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: 'upload.jpg'));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = json.decode(resStr);
      return resJson['secure_url'];
    } else {
      final resStr = await response.stream.bytesToString();
      throw Exception("Image upload failed: ${response.statusCode} - $resStr");
    }
  }

  Future<void> pickImageAndUpload() async {
    final pickedBytes = await ImagePickerWeb.getImageAsBytes();

    if (pickedBytes != null) {
      setState(() {
        _imageBytes = pickedBytes;
        _isUploading = true;
      });

      try {
        final imageUrl = await uploadImageToCloudinary(pickedBytes);
        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an image")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'price': priceController.text.trim(), // ✅ Store as String
        'description': descriptionController.text.trim(),
        'category': selectedCategory ?? '',
        'imageUrl': _uploadedImageUrl!,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laptop added successfully")),
      );

      nameController.clear();
      priceController.clear();
      descriptionController.clear();
      setState(() {
        selectedCategory = null;
        _uploadedImageUrl = null;
        _imageBytes = null;
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add product: $e")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Add Laptop"),
        backgroundColor: Colors.indigo.shade700,
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Laptop Name
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Laptop Name",
                      prefixIcon: Icon(Icons.laptop),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter Laptop name" : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Price
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Price (PKR)",
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter price" : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter description" : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Please select a category" : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Upload Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : pickImageAndUpload,
                icon: const Icon(Icons.cloud_upload),
                label: _isUploading
                    ? const Text("Uploading...")
                    : const Text("Upload Image from Laptop"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover),
                  ),
                ),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Submit Laptop"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
