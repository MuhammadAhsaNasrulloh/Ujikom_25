import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EditProduct extends StatefulWidget {
  final dynamic productId;
  const EditProduct({super.key, required this.productId});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _EditProductState extends State<EditProduct> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  Map<String, dynamic>? productDetail;
  List<dynamic> categories = [];
  List<dynamic> units = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? selectedCategoryId;
  String? selectedUnitId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      await Future.wait([
        _fetchProductDetail(),
        _fetchCategories(),
        _fetchUnits(),
      ]);
    } catch (e) {
      _showErrorMessage('Error fetching data: $e');
    }
  }

  Future<void> _fetchProductDetail() async {
    try {
      final response = await _supabase.from('products').select('''
            *,
            kategori:category(*),
            unit:units(*)
          ''').eq('id', widget.productId).single();

      if (response != null) {
        setState(() {
          productDetail = response;
          _nameController.text = response['produk'] ?? '';
          _priceController.text = response['harga']?.toString() ?? '';
          selectedCategoryId = response['kategori_id']?.toString();
          selectedUnitId = response['unit_id']?.toString();
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Error fetching product details: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _supabase
          .from('category')
          .select()
          .order('kategori', ascending: true);

      if (response != null) {
        setState(() => categories = response);
      }
    } catch (e) {
      _showErrorMessage('Error fetching categories: $e');
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final response =
          await _supabase.from('units').select().order('unit', ascending: true);

      if (response != null) {
        setState(() => units = response);
      }
    } catch (e) {
      _showErrorMessage('Error fetching units: $e');
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      await _supabase.from('products').update({
        'produk': _nameController.text,
        'harga': double.parse(_priceController.text),
        'kategori_id': int.parse(selectedCategoryId!),
        'unit_id': int.parse(selectedUnitId!),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.productId);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      _showErrorMessage('Error updating product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Category',
                      value: selectedCategoryId,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category['id'].toString(),
                          child: Text(category['kategori']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategoryId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Unit',
                      value: selectedUnitId,
                      items: units.map((unit) {
                        return DropdownMenuItem(
                          value: unit['id'].toString(),
                          child: Text(unit['unit']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedUnitId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: productDetail?['foto_produk'] != null
            ? Image.network(
                productDetail!['foto_produk'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40,
                  );
                },
              )
            : const Icon(
                Icons.image,
                color: Colors.grey,
                size: 40,
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: label == 'Price'
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboardType,
      validator: label == 'Price'
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            }
          : validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
    );
  }
}
