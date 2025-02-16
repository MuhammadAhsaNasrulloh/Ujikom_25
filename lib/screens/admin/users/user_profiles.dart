import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfiles extends StatefulWidget {
  final String userId;
  const UserProfiles({super.key, required this.userId});

  @override
  State<UserProfiles> createState() => _UserScreenState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _UserScreenState extends State<UserProfiles> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  final supabaseAdmin = SupabaseClient(
    'https://uvrwqhuzjttktlqerruc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cndxaHV6anR0a3RscWVycnVjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODIzMjYzOSwiZXhwIjoyMDUzODA4NjM5fQ.9KkZjb8TZq4f5vIBWsi0GF1ZX-_yqWSyCWeX_J-EQ-Y',
  );
  @override
  void initState() {
    super.initState();
    if (mounted) {
      fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    setState(() => isLoading = true); // Set loading di awal
    try {
      print('Fetching user with ID: ${widget.userId}'); // Debug print

      final userData =
          await supabaseAdmin.auth.admin.getUserById(widget.userId);
      print('User data: $userData'); // Debug print

      if (userData?.user != null) {
        final userProfileData = await _supabase
            .from('profiles')
            .select('*')
            .eq('user_id', widget.userId)
            .maybeSingle();
        print('Profile data: $userProfileData'); // Debug print

        if (userProfileData != null) {
          setState(() {
            userProfile = {
              ...userProfileData,
              'email': userData.user?.email,
              
            };
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showError('Profile not found');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showError('User not found');
      }
    } catch (e) {
      print('Error in fetchUserProfile: $e'); // Debug print
      setState(() => isLoading = false);
      _showError('Error fetching user profile: $e');
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

   Future<List<Map<String, dynamic>>> _fetchUserActivityLogs() async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('*')
          .eq('user_id', widget.userId)
          .order('timestamp', ascending: false)
          .limit(10);

      if (response.isEmpty) {
        return [];
      }

      return response;
    } catch (e) {
      print('Error fetching activity logs: $e');
      return [];
    }
  }

  void _logDebug(String message) {
    debugPrint('🔧 DEBUG: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildProfileDetails(),
                      const SizedBox(height: 24),
                      _buildActivitySection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: userProfile?['foto_profile'] != null
                  ? null
                  : AppColors.primaryColor,
              image: userProfile?['foto_profile'] != null
                  ? DecorationImage(
                      image: NetworkImage(userProfile!['foto_profile']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: userProfile?['foto_profile'] == null
                ? Center(
                    child: Text(
                      (userProfile?['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile?['name'] ?? 'Unnamed User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile?['role'] ?? 'No Role',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textLightColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (userProfile?['is_active'] ?? false)
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (userProfile?['is_active'] ?? false)
                        ? 'Active'
                        : 'Inactive',
                    style: TextStyle(
                      color: (userProfile?['is_active'] ?? false)
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailItem('Email', userProfile?['email'] ?? 'No email'),
          _buildDetailItem(
            'Member Since',
            _formatDate(userProfile?['created_at']),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkColor,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUserActivityLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(
                      color: AppColors.textLightColor,
                      fontSize: 16,
                    ),
                  ),
                );
              } else {
                final activities = snapshot.data!;
                return Column(
                  children: activities.map((activity) {
                    return ListTile(
                      title: Text(activity['description'] ?? 'No description'),
                      subtitle: Text(_formatDate(activity['timestamp'])),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLightColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDarkColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
