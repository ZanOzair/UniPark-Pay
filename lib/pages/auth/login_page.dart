import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_manager.dart';
import '../../auth/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _selectedRole = 'lecturer_student'; // Default selection
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final AuthManager _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.wasExpired) {
        _showExpiryDialog();
        // Clear the expiry state after showing the dialog
        authProvider.clearExpired();
      }
    });
  }

  void _showExpiryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Expired'),
        content: const Text(
          'Your account has expired and been removed from the system. '
          'Please register again to continue using the app.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('Register Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('UNIPARKPAY',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Login',
                 style: TextStyle(fontSize: 16)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Role Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Login as:'),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'lecturer_student',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const Text('Lecturer/Student'),
                      Radio<String>(
                        value: 'guest',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const Text('Guest'),
                    ],
                  ),
                ],
              ),

              // Dynamic Form Fields
              if (_selectedRole == 'lecturer_student')
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'University ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ID';
                    }
                    final regex = RegExp(r'^[a-zA-Z0-9]{4}$|^[a-zA-Z0-9]{10}$');
                    if (!regex.hasMatch(value)) {
                      return 'ID must be 4 or 10 alphanumeric characters';
                    }
                    return null;
                  },
                ),
              if (_selectedRole == 'guest')
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10 || value.length > 15) {
                    return 'Phone must be 10-15 digits';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  
                  setState(() => _isLoading = true);
                  
                  try {
                    await _authManager.login(
                      loginType: _selectedRole,
                      phone: _phoneController.text,
                      identifier: _selectedRole == 'lecturer_student'
                        ? _idController.text
                        : _nameController.text,
                    );
                  } catch (e) {
                    final error = e.toString();
                    if (error.contains('USER_EXPIRED')) {
                      if (mounted) {
                        _showExpiryDialog();
                      }
                    } else {
                      setState(() {
                        _errorMessage = error;
                      });
                    }
                    setState(() => _isLoading = false);
                  }
                },
                child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}