import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/models/services.dart';
import 'package:waixilaundry/screens/admin/log/log_screen.dart';

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
  final _durasiController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _layananController.dispose();
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
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tambah Layanan'),
              _buildTextField(_layananController, 'Nama Layanan',
                  isRequired: true),
              _buildTextField(_durasiController, 'Durasi waktu',
                  keyboardType: TextInputType.number),
              _buildTextField(_priceController, 'Harga',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildSectionTitle('Tambah Unit'),
              _buildTextField(_unitController, 'Nama Unit'),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isRequired = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        keyboardType: keyboardType,
        validator: isRequired
            ? (value) => value!.isEmpty ? '$labelText tidak boleh kosong' : null
            : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Tambah Data',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }
}
