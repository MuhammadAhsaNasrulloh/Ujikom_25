import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waixilaundry/config/route.dart';

class ManageUser extends StatefulWidget {
  const ManageUser({super.key});

  @override
  State<ManageUser> createState() => _ManageUserState();
}

class _ManageUserState extends State<ManageUser> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> dataUser = [];
  List<Map<String, dynamic>> filteredUsers = [];
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDataUsers();
  }

  Future<void> _fetchDataUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          dataUser = List<Map<String, dynamic>>.from(response);
          filteredUsers = dataUser;
          isLoading = false;
        });
        _logDebug('Users fetched successfully. Count: ${dataUser.length}');
      } else {
        throw 'No data received from profiles table';
      }
    } catch (e) {
      _logError('Error in fetchUsers', e);
      _showError('Error fetching users: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  void _logDebug(String message) {
    debugPrint('🔧 DEBUG: $message');
  }

  void _logError(String message, dynamic error) {
    debugPrint('❌ ERROR: $message');
    debugPrint('Error details: $error');
    if (error is PostgrestException) {
      debugPrint('Postgrest Error Code: ${error.code}');
      debugPrint('Postgrest Error Message: ${error.message}');
      debugPrint('Postgrest Error Details: ${error.details}');
    }
  }

  void _showError(String message) {
    _logDebug('Showing error message: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = dataUser;
      } else {
        filteredUsers = dataUser
            .where((user) =>
                user['name'].toLowerCase().contains(query.toLowerCase()) ||
                user['role'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isTablet = screenSize.width >= 600;
    final isDesktop = screenSize.width >= 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(screenSize, isTablet, isDesktop),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      title: Text(
        'Data Users',
        style: TextStyle(
          color: backgroundColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'BuckinDemiBold'
        ),
      ),
      iconTheme: IconThemeData(color: backgroundColor),
    );
  }

  Widget _buildBody(Size screenSize, bool isTablet, bool isDesktop) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(screenSize),
                SizedBox(height: screenSize.height * 0.02),
                _buildUserList(screenSize, isTablet, isDesktop),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: TextStyle(color: textLightColor),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: textLightColor),
        ),
        onChanged: _filterUsers, // Setiap ketik, langsung filter
      ),
    );
  }

  Widget _buildUserList(Size screenSize, bool isTablet, bool isDesktop) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, screenSize, isTablet, isDesktop);
      },
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    Size screenSize,
    bool isTablet,
    bool isDesktop,
  ) {
    final defaultProfileImage =
        'https://apjwnjcrgipfmvynrkfr.supabase.co/storage/v1/object/public/profiles/profile-user.png';

    return Container(
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
          CircleAvatar(
            radius: screenSize.width * 0.06,
            backgroundImage: NetworkImage(
              user['foto_profile'] ?? defaultProfileImage,
            ),
          ),
          SizedBox(width: screenSize.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: TextStyle(
                    color: textDarkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  user['role'] ?? 'No Role',
                  style: TextStyle(
                    color: textLightColor,
                    fontSize: screenSize.width * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
