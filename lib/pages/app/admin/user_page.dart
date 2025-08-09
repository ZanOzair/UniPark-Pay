import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'package:uniparkpay/app/user_manager.dart';
import 'package:uniparkpay/app/user_role.dart';
import 'package:uniparkpay/utils/validation_utils.dart';

class UserPage extends ContentPage {
  const UserPage({super.key}) : super(title: 'User Management');

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserManager userManager = UserManager();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _usersFuture = userManager.getAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = userManager.getAllUsers();
    });
  }

  Future<void> _selectExpiryDate(BuildContext context, DateTime? currentDate, Function(DateTime?) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    onDateSelected(picked);
  }

  Future<void> _showUserFormDialog({
    required BuildContext context,
    Map<String, dynamic>? user,
    required bool isCreate,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?['name']);
    final phoneController = TextEditingController(text: user?['phone_number']);
    final uniIdController = TextEditingController(text: user?['university_id']);
    final plateController = TextEditingController(text: user?['car_plate_no']);
    
    DateTime? expiryDate;
    UserRole selectedRole;
    late final String dialogTitle;
    late final String buttonText;
    
    if (isCreate) {
      expiryDate = null;
      selectedRole = UserRole.guest;
      dialogTitle = 'Create User';
      buttonText = 'Create';
    } else {
      expiryDate = user?['expiry_date'] == null ? null : DateTime.parse(user?['expiry_date']);
      selectedRole = UserRoleExtension.fromString(user?['role']);
      dialogTitle = 'Edit User';
      buttonText = 'Save';
    }
    
    bool isProcessing = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentRole = selectedRole;
          final isGuest = currentRole == UserRole.guest;
          
          return AlertDialog(
            title: Text(dialogTitle),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: UserRole.values
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedRole = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: ValidationUtils.validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: ValidationUtils.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    if (!isGuest) ...[
                      TextFormField(
                        controller: uniIdController,
                        decoration: const InputDecoration(
                          labelText: 'University ID',
                          hintText: '4 or 10 alphanumeric characters',
                        ),
                        validator: (value) => ValidationUtils.validateUniversityIdForRole(
                          value,
                          currentRole
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: plateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Plate No',
                        hintText: 'Vehicle registration number',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) =>
                          ValidationUtils.validatePlateForRole(
                            value,
                            currentRole,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (!isGuest)
                      ListTile(
                        title: Text(
                          expiryDate == null
                            ? 'Select Expiry Date'
                            : 'Expiry: ${expiryDate.toString().substring(0, 10)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectExpiryDate(context, expiryDate, (date) {
                          setState(() => expiryDate = date);
                        }),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isProcessing ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isProcessing = true);
                    
                    final name = nameController.text;
                    final phone = phoneController.text;
                    final universityId = uniIdController.text.isEmpty ? null : uniIdController.text;
                    final plateNumber = plateController.text;
                    final role = selectedRole;

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context, rootNavigator: true);
                    
                    try {
                      if (isCreate) {
                        await userManager.create(
                          name: name,
                          phone: phone,
                          universityId: universityId,
                          plateNumber: plateNumber,
                          expiryDate: expiryDate,
                          role: role,
                        );
                      } else {
                        await userManager.update(
                          user!['id'],
                          name: name,
                          phone: phone,
                          universityId: universityId,
                          plateNumber: plateNumber,
                          expiryDate: expiryDate,
                          role: role,
                        );
                      }
                      
                      messenger.showSnackBar(
                        SnackBar(content: Text(isCreate ? 'User created successfully' : 'User updated successfully')),
                      );
                      _refreshUsers();
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('${isCreate ? 'Failed to create' : 'Failed to update'} user: $e')),
                      );
                    }
                  }
                },
                child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(buttonText),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> user) async {
    await _showUserFormDialog(context: context, user: user, isCreate: false);
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    await _showUserFormDialog(context: context, isCreate: true);
  }

  Future<void> _showDeleteDialog(BuildContext context, Map<String, dynamic> user) async {
    bool isProcessing = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Delete ${user['name']}?'),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isProcessing ? null : () async {
                  setState(() => isProcessing = true);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context, rootNavigator: true);
                  
                  try {
                    await userManager.delete(user['id']);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('User deleted successfully')),
                    );
                    _refreshUsers();
                    navigator.pop();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to delete user: $e')),
                    );
                    setState(() => isProcessing = false);
                  }
                },
                child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text(user['name'] ?? 'User Details')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Role', user['role']),
              _buildDetailRow('Phone', user['phone_number']),
              _buildDetailRow('University ID', user['university_id']),
              _buildDetailRow('Vehicle', user['car_plate_no']),
              _buildDetailRow('Expiry', user['expiry_date']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: $value'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load users'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];
          final filteredUsers = _searchQuery.isEmpty 
              ? users 
              : users.where((user) {
                  final name = user['name'].toLowerCase();
                  final role = user['role'].toLowerCase();
                  final uniId = user['university_id']?.toLowerCase() ?? '';
                  
                  return name.contains(_searchQuery) ||
                         role.contains(_searchQuery) ||
                         uniId.contains(_searchQuery);
                }).toList();

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search users',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Role: ${user['role']}'),
                            if (user['university_id'] != null)
                              Text('University ID: ${user['university_id']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteDialog(context, user),
                            ),
                          ],
                        ),
                        onTap: () => _showUserDetails(context, user),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}