import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/services/auth_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);

  final supabaseAdmin = SupabaseClient(
    'https://uvrwqhuzjttktlqerruc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cndxaHV6anR0a3RscWVycnVjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODIzMjYzOSwiZXhwIjoyMDUzODA4NjM5fQ.9KkZjb8TZq4f5vIBWsi0GF1ZX-_yqWSyCWeX_J-EQ-Y',
  );

  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> userProfiles = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = userProfiles;
      } else {
        filteredUsers = userProfiles
            .where((user) =>
                user['name'].toLowerCase().contains(query.toLowerCase()) ||
                user['role'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Debug logging function
  void _logDebug(String message) {
    debugPrint('🔧 DEBUG: $message');
  }

  // Error logging function
  void _logError(String message, dynamic error) {
    debugPrint('❌ ERROR: $message');
    debugPrint('Error details: $error');
    if (error is PostgrestException) {
      debugPrint('Postgrest Error Code: ${error.code}');
      debugPrint('Postgrest Error Message: ${error.message}');
      debugPrint('Postgrest Error Details: ${error.details}');
    }
  }

  Future<void> fetchUsers() async {
    try {
      _logDebug('Fetching users...');
      setState(() => isLoading = true);

      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        setState(() {
          userProfiles = List<Map<String, dynamic>>.from(response);
          filteredUsers = userProfiles;
          isLoading = false;
        });
        _logDebug('Users fetched successfully. Count: ${userProfiles.length}');
      } else {
        throw 'No data received from profiles table';
      }
    } catch (e) {
      _logError('Error in fetchUsers', e);
      _showError('Error fetching users: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUserAuth(String userId,
      {String? email, String? password}) async {
    try {
      _logDebug('Updating auth user with ID: $userId');

      // Create updates object
      Map<String, dynamic> updates = {};
      if (email != null) updates['email'] = email;
      if (password != null) updates['password'] = password;

      if (updates.isEmpty) {
        _showError('No updates provided');
        return;
      }

      // Update auth.users using admin client
      final response = await supabaseAdmin.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(
          email: email,
          password: password,
        ),
      );

      if (response.user != null) {
        _logDebug('Auth user updated successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User authentication details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logError('Error in updateUserAuth', e);
      _showError('Error updating user authentication: ${e.toString()}');
    }
  }

  Future<void> updateUser(
      String profileId, Map<String, dynamic> updates) async {
    try {
      _logDebug('Updating user with ID: $profileId');
      _logDebug('Updates to apply: $updates');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await supabase
          .from('profiles')
          .update(updates)
          .eq('id', profileId)
          .select();

      _logDebug('Update response received: $response');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response != null) {
        await fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _logDebug('User updated successfully');
      } else {
        throw 'Failed to update user';
      }
    } catch (e) {
      _logError('Error in updateUser', e);
      if (mounted) {
        Navigator.pop(context);
        _showError('Error updating user: ${e.toString()}');
      }
    }
  }

  Future<void> toggleUserActivation(String profileId, String userId) async {
    try {
      _logDebug('Starting activation toggle for profileId: $profileId');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        _showError('Gagal mendapatkan informasi pengguna');
        return;
      }

      // Cegah admin menonaktifkan dirinya sendiri
      if (currentUser.id == userId) {
        _showError('Anda tidak bisa menonaktifkan akun Anda sendiri!');
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Step 1: Fetch current status
      _logDebug('Fetching current user status...');
      final userDataResponse = await supabase
          .from('profiles')
          .select('is_active, id')
          .eq('id', profileId)
          .maybeSingle();

      _logDebug('Current user data: $userDataResponse');

      if (userDataResponse == null) {
        if (mounted) Navigator.pop(context);
        _showError('User not found');
        return;
      }

      final bool currentStatus = userDataResponse['is_active'] ?? false;
      final bool newStatus = !currentStatus;

      _logDebug('Current status: $currentStatus, New status: $newStatus');

      // Step 2: Perform update
      _logDebug('Attempting to update status...');
      try {
        await supabase.from('profiles').update({
          'is_active': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', profileId);

        _logDebug('Update completed');
      } catch (updateError) {
        _logDebug('Error during update operation: $updateError');
        throw Exception('Database update failed: $updateError');
      }

      // Step 3: Verify update
      final verificationResponse = await supabase
          .from('profiles')
          .select('is_active, id')
          .eq('id', profileId)
          .maybeSingle();

      _logDebug('Verification response: $verificationResponse');

      if (verificationResponse == null ||
          verificationResponse['is_active'] != newStatus) {
        _logDebug(
            'Verification failed - Expected: $newStatus, Got: ${verificationResponse?['is_active']}');
        throw Exception('Status update failed verification');
      }

      // Step 4: Log activity
      await authService.logActivity(
        'USER_STATUS_UPDATE',
        'User dengan ID $userId ${newStatus ? "diaktifkan" : "dinonaktifkan"} oleh admin',
      );

      // Step 5: Show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'User berhasil diaktifkan'
                : 'User berhasil dinonaktifkan'),
            backgroundColor: newStatus ? Colors.green : Colors.red,
          ),
        );
      }

      // Step 6: Refresh users
      await fetchUsers();
      _logDebug('Toggle operation completed successfully');
    } catch (e) {
      _logDebug('Final error caught: $e');
      if (mounted) Navigator.pop(context);
      _logError('Error in toggleUserActivation', e);
      _showError('Gagal mengubah status user: ${e.toString()}');
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

  // Fungsi untuk memilih gambar dari galeri
  Future<File?> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Fungsi untuk mengunggah gambar ke Supabase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'foto_profiles/$fileName';

      await supabase.storage.from('foto_profiles').upload(filePath, image);
      return supabase.storage.from('foto_profiles').getPublicUrl(filePath);
    } catch (e) {
      _logError('Error uploading image', e);
      return null;
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['name']);
    final roleController = TextEditingController(text: user['role']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    File? selectedImage;
    String? newImageUrl;

    _logDebug('Opening edit dialog for user: ${user['name']}');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final image = await _pickImage();
                  if (image != null) {
                    setState(() => selectedImage = image);
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (user['foto_profile'] != null
                          ? NetworkImage(user['foto_profile'])
                          : const AssetImage(
                              'assets/images/logo-login.png')) as ImageProvider,
                  child: selectedImage == null && user['foto_profile'] == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password (leave empty to keep current)',
                  helperText: 'Minimum 6 characters',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: roleController.text,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['owner', 'kasir', 'admin'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => roleController.text = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedImage != null) {
                newImageUrl = await _uploadImage(selectedImage!);
                if (newImageUrl == null) {
                  _showError('Gagal mengunggah gambar');
                  return;
                }
              }

              Navigator.pop(context);
              final profileUpdates = {
                'name': nameController.text,
                'role': roleController.text,
              };

              if (newImageUrl != null) {
                profileUpdates['foto_profile'] = newImageUrl ??
                    'https://apjwnjcrgipfmvynrkfr.supabase.co/storage/v1/object/public/profiles/profile-user.png';
              }
              await updateUser(user['id'], profileUpdates);

              // Update auth user if email or password changed
              if (emailController.text != user['email'] ||
                  passwordController.text.isNotEmpty) {
                await updateUserAuth(
                  user['user_id'],
                  email: emailController.text != user['email']
                      ? emailController.text
                      : null,
                  password: passwordController.text.isNotEmpty
                      ? passwordController.text
                      : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAC),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(String profileId, String userId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menonaktifkan user ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await toggleUserActivation(profileId, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Nonaktifkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      iconTheme: IconThemeData(color: backgroundColor),
      title: const Text(
        'Data Users',
        style: TextStyle(
          color: backgroundColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: backgroundColor),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addUser)
                  .then((_) => fetchUsers());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(Size screenSize, bool isTablet, bool isDesktop) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(screenSize),
            const SizedBox(
              height: 16,
            ),
            _buildUserList(screenSize, isTablet, isDesktop),
          ],
        ),
      ),
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
        onChanged: _filterUsers,
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
                  user['role']?.toUpperCase() ?? 'NO ROLE',
                  style: TextStyle(
                    color: textLightColor,
                    fontSize: screenSize.width * 0.03,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  user['is_active'] == true ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color:
                        user['is_active'] == true ? Colors.green : Colors.red,
                    fontSize: screenSize.width * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: primaryColor,
                  size: screenSize.width * 0.045,
                ),
                onPressed: () => _showEditDialog(user),
              ),
              IconButton(
                icon: Icon(
                  user['is_active'] == true ? Icons.block : Icons.check_circle,
                  color: user['is_active'] == true ? Colors.red : Colors.green,
                  size: screenSize.width * 0.045,
                ),
                onPressed: () => _showConfirmationDialog(
                  user['id'] ?? '',
                  user['user_id'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushNamed(context, AppRoutes.adminDashboard);
        } else if (index == 1) {
          Navigator.pushNamed(context, AppRoutes.activityLog);
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.profilePage);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      selectedItemColor: const Color(0xFF005BAC),
      unselectedItemColor: Colors.grey,
    );
  }
}
