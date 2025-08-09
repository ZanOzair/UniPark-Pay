import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniparkpay/auth/auth_manager.dart';
import 'package:uniparkpay/app/user_role.dart';
import 'package:uniparkpay/utils/validation_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _selectedRole = 'lecturer_student'; // Default selection
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  final AuthManager _authManager = AuthManager();

  Future<void> _handleRegistration() async {
    setState(() => _isLoading = true);
    
    try {
      String? universityId = _idController.text;
      UserRole role;
      
      if (_selectedRole == 'guest' || universityId.isEmpty) {
        role = UserRole.guest;
        universityId = null;
      } else if (universityId.length < 10) {
        role = UserRole.lecturer;
      } else {
        role = UserRole.student;
      }
      
      await _authManager.register(
        role: role,
        phone: _phoneController.text,
        universityId: universityId,
        name: _nameController.text,
        plateNumber: _plateController.text,
        expiryDate: _expiryDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    finally {
      setState(() => _isLoading = false);
    }
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
            Text('Register',
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
                  const Text('Register as:'),
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
                Column(
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'University ID',
                      ),
                      validator: ValidationUtils.validateUniversityId,
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                      ),
                      validator: ValidationUtils.validateName,
                    ),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Plate No',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: ValidationUtils.validatePlate,
                    ),
                    ListTile(
                      title: Text(
                        _expiryDate == null
                          ? 'Select Expiry Date'
                          : 'Expiry: ${_expiryDate.toString().substring(0, 10)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectExpiryDate(context),
                    ),
                  ],
                ),

              if (_selectedRole == 'guest')
                Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                      ),
                      validator: ValidationUtils.validateName,
                    ),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Plate No',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: ValidationUtils.validatePlate,
                    ),
                  ],
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
                validator: ValidationUtils.validatePhone,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedRole == 'lecturer_student' && _expiryDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select expiry date')),
                      );
                      return;
                    }
                    _handleRegistration();
                  }
                },
                child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}