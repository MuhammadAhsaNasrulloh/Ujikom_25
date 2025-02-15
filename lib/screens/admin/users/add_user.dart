import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/services/auth_service.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  State<AddUser> createState() => _AddUserState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _AddUserState extends State<AddUser> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  String selectedRole = 'kasir';
  File? _selectedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to upload profile picture to Supabase storage
  Future<String?> _uploadProfilePicture(File image) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'foto_profiles/$fileName';

      await supabase.storage.from('foto_profiles').upload(filePath, image);
      return supabase.storage.from('foto_profiles').getPublicUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error mengunggah gambar: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _addUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final fullName = fullNameController.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi!')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak valid!')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password harus minimal 6 karakter!')),
      );
      return;
    }

    try {
      // Upload gambar jika ada
      if (_selectedImage != null) {
        _uploadedImageUrl = await _uploadProfilePicture(_selectedImage!);
        if (_uploadedImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah gambar!')),
          );
          return;
        }
      }

      final authService = AuthService();
      await authService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: selectedRole,
        fotoProfile: _uploadedImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil ditambahkan!')),
        );

        // Clear form setelah berhasil
        emailController.clear();
        passwordController.clear();
        fullNameController.clear();
        setState(() {
          selectedRole = 'kasir';
          _selectedImage = null;
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(screenSize),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                color: AppColors.backgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambah Pengguna',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                          'Email', emailController, false, Icons.email),
                      _buildTextField(
                          'Password', passwordController, true, Icons.lock),
                      _buildTextField('Nama Lengkap', fullNameController, false,
                          Icons.person),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRole = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(
                            Icons.badge,
                            color: Color(0xFF005BAC),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF005BAC),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'kasir', child: Text('Kasir')),
                          DropdownMenuItem(
                              value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                              value: 'owner', child: Text('Owner')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF005BAC),
                                width: 2,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 40,
                                        color: Color(0xFF005BAC),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Pilih Foto Profil',
                                        style: TextStyle(
                                          color: Color(0xFF005BAC),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _addUser(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005BAC),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Tambah User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    final double toolbarHeight =
        screenSize.height * 0.08; // 8% of screen height

    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      iconTheme: IconThemeData(color: Colors.white),
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waixi Laundry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color:AppColors.primaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF005BAC),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
