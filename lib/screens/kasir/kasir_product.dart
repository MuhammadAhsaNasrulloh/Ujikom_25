import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KasirProduct extends StatefulWidget {
  const KasirProduct({super.key});

  @override
  State<KasirProduct> createState() => _KasirProductState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _KasirProductState extends State<KasirProduct> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> filteredProducts = [];
  String? selectedCategoryId;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProducts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchQuery = searchController.text.toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products.where((product) {
          final productName = product['produk'].toString().toLowerCase();
          final category = product['kategori']?['kategori'].toString().toLowerCase() ?? '';
          return productName.contains(searchQuery) || category.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> fetchCategories() async {
    try {
      final response = await supabase
          .from('category')
          .select('id, kategori')
          .order('kategori', ascending: true);

      if (response is List) {
        setState(() {
          categories = response;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  Future<void> fetchProducts() async {
    try {
      setState(() => isLoading = true);

      var query = supabase.from('products').select('''
          id, 
          produk, 
          kategori_id, 
          unit_id,
          foto_produk, 
          harga, 
          created_at, 
          updated_at,
          kategori: category(kategori), 
          unit: units(unit)
        ''');

      if (selectedCategoryId != null) {
        query = query.eq('kategori_id', int.parse(selectedCategoryId!));
      }

      final response = await query.order('created_at', ascending: false);

      if (response is List) {
        setState(() {
          products = response;
          filteredProducts = response; // Initialize filtered products
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: fetchProducts,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildSearchField(), // Changed from _buildSearchBar()
            const SizedBox(height: 20),
            _buildCategoryFilter(),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            else if (filteredProducts.isEmpty)
              Center(
                child: Text(
                  'Tidak ada produk ditemukan',
                  style: TextStyle(
                    color: AppColors.textLightColor,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ...filteredProducts.map(_buildProductCard).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLightColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkColor,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
            ),
            value: selectedCategoryId,
            hint: const Text('Semua Kategori'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua Kategori'),
              ),
              ...categories.map((category) {
                return DropdownMenuItem<String?>(
                  value: category['id'].toString(),
                  child: Text(category['kategori']),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value;
              });
              fetchProducts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['produk'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Kategori', product['kategori']?['kategori'] ?? 'N/A'),
                  _buildInfoRow('Unit', product['unit']?['unit'] ?? 'N/A'),
                  const SizedBox(height: 8),
                  _buildPriceRow(product['harga'] ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic product) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: product['foto_produk'] != null
            ? Image.network(
                product['foto_produk'],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLightColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDarkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(num price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Rp${NumberFormat('#,###').format(price)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Waixi Laundry',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'BuckinDemiBold',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: fetchProducts,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }
}