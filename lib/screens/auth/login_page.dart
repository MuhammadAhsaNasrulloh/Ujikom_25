import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      _signIn(session);
    } else {
      supabase.auth.onAuthStateChange.listen((event) async {
        final session = event.session;
        if (session != null) {
          _signIn(session);
        }
      });
    }
  }

  void _signIn(Session session) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Cek status aktif user
      final isActive = await _authService.checkUserActive(session.user.id);
      if (!isActive) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Akun Anda tidak aktif. Silakan hubungi admin.')),
        );
        await _authService.signOut(); // Sign out jika user tidak aktif
        return;
      }

      // Jika user aktif, lanjutkan dengan pengecekan role
      final role = await _authService.getCurrentUserRole(session);
      print('Current user role: $role'); // Debug log

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (role != null) {
        String route;
        switch (role.toLowerCase()) {
          case 'admin':
            route = AppRoutes.adminDashboard;
            break;
          case 'kasir':
            route = AppRoutes.kasirDashboard;
            break;
          case 'owner':
            route = AppRoutes.ownerDashboard;
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid role: $role')),
            );
            return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    height: 120,
                    margin: EdgeInsets.only(bottom: 40),
                    child: Image.asset(
                      'assets/images/logo-login.png', // Make sure to add your logo to assets
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Welcome Text
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please log in to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLightColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: 16),
                  // Password Field
                  _buildPasswordField(),
                  SizedBox(height: 24),
                  // Login Button
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textLightColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: AppColors.textLightColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppColors.primaryColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primaryColor,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isLoading
            ? null
            : () async {
                print('Attempting login...');
                final error = await _authService.signIn(
                  email: _emailController.text,
                  password: _passwordController.text,
                );

                if (!mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                  setState(() => _isLoading = false);
                  return;
                }
              },
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
