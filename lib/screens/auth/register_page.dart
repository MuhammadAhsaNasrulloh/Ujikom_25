import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedRole;
  final List<String> _roles = ['admin', 'user'];

  void _signUp() async {
    setState(() => _isLoading = true);

    final error = await _authService.signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      role: _selectedRole!,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    } else {
      // Navigate to login
      Navigator.pushReplacementNamed(context, '/login'); // Use your actual route name for the login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Role'),
              value: _selectedRole,
              onChanged: (newValue) {
                setState(() {
                  _selectedRole = newValue;
                });
              },
              items: _roles.map((role) {
                return DropdownMenuItem(
                  child: Text(role),
                  value: role,
                );
              }).toList(),
              hint: Text('Select Role'), // Placeholder when no role is selected
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading || _selectedRole == null ? null : _signUp,
              child: _isLoading ? CircularProgressIndicator() : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}