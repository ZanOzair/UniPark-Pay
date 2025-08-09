import 'package:flutter/material.dart';
import '../app/user_role.dart';

/// Authentication state management
class AuthProvider with ChangeNotifier {
  String? _id;
  String? _universityId;
  String _name = '';
  String _phoneNumber = '';
  UserRole _role = UserRoleExtension.fromString('');
  DateTime? _expiryDate;
  String? _carPlateNo;
  bool _wasExpired = false;
  
  bool get isLoggedIn => _id != null;
  bool get wasExpired => _wasExpired;
  String? get id => _id;
  String? get universityId => _universityId;
  String get name => _name;
  String get phoneNumber => _phoneNumber;
  UserRole get role => _role;
  DateTime? get expiryDate => _expiryDate;
  String? get carPlateNo => _carPlateNo;

  Future<void> login({
    required String id,
    String? universityId,
    required String name,
    required String phoneNumber,
    required UserRole role,
    DateTime? expiryDate,
    String? carPlateNo,
  }) async {
    _id = id;
    _universityId = universityId;
    _name = name;
    _phoneNumber = phoneNumber;
    _role = role;
    _expiryDate = expiryDate;
    _carPlateNo = carPlateNo;
    notifyListeners();
  }

  Future<void> logout() async {
    _id = null;
    _universityId = null;
    _name = '';
    _phoneNumber = '';
    _role = UserRoleExtension.fromString('');
    _expiryDate = null;
    _carPlateNo = null;
    // Don't clear _wasExpired here - it will be cleared when dialog is shown
    notifyListeners();
  }

  void setExpired() {
    _wasExpired = true;
    notifyListeners();
  }

  void clearExpired() {
    debugPrint("DISPLAYED CLEAR EXPIRED");
    _wasExpired = false;
    notifyListeners();
  }
}