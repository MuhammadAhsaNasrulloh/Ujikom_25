import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/screens/owner/transaction_detail.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactionData = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUserProfile;
  bool isShowAllStats = false;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
    fetchCurrentUserProfile();
  }

  Future<void> fetchCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          currentUserProfile =
              response ?? {}; // Gunakan map kosong jika response null
        });
      }
    } catch (e) {
      _showError('Error fetching user profile: $e');
      setState(() {
        currentUserProfile = {}; // Gunakan map kosong jika terjadi error
      });
    }
  }

  Future<void> fetchTransactions({int limit = 5, int offset = 0}) async {
    try {
      final response = await supabase
          .from('transactions')
          .select('''
            id, kode_unik, kasir_id, pelanggan_id, 
            bayar, kembalian, is_deleted, created_at, 
            updated_at, total_harga, 
            detail_transaction!inner(status), 
            profiles(name), pelanggans(nama_pelanggan)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response != null) {
        setState(() {
          final List<Map<String, dynamic>> transactions =
              List<Map<String, dynamic>>.from(response);

          for (var transaction in transactions) {
            final detailTransaction = transaction['detail_transaction'];
            if (detailTransaction is List && detailTransaction.isNotEmpty) {
              transaction['status'] = detailTransaction[0]['status'] as String;
            } else {
              transaction['status'] = 'pending';
            }
          }

          offset == 0
              ? transactionData = transactions
              : transactionData.addAll(transactions);
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error fetching transactions: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> logActivity(String activityType, String description) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('activity_logs').insert({
          'user_id': user.id,
          'activity_type': activityType,
          'description': description,
        });
      }
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('activity_logs').insert({
          'user_id': user.id,
          'activity_type': 'logout',
          'description': 'Owner logged out',
        });
      }
      await supabase.auth.signOut();
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      _showError('Failed to log out: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isTablet = screenSize.width >= 600;
    final isDesktop = screenSize.width >= 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(screenSize),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: _buildResponsiveBody(
          isTablet: isTablet,
          isDesktop: isDesktop,
          horizontalPadding: screenSize.width * 0.04,
          verticalPadding: screenSize.height * 0.02,
        ),
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomAppBar(context) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    final double toolbarHeight =
        screenSize.height * 0.08; // 8% of screen height
    final now = DateTime.now();

    return AppBar(
      backgroundColor: primaryColor,
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

  Widget _buildResponsiveBody({
    required bool isTablet,
    required bool isDesktop,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsGrid(isTablet, isDesktop),
                  SizedBox(height: verticalPadding * 1.5),
                  _buildTransactionSection(isTablet, isDesktop),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _getCompletedOrdersCount() {
    return transactionData
        .where((transaction) => transaction['status'] == 'diterima')
        .length;
  }

  int _getPendingOrdersCount() {
    return transactionData
        .where((transaction) => transaction['status'] == 'pending')
        .length;
  }

  Widget _buildStatisticsGrid(bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate sizes based on available width
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth - (isDesktop ? 48 : 16)) /
            (isDesktop ? 4 : (isTablet ? 3 : 2));
        final cardHeight = cardWidth * 0.8;

        // Basic stats that are always shown
        final List<Widget> basicStats = [
          _buildStatCard(
            'Active Orders',
            '${transactionData.length}',
            Icons.assignment_outlined,
            const Color(0xFFECFDF5),
            const Color(0xFF059669),
            cardWidth,
            cardHeight,
          ),
          _buildStatCard(
            'Total Revenue',
            'Rp ${_calculateTotalRevenue()}',
            Icons.account_balance_wallet_outlined,
            const Color(0xFFEFF6FF),
            const Color(0xFF3B82F6),
            cardWidth,
            cardHeight,
          ),
        ];

        // Additional stats
        final List<Widget> additionalStats = [
          _buildStatCard(
            'Completed Orders',
            '${_getCompletedOrdersCount()}',
            Icons.check_circle_outline,
            const Color(0xFFFDF2F8),
            const Color(0xFFDB2777),
            cardWidth,
            cardHeight,
          ),
          _buildStatCard(
            'Pending Orders',
            '${_getPendingOrdersCount()}',
            Icons.pending_outlined,
            const Color(0xFFFEF3C7),
            const Color(0xFFD97706),
            cardWidth,
            cardHeight,
          ),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ...basicStats,
                  if (isTablet || isDesktop || isShowAllStats)
                    ...additionalStats,
                ],
              ),
            ),
            if (!isTablet && !isDesktop) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    isShowAllStats = !isShowAllStats;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isShowAllStats ? 'Show Less' : 'Show All Statistics',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: primaryColor,
                      ),
                    ),
                    Icon(
                      isShowAllStats
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _calculateTotalRevenue() {
    double total = transactionData.fold(
      0,
      (sum, transaction) => sum + (transaction['total_harga'] ?? 0),
    );
    return total.toStringAsFixed(0);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.06),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: width * 0.15,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: textDarkColor,
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: textLightColor,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: textDarkColor,
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.ownerTransaksi);
              },
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactionData.take(5).length,
          itemBuilder: (context, index) => _buildTransactionItem(
            transactionData[index],
            isTablet,
            isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> transaction,
    bool isTablet,
    bool isDesktop,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final amount = transaction['total_harga'] ?? 0.0;
    final status = transaction['status'] ?? 'pending';
    final kodeUnik = transaction['kode_unik'] ?? 'Unknown';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailOwner(transaksi: transaction),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
        padding: EdgeInsets.all(screenSize.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_outlined,
                color: primaryColor,
                size: screenSize.width * 0.05,
              ),
            ),
            SizedBox(width: screenSize.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order $kodeUnik',
                    style: TextStyle(
                      color: textDarkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    status,
                    style: TextStyle(
                      color:
                          status == 'diterima' ? Colors.green : Colors.orange,
                      fontSize: screenSize.width * 0.03,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: screenSize.width * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDrawer(BuildContext context) {
    const defaultProfileImage =
        'https://apjwnjcrgipfmvynrkfr.supabase.co/storage/v1/object/public/profiles/profile-user.png';

    return Drawer(
      backgroundColor: Colors.white,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final fotoProfile =
              snapshot.data?['foto_profile'] ?? defaultProfileImage;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: primaryColor,
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
                      'Owner Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.bar_chart, 'Laporan Keuangan',
                  AppRoutes.transactionReport),
              _buildDrawerItem(CupertinoIcons.cube_box, 'Data Produk',
                  AppRoutes.kasirProduct),
              _buildDrawerItem(
                  Icons.people, 'Manajemen Staff', AppRoutes.manageUser),
              _buildDrawerItem(
                  Icons.history, 'Log Aktivitas', AppRoutes.activityLog),
              Divider(color: Colors.grey.withOpacity(0.2)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
      leading: Icon(icon, color: const Color(0xFF005BAC)),
      title: Text(title),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      backgroundColor: Colors.white, // Tambahkan warna latar belakang di sini
      onTap: (index) {
        if (index == 1) {
          Navigator.pushNamed(context, AppRoutes.ownerDashboard);
        } else if (index == 0) {
          Navigator.pushNamed(context, AppRoutes.activityLog);
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.profilePage);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_outlined),
          label: 'Profile',
        ),
      ],
      selectedItemColor: Color(0xFF005BAC),
      unselectedItemColor: Colors.grey,
    );
  }
}
