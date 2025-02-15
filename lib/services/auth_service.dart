import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  // Konversi UTC ke WIB
  static DateTime utcToLocal(String utcTime) {
    DateTime utcDate = DateTime.parse(utcTime);
    return utcDate.add(const Duration(hours: 7));
  }

  // Mendapatkan timestamp WIB sekarang
  static String nowWIB() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return now.toIso8601String();
  }

  // Format timestamp untuk display
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }
}

class AuthService {
  final supabase = Supabase.instance.client;
  final supabaseAdmin = SupabaseClient(
    'https://uvrwqhuzjttktlqerruc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cndxaHV6anR0a3RscWVycnVjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODIzMjYzOSwiZXhwIjoyMDUzODA4NjM5fQ.9KkZjb8TZq4f5vIBWsi0GF1ZX-_yqWSyCWeX_J-EQ-Y', // Simpan ini di env kalau bisa
  );

  // Fungsi untuk signup (hanya bisa dilakukan oleh admin)
  Future<String?> signUpUser({
    required String email,    required String password,
    required String fullName,
    required String role,
    String? fotoProfile,
  }) async {
    try {
      print('Mulai proses sign up untuk $email');
      final existingAdmins = await supabase
          .from('profiles')
          .select()
          .eq('role', 'admin')
          .maybeSingle();
      print('Admin yang ada: $existingAdmins');

      final isFirstUser = existingAdmins == null;

      if (isFirstUser || role == 'admin') {
        final authResponse = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        print('Sign up response: ${authResponse.user?.id}');

        if (authResponse.user != null) {
          await supabase.from('profiles').insert({
            'user_id': authResponse.user!.id,
            'role': isFirstUser ? 'admin' : role,
            'name': fullName,
            'foto_profile': fotoProfile,
            'is_active': true,
          }).select();

          print('Profile berhasil ditambahkan ke tabel');
          await logActivity(
            'user_creation',
            'Created new user: $fullName with role: ${isFirstUser ? "admin" : role}',
          );
        }
      } else {
        throw Exception('Only admins can add users!');
      }
    } catch (e) {
      print('Error during sign up: $e');
      throw Exception('Error during sign up: $e');
    }
  }

   Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? fotoProfile,
  }) async {
    try {
      print('Mulai proses pembuatan user untuk email: $email');

      // Gunakan client admin untuk membuat user
      final authResponse = await supabaseAdmin.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Otomatis memverifikasi email
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Gagal membuat user di auth.users');
      }

      print('User berhasil dibuat dengan ID: ${authResponse.user!.id}');

      // Simpan user ke tabel profiles
      await supabaseAdmin.from('profiles').insert([
        {
          'user_id': authResponse.user!.id,
          'name': fullName,
          'role': role,
          'foto_profile': fotoProfile ??
              'https://your-default-avatar-url.com/default.png',
          'is_active': true,
        },
      ]);

      print('User berhasil dimasukkan ke tabel "profiles".');

      await logActivity(
        'user_creation',
        'Created new user: $fullName with role: $role',
      );
    } catch (e) {
      print('Error saat membuat user: $e');
      throw Exception('Gagal membuat user: $e');
    }
  }


  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'Login failed';
      }

      // Cek status aktif setelah login berhasil
      final isActive = await checkUserActive(response.user!.id);
      if (!isActive) {
        await signOut(); // Sign out jika user tidak aktif
        return 'Akun Anda tidak aktif. Silakan hubungi admin.';
      }

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error occurred';
    }
  }

  Future<bool> checkUserActive(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('is_active')
          .eq('user_id', userId)
          .single();
      
      return response['is_active'] ?? false;
    } catch (e) {
      print('Error checking user active status: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserRole(Session session) async {
    try {
      final user = supabase.auth.currentSession?.user.id;
      if (user != null) {
        print('User ID saat ini: ${user}');

        final userDataResponse = await supabase
            .from('profiles')
            .select('role') // Mengambil kolom 'role'
            .eq('user_id', session.user.id)
            .single();

        if (userDataResponse != null && userDataResponse['role'] != null) {
          print('Role User saat ini: ${userDataResponse['role']}');
          return userDataResponse['role']; // Mengembalikan nilai 'role'
        } else {
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error mengambil role user: $e');
      return null;
    }
  }

  // Fungsi untuk mencatat aktivitas dengan WIB timestamp
  Future<void> logActivity(String activityType, String description) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('activity_logs').insert({
          'user_id': user.id,
          'activity_type': activityType,
          'description': description,
          'created_at': DateTimeUtils.nowWIB(), // Menambahkan timestamp WIB
        }).select();
      }
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  // Fungsi untuk mengambil activity logs dengan format WIB
  Future<List<Map<String, dynamic>>> getActivityLogs() async {
    try {
      final response = await supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false);

      // Konversi timestamp ke format WIB
      return List<Map<String, dynamic>>.from(response).map((log) {
        final localDateTime = DateTimeUtils.utcToLocal(log['created_at']);
        return {
          ...log,
          'created_at_formatted': DateTimeUtils.formatDateTime(localDateTime),
          'created_at': log['created_at'], // tetap simpan timestamp asli
        };
      }).toList();
    } catch (e) {
      print('Error fetching activity logs: $e');
      return [];
    }
  }

  Future<void> signOut() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Mengambil nama pengguna dari profil
        final userDataResponse = await supabase
            .from('profiles')
            .select('name')
            .eq('user_id', user.id)
            .single();

        String userName = userDataResponse['name'] ?? 'Unknown User';
        await logActivity('logout', 'User $userName logged out');
      }
      await supabase.auth.signOut();

      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('is_logged_in');
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}
