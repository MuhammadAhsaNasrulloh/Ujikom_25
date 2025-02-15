import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/models/product_model.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _produkController = TextEditingController();
  final _hargaController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedUnitId;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool isLoading = false;
  List<Map<String, dynamic>> _category = [];
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchCategory(),
      _fetchUnits(),
    ]);
  }

  @override
  void dispose() {
    _produkController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategory() async {
    try {
      final response = await supabase.from('category').select('id, kategori');
      setState(() {
        _category = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackBar('Error mengambil kategori : $e', isError: true);
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await supabase.from('units').select('id, unit');
      setState(() {
        _units = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackBar('Error mengambil unit: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage(_selectedImage!);
      }
    } catch (e) {
      _showSnackBar('Error memilih gambar: $e', isError: true);
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'product_images/$fileName';

      await supabase.storage.from('product_images').upload(filePath, image);
      final publicUrl =
          supabase.storage.from('product_images').getPublicUrl(filePath);

      setState(() {
        _uploadedImageUrl = publicUrl;
      });
    } catch (e) {
      _showSnackBar('Error mengunggah gambar: $e', isError: true);
    }
  }

  Future<void> _addProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Mohon lengkapi semua field', isError: true);
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnackBar('Mohon pilih layanan', isError: true);
      return;
    }

    if (_selectedUnitId == null) {
      _showSnackBar('Mohon pilih unit', isError: true);
      return;
    }

    if (_uploadedImageUrl == null) {
      _showSnackBar('Mohon upload gambar produk', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final product = Product(
        produk: _produkController.text,
        unitId: int.parse(_selectedUnitId!),
        categoryId: int.parse(_selectedCategoryId!),
        fotoProduk: _uploadedImageUrl,
        harga: double.parse(_hargaController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await supabase.from('products').insert(product.toJson());

      _showSnackBar('Produk berhasil ditambahkan!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF005BAC),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Detail Produk',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005BAC),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                            'Nama Produk', _produkController, false),
                        _buildDropdownFieldCategory(),
                        _buildDropdownFieldUnit(),
                        _buildImageUploader(),
                        _buildTextField('Harga', _hargaController, true),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _addProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BAC),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Tambah Produk',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
    );
  }

   Widget _buildDropdownFieldCategory() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _category.map((category) {
        return DropdownMenuItem<String>(
          value: category['id'].toString(),
          child: Text(category['kategori'] ?? 'Unknown'),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedCategoryId = val);
      },
    );
  }

  Widget _buildDropdownFieldUnit() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedUnitId,
        decoration: InputDecoration(
          labelText: 'Unit',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _units.map((unit) {
          return DropdownMenuItem<String>(
            value: unit['id'].toString(),
            child: Text(
                unit['unit'] ?? 'Unknown'), // Berikan nilai default jika null
          );
        }).toList(),
        onChanged: (val) {
          if (mounted) {
            setState(() => _selectedUnitId = val);
          }
        },
      ),
    );
  }

  Widget _buildImageUploader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto Produk',
              style: TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih Gambar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isNumeric,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (isNumeric) {
            final number = num.tryParse(value);
            if (number == null) {
              return '$label harus berupa angka';
            }
          }
          return null;
        },
      ),
    );
  }

  int _selectedIndex = 1;
  Widget _buildBottomAppBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          Navigator.pushNamed(context, AppRoutes.activityLog);
        } else if (index == 1) {
          Navigator.pushNamed(context, AppRoutes.adminDashboard);
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.profilePage);
        }
      },
      selectedItemColor: const Color(0xFF005BAC),
      unselectedItemColor: Colors.grey,
      selectedIconTheme:
          const IconThemeData(color: Color(0xFF005BAC), size: 28),
      unselectedIconTheme: const IconThemeData(color: Colors.grey, size: 24),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
