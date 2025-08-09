import 'package:flutter/material.dart';
import '../../auth/auth_provider.dart';

class IdentityCard extends StatelessWidget {
  final String? universityId;
  final String name;
  final String phoneNumber;
  final String? carPlateNo;
  final DateTime? expiryDate;

  const IdentityCard({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.universityId,
    this.carPlateNo,
    this.expiryDate,
  });

  factory IdentityCard.fromAuthProvider(AuthProvider auth) {
    return IdentityCard(
      universityId: auth.universityId,
      name: auth.name,
      phoneNumber: auth.phoneNumber,
      carPlateNo: auth.carPlateNo,
      expiryDate: auth.expiryDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (universityId != null)
              _buildProfileRow('University ID', universityId!),
            _buildProfileRow('Name', name),
            _buildProfileRow('Phone', phoneNumber),
            if (carPlateNo != null)
              _buildProfileRow('Vehicle Plate No', carPlateNo!),
            if (expiryDate != null)
              _buildProfileRow(
                'Expiry',
                _formatDate(expiryDate!),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label),
          ),
          Text(value),
        ],
      ),
    );
  }
}