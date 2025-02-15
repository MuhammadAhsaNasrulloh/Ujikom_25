import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = supabase.auth.currentUser;
        if (user == null) {
          throw Exception('User tidak terautentikasi');
        }

        final userData = await supabase
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (userData == null) {
          throw Exception('Data user tidak ditemukan');
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
          Navigator.pop(context, true);
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
        backgroundColor: const Color(0xFF005BAC),
        title: const Text(
          'Tambah Kategori',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005BAC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
