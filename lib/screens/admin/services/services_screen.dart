import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/screens/admin/services/services_detail.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
  static const Color cardColor = Colors.white;
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDataServices();
  }

  Future<void> _fetchDataServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .order('created_at', ascending: false);
      setState(() {
        _services = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(
                  child: Text(
                    'No services available',
                    style: TextStyle(
                        fontSize: 18, color: AppColors.textLightColor),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul "Daftar Layanan" di atas list
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Daftar Layanan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDarkColor,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return _buildCardServices(service);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCardServices(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesDetail(servicesId: service['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dummy image icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_laundry_service,
                  size: 32, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['layanan'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durasi Pengerjaan : ${service['durasi']} Hari',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textLightColor,
                    ),
                  ),
                  Text(
                    'Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(service['harga_layanan'])}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLightColor,
                    ),
                  )
                ],
              ),
            ),
          ],
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
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addServices),
          icon: const Icon(Icons.add_circle_outline_outlined,
              color: Colors.white),
        ),
      ],
    );
  }
}
