import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/screens/admin/users/user_profiles.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userProfiles = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> units = [];
  bool isLoading = true;
  bool isShowAll = false; // Flag untuk menampilkan semua data
  bool isShowAllStats = false;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      await Future.wait([
        fetchUserProfiles(limit: 5),
        fetchProducts(),
        fetchServices(),
        fetchUnits()
      ]);
      setState(() => isLoading = false);
    } catch (e) {
      _showError('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserProfiles({int limit = 5, int offset = 0}) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*, user_id') // Make sure to select user_id explicitly
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response != null) {
        setState(() {
          if (offset == 0) {
            userProfiles = List<Map<String, dynamic>>.from(response);
          } else {
            userProfiles.addAll(List<Map<String, dynamic>>.from(response));
          }
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error fetching user profiles: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          products = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> fetchUnits() async {
    try {
      final response = await supabase
          .from('units')
          .select('*')
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          units = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> fetchServices() async {
    try {
      final response = await supabase
          .from('services')
          .select('*')
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          services = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching services: $e');
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
        // Fetch user details from the 'profiles' table using 'user_id'
        final response = await supabase
            .from('profiles') // Replace with your actual user table name
            .select('name')
            .eq('user_id', user.id) // Use 'user_id' instead of 'id'
            .single();

        final userName = response['name'] ?? 'Unknown';

        // Insert logout activity log
        await supabase.from('activity_logs').insert({
          'user_id': user.id,
          'activity_type': 'logout',
          'description': 'User $userName logged out',
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(screenSize),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsGrid(isTablet, isDesktop),
              const SizedBox(height: 24),
              _buildUserSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    final double toolbarHeight =
        screenSize.height * 0.08; // 8% of screen height
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

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForCard(title),
              color: color,
              size: width * 0.15,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textDarkColor,
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textLightColor,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForCard(String title) {
    switch (title) {
      case 'Jumlah Pengguna':
        return Icons.people_outlined;
      case 'Jumlah Produk':
        return Icons.inventory_2_outlined;
      case 'Jumlah Layanan':
        return Icons.miscellaneous_services_outlined;
      case 'Jumlah Unit Tersedia':
        return Icons.category_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  Widget _buildStatisticsGrid(bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth - (isDesktop ? 48 : 16)) /
            (isDesktop ? 4 : (isTablet ? 3 : 2));
        final cardHeight = cardWidth * 0.8;

        // Basic stats that are always shown
        final List<Widget> basicStats = [
          _buildStatCard(
            'Jumlah Pengguna',
            userProfiles.length.toString(),
            'Total User',
            AppColors.primaryColor,
            cardWidth,
            cardHeight,
          ),
          _buildStatCard(
            'Jumlah Produk',
            products.length.toString(),
            'Total Produk',
            const Color(0xFFDB2777), // Using a more elegant color
            cardWidth,
            cardHeight,
          ),
        ];

        // Additional stats
        final List<Widget> additionalStats = [
          _buildStatCard(
            'Jumlah Layanan',
            services.length.toString(),
            'Total Layanan',
            const Color(0xFF059669), // Using a more elegant color
            cardWidth,
            cardHeight,
          ),
          _buildStatCard(
            'Jumlah Unit Tersedia',
            units.length.toString(),
            'Total Unit',
            const Color(0xFFD97706), // Using a more elegant color
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
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Icon(
                      isShowAllStats
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primaryColor,
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

  Widget _buildUserSection() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.seeUser);
                    },
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFF005BAC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userProfiles.length,
                itemBuilder: (context, index) {
                  final user = userProfiles[index];
                  return _buildUserCard(user);
                },
              ),
            ],
          );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Unnamed User';
    final isActive = user['is_active'] ?? false;
    final roleUser = user['role'] ?? 'N/A';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile Image Section
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user['foto_profile'] != null
                    ? null
                    : const Color(0xFF005BAC),
                image: user['foto_profile'] != null
                    ? DecorationImage(
                        image: NetworkImage(user['foto_profile']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user['foto_profile'] == null
                  ? Center(
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // User Information Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: $roleUser',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Button
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Color(0xFF64748B),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfiles(userId: user['user_id']),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // URL gambar default jika foto profil tidak tersedia
    final defaultProfileImage =
        'https://apjwnjcrgipfmvynrkfr.supabase.co/storage/v1/object/public/profiles/profile-user.png';

    return Drawer(
      backgroundColor: Colors.white,
      child: FutureBuilder<Map<String, dynamic>?>(
        future:
            _getCurrentUserProfile(), // Ambil data profil user yang sedang login
        builder: (context, snapshot) {
          // Tampilkan loading jika data belum siap
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tampilkan pesan error jika terjadi kesalahan
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Ambil foto profil dari data yang di-fetch
          final fotoProfile =
              snapshot.data?['foto_profile'] ?? defaultProfileImage;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          NetworkImage(fotoProfile), // Foto profil dari URL
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Admin Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                  Icons.person_add, 'Tambah User', AppRoutes.addUser),
              _buildDrawerItem(
                  Icons.add_box, 'Tambah Produk', AppRoutes.productPage),
              _buildDrawerItem(
                  Icons.category, 'Tambah Kategori', AppRoutes.addKategori),
              _buildDrawerItem(CupertinoIcons.gear, 'Tambah Services',
                  AppRoutes.seeServices),
              const Divider(),
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

  // Fungsi untuk mengambil data profil user yang sedang login
  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('foto_profile') // Ambil kolom foto_profile
            .eq('user_id', user.id) // Filter berdasarkan user_id
            .single(); // Ambil satu baris data

        return response; // Kembalikan data profil
      }
      return null;
    } catch (e) {
      print('Error mengambil data profil: $e');
      return null;
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF005BAC)),
      title: Text(title),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  int _selectedIndex = 0; // Default ke Admin Dashboard

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
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.addUser);
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
            label: 'Add User',
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
