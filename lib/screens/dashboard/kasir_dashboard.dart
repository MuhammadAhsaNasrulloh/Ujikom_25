import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:flutter/cupertino.dart';
import 'package:waixilaundry/screens/kasir/detail_transaksi.dart';

class KasirDashboard extends StatefulWidget {
  const KasirDashboard({super.key});

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _KasirDashboardState extends State<KasirDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactionData = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions({int limit = 5, int offset = 0}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await supabase
          .from('transactions')
          .select('''
            *,
            profiles (id, name),
            pelanggans (id, nama_pelanggan, alamat, no_hp),
            detail_transaction (
              id, status, qty,
              products (id, produk, harga),
              services (id, layanan, harga_layanan),
              units (id, unit)
            )
          ''')
          .eq('is_deleted', false)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (mounted) {
        setState(() {
          transactionData = offset == 0 
            ? List<Map<String, dynamic>>.from(response)
            : [...transactionData, ...List<Map<String, dynamic>>.from(response)];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
        setState(() => isLoading = false);
      }
    }
  }


 @override
   Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(screenSize),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () => fetchTransactions(),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildRevenueCard(),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ))
            else if (transactionData.isEmpty)
              Center(
                child: Text(
                  'Belum ada transaksi hari ini',
                  style: TextStyle(
                    color: AppColors.textLightColor,
                    fontSize: 16,
                  ),
                ),
              )
            else
              ...transactionData.map(_transactionCard).toList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
    );
  }

 PreferredSizeWidget _buildAppBar(Size screenSize) {
    final double toolbarHeight = screenSize.height * 0.08; // 8% of screen height
    final now = DateTime.now();

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
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${now.day} ${_getMonth(now.month)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.width * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

 Widget _buildRevenueCard() {
    final totalRevenue = transactionData.fold<double>(
      0,
      (sum, transaction) => sum + ((transaction['total_harga'] ?? 0) as num).toDouble(),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pendapatan Hari Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rp ${NumberFormat('#,###').format(totalRevenue)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

   Widget _transactionCard(Map<String, dynamic> transaction) {
    final pelanggan = transaction['pelanggans'] as Map<String, dynamic>? ?? {};
    final details = transaction['detail_transaction'] as List<dynamic>? ?? [];
    final status = details.isNotEmpty ? details.first['status'] ?? 'Unknown' : 'Unknown';
    final statusColor = status == 'diterima' ? Colors.green : Colors.orange;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailTransaksi(transaksi: transaction),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode: ${transaction['kode_unik'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDarkColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • HH:mm').format(
                              DateTime.parse(transaction['created_at'] ?? ''),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 16),
                _buildDetailRow('Pelanggan', pelanggan['nama_pelanggan'] ?? 'Tidak Diketahui'),
                _buildDetailRow(
                  'Total',
                  'Rp${NumberFormat('#,###').format(transaction['total_harga'] ?? 0)}',
                  isTotal: true,
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'Detail:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...details.take(2).map((detail) {
                    final product = detail['products'] as Map<String, dynamic>? ?? {};
                    final service = detail['services'] as Map<String, dynamic>? ?? {};
                    final unit = detail['units'] as Map<String, dynamic>? ?? {};

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product['produk'] ?? '-'} (${service['layanan'] ?? '-'})',
                            style: TextStyle(color: AppColors.textDarkColor),
                          ),
                          Text(
                            '  ${detail['qty']?.toString() ?? '0'} ${unit['unit'] ?? '-'}',
                            style: TextStyle(color: AppColors.textLightColor),
                          ),
                          Text(
                            '  Status: ${detail['status'] ?? 'pending'}',
                            style: TextStyle(color: AppColors.textLightColor),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (details.length > 2)
                    Text(
                      '... dan ${details.length - 2} item lainnya',
                      style: TextStyle(color: AppColors.textLightColor),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textLightColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textDarkColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
    Widget _buildDrawer(BuildContext context) {
    const defaultProfileImage = 'https://apjwnjcrgipfmvynrkfr.supabase.co/storage/v1/object/public/profiles/profile-user.png';

    return Drawer(
      backgroundColor: Colors.white,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          final fotoProfile = snapshot.data?['foto_profile'] ?? defaultProfileImage;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(fotoProfile),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kasir Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(CupertinoIcons.doc_plaintext, 'Pesanan', AppRoutes.historiTransaksi),
              _buildDrawerItem(CupertinoIcons.cube_box, 'Data Produk', AppRoutes.kasirProduct),
              _buildDrawerItem(Icons.history, 'Log Aktivitas', AppRoutes.activityLog),
              Divider(color: Colors.grey.withOpacity(0.2)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: signOut,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textDarkColor),
      ),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
  Future<void> signOut() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('activity_logs').insert({
          'user_id': user.id,
          'activity_type': 'logout',
          'description': 'User logged out',
        });
      }
      
      await supabase.auth.signOut();
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('is_logged_in');

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      _showError('Gagal logout: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        return await supabase
            .from('profiles')
            .select('foto_profile')
            .eq('user_id', user.id)
            .single();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

   Widget _buildBottomAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              Navigator.pushNamed(context, AppRoutes.kasirDashboard);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.transaction);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.profilePage);
              break;
          }
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textLightColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}