import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/screens/admin/category/category_detail.dart';
import 'package:waixilaundry/screens/dashboard/admin_dashboard.dart';

class AddKategori extends StatefulWidget {
  const AddKategori({super.key});

  @override
  State<AddKategori> createState() => _AddKategoriState();
}

class _AddKategoriState extends State<AddKategori> {
  final _formKey = GlobalKey<FormState>();
  final _kategoriController = TextEditingController();
  bool _isLoading = false;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchDataKategori(); // Panggil fungsi untuk mengambil data kategori
  }

  Future<void> _fetchDataKategori() async {
    try {
      final response = await supabase
          .from('category')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = supabase.auth.currentUser;
        if (user == null) {
          throw Exception('User tidak terautentikasi');
        }

        final now = DateTime.now().toIso8601String();

        await supabase.from('category').insert({
          'kategori': _kategoriController.text,
          'created_at': now,
          'updated_at': now,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil ditambahkan')),
          );
          _kategoriController.clear();
          _fetchDataKategori(); // Refresh data setelah menambah kategori
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _kategoriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Tambah Kategori',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _kategoriController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      hintText: 'Masukkan nama kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama kategori tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity, // Set your desired width
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(
                              200, 50), // Set button width and height
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Use the minimum width for the children
                                children: const [
                                  Icon(Icons.save,
                                      color: Colors.white), // Add icon
                                  SizedBox(
                                      width:
                                          8), // Add spacing between icon and text
                                  Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ))
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Daftar Kategori:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _categories.isEmpty
                  ? const Center(child: Text('Belum ada kategori'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryDetailPage(
                                  categoryId: category['id']
                                      .toString(), // Extract and convert the id to String
                                ),
                              ),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(category['kategori']),
                              subtitle: Text(
                                  'Dibuat pada: ${category['created_at']}'),
                            ),
                          ),
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
