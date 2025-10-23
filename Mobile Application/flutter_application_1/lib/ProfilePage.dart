import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'order_tracking_page.dart';
import 'userloginpage.dart'; // ✅ Make sure this is your correct login page file

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _previewUrl;
  String? _localPath;
  Uint8List? _webImage;

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  /// Upload image to Cloudinary
  Future<String?> _uploadToCloudinary({File? imageFile, Uint8List? bytes}) async {
    const cloudName = "df1sgdor0";
    const uploadPreset = "profile_pic";

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", url);
    request.fields["upload_preset"] = uploadPreset;

    if (kIsWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes("file", bytes, filename: "profile.jpg"));
    } else if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath("file", imageFile.path));
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data["secure_url"];
    } else {
      debugPrint("❌ Cloudinary upload failed: $resBody");
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No user logged in")),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile == null) return;

      setState(() => _loading = true);

      String? downloadUrl;
      if (kIsWeb) {
        _webImage = await pickedFile.readAsBytes();
        downloadUrl = await _uploadToCloudinary(bytes: _webImage);
      } else {
        _localPath = pickedFile.path;
        downloadUrl = await _uploadToCloudinary(imageFile: File(_localPath!));
      }

      if (downloadUrl == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Upload failed. Try again.")),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _previewUrl = downloadUrl;
        _loading = false;
      });

      await _firestore.collection("users").doc(user.uid).set({
        "profilePic": downloadUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile picture updated")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).set({
      "name": _nameController.text.trim(),
      "mobile": _mobileController.text.trim(),
      "address": _addressController.text.trim(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Profile updated")),
    );
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _auth.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📩 Password reset email sent")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;

    /// ✅ This will remove all previous routes and go to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginForm()), // make sure LoginForm is your login widget
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (user != null)
            IconButton(
              tooltip: "Logout",
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            )
        ],
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection("users").doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No user data found"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final name = data['name'] ?? "";
                final email = data['email'] ?? user.email ?? "";
                final mobile = data['mobile'] ?? "";
                final address = data['address'] ?? "";
                final profilePic = data['profilePic'] as String?;

                _nameController.text = name;
                _mobileController.text = mobile;
                _addressController.text = address;

                ImageProvider<Object>? avatarImage;
                if (_webImage != null) {
                  avatarImage = MemoryImage(_webImage!);
                } else if (_localPath != null) {
                  avatarImage = FileImage(File(_localPath!));
                } else if (_previewUrl != null) {
                  avatarImage = NetworkImage(_previewUrl!);
                } else if (profilePic != null && profilePic.isNotEmpty) {
                  avatarImage = NetworkImage(profilePic);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: avatarImage,
                            backgroundColor: Colors.grey[300],
                            child: avatarImage == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          if (!_loading)
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blueAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                                  onPressed: _pickAndUploadImage,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildTextField("Name", _nameController),
                      const SizedBox(height: 12),
                      _buildTextField("Mobile", _mobileController),
                      const SizedBox(height: 12),
                      _buildTextField("Address", _addressController),
                      const SizedBox(height: 12),
                      _buildTextField("Email", TextEditingController(text: email), readOnly: true),
                      const SizedBox(height: 20),

                      _buildButton("Save Changes", Icons.save, Colors.blueAccent, _saveProfile),
                      const SizedBox(height: 12),
                      _buildButton("Change Password", Icons.lock_reset, Colors.orange, _changePassword),
                      const SizedBox(height: 12),
                      _buildButton("Track My Orders", Icons.local_shipping, Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrderTrackingPage()),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        shadowColor: Colors.black45,
        elevation: 4,
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
