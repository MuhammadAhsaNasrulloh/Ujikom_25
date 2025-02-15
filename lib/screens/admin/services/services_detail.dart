import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicesDetail extends StatefulWidget {
  final dynamic servicesId;
  const ServicesDetail({super.key, required this.servicesId});

  @override
  State<ServicesDetail> createState() => _ServicesDetailState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFDC2626);
}

class _ServicesDetailState extends State<ServicesDetail> {
  final _supabase = Supabase.instance.client;
  final _layananController = TextEditingController();
  final _durasiController = TextEditingController();
  final _hargaController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
  }

  Future<void> _fetchServiceDetail() async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('id', widget.servicesId)
          .single();
      
      setState(() {
        _layananController.text = response['layanan'];
        _durasiController.text = response['durasi'].toString();
        _hargaController.text = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(response['harga_layanan']).replaceAll('Rp ', '');
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching service detail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateService() async {
    try {
      final harga = int.parse(_hargaController.text.replaceAll('.', ''));
      
      await _supabase.from('services').update({
        'layanan': _layananController.text,
        'durasi': int.parse(_durasiController.text),
        'harga_layanan': harga,
      }).eq('id', widget.servicesId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Layanan berhasil diperbarui'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Gagal memperbarui layanan'),
              ],
            ),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              label: 'Nama Layanan',
                              controller: _layananController,
                              icon: Icons.business_center,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Durasi (Hari)',
                              controller: _durasiController,
                              icon: Icons.timer,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Harga Layanan',
                              controller: _hargaController,
                              icon: Icons.money,
                              keyboardType: TextInputType.number,
                              prefix: 'Rp ',
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final number = int.parse(value.replaceAll('.', ''));
                                  final formattedNumber = NumberFormat('#,###', 'id_ID')
                                      .format(number)
                                      .replaceAll(',', '.');
                                  _hargaController.value = TextEditingValue(
                                    text: formattedNumber,
                                    selection: TextSelection.collapsed(
                                      offset: formattedNumber.length,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save, color: AppColors.backgroundColor,),
                            SizedBox(width: 8),
                            Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefix,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: prefix,
            prefixIcon: Icon(icon, color: AppColors.textLightColor),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detail Layanan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  void dispose() {
    _layananController.dispose();
    _durasiController.dispose();
    _hargaController.dispose();
    super.dispose();
  }
}