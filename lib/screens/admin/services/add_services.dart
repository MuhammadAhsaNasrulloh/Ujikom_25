import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/models/services.dart';

class AddServices extends StatefulWidget {
  const AddServices({super.key});

  @override
  State<AddServices> createState() => _AddServicesState();
}

class _AddServicesState extends State<AddServices> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controller untuk form input
  final _layananController = TextEditingController();
  final _estimasiController = TextEditingController();
  final _durasiController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _layananController.dispose();
    _estimasiController.dispose();
    _durasiController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _addData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = Service(
        layanan: _layananController.text,
        durasi: _durasiController.text.isNotEmpty
            ? int.parse(_durasiController.text)
            : null,
        estimasi: _estimasiController.text.isNotEmpty
            ? _estimasiController.text
            : null,
        harga: _priceController.text.isNotEmpty
            ? int.parse(_priceController.text)
            : 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );


      await supabase.from('services').insert(service.toMap());

      if (_unitController.text.isNotEmpty) {
        await supabase.from('units').insert({'unit': _unitController.text});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil ditambahkan!')),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tambah Layanan & Unit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF005BAC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Layanan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _layananController,
                decoration: const InputDecoration(
                    labelText: 'Nama Layanan', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? 'Nama layanan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _durasiController,
                decoration: const InputDecoration(
                    labelText: 'Durasi waktu', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _estimasiController,
                decoration: const InputDecoration(
                    labelText: 'Estimasi (hari/minggu)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Text('Tambah Unit',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                    labelText: 'Nama Unit', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _addData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005BAC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tambah Data',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
