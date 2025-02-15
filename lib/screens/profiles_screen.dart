import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final data = await getCurrentUserData();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userProfile = await _supabase
            .from('profiles')
            .select('*')
            .eq('user_id', user.id)
            .single();

        final userData = {
          'id': user.id,
          'email': user.email,
          'phone': user.phone,
          'emailConfirmed': user.emailConfirmedAt,
          'lastSignInAt': user.lastSignInAt,
          ...userProfile,
        };
        return userData;
      }
      return null;
    } catch (e) {
      print('Error mengambil data user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userDataResponse = await _supabase
            .from('profiles')
            .select('name')
            .eq('user_id', user.id)
            .single();

        String userName = userDataResponse['name'] ?? 'Unknown User';
        await logActivity('logout', 'User $userName logged out');
      }
      await _supabase.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name as needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> logActivity(String action, String description) async {
    try {
      await _supabase.from('activity_logs').insert({
        'action': action,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> _showSignOutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF718096)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4299E1),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4299E1),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: userData?['foto_profile'] != null
                                    ? Image.network(
                                        userData?['foto_profile'],
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData?['name'] ?? 'John Doe',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData?['email'] ?? 'email@example.com',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // Personal Information Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoItem(
                                CupertinoIcons.person_crop_rectangle,
                                'User ID',
                                userData?['user_id'] ?? 'N/A',
                              ),
                              const Divider(height: 1),
                              _buildInfoItem(
                                Icons.calendar_today_outlined,
                                'Joined',
                                _formatDate(userData?['created_at']),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Sign Out Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showSignOutDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4299E1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}