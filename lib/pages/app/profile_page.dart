import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniparkpay/auth/auth_manager.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'package:uniparkpay/widgets/app/identity_card.dart';
import 'package:uniparkpay/auth/auth_provider.dart';

class ProfilePage extends ContentPage {
  const ProfilePage({super.key}) : super(title: 'My Profile');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          IdentityCard.fromAuthProvider(authProvider),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => AuthManager().logout(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}