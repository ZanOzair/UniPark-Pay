import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniparkpay/database/db_manager.dart';
import 'auth_provider.dart';
import 'package:uniparkpay/app/user_manager.dart';
import 'package:uniparkpay/app/user_role.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._constructor();
  final AuthProvider authProvider = AuthProvider();

  factory AuthManager() => _instance;

  AuthManager._constructor() {
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      
      // Check if user has expired
      final expiredInfo = await _handleExpiredUser({
        'id': user['id'],
        'name': user['name'],
        'phone_number': user['phoneNumber'],
        'university_id': user['universityId'],
        'expiry_date': user['expiryDate'],
      });
      
      if (expiredInfo != null) {
        // User expired, clear session and logout
        debugPrint('[$_tag] Expired user detected on startup, logging out');
        authProvider.setExpired();
        await logout();
        return;
      }
      
      // User not expired, proceed with login
      authProvider.login(
        id: user['id'],
        universityId: user['universityId'],
        name: user['name'],
        phoneNumber: user['phoneNumber'],
        role: UserRoleExtension.fromString(user['role']),
        expiryDate: user['expiryDate'] != null
          ? DateTime.parse(user['expiryDate'])
          : null,
        carPlateNo: user['carPlateNo'],
      );
    }
  }

  Future<void> persistCurrentAuth() async {
    if (authProvider.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode({
        'id': authProvider.id,
        'universityId': authProvider.universityId,
        'name': authProvider.name,
        'phoneNumber': authProvider.phoneNumber,
        'role': authProvider.role.name,
        'expiryDate': authProvider.expiryDate?.toIso8601String(),
        'carPlateNo': authProvider.carPlateNo,
      }));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    authProvider.logout();
  }

  final DatabaseManager _db = DatabaseManager();
  static const String _tag = 'AuthManager';

  bool _isUserExpired(Map<String, dynamic> user) {
    final expiryDateStr = user['expiry_date'];
    if (expiryDateStr == null) return false;
    
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      return expiryDate.isBefore(DateTime.now());
    } catch (e) {
      debugPrint('[$_tag] Error parsing expiry date: $e');
      return false;
    }
  }

  Future<void> _deleteExpiredUser(String userId) async {
    try {
      debugPrint('[$_tag] Deleting expired user: $userId');
      
      // Delete user - parking sessions will auto-delete via foreign key cascade
      await _db.executePrepared(
        'DELETE FROM USER WHERE id = ?',
        [userId]
      );
      
      debugPrint('[$_tag] Successfully deleted expired user: $userId');
    } catch (e, stack) {
      debugPrint('[$_tag] Error deleting expired user: $e\n$stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _handleExpiredUser(Map<String, dynamic> user) async {
    if (_isUserExpired(user)) {
      debugPrint('[$_tag] User ${user['id']} has expired, deleting...');
      
      await _deleteExpiredUser(user['id']);
      
      // Return expiry info for re-registration prompt
      return {
        'expired': true,
        'name': user['name'],
        'phone': user['phone_number'],
        'universityId': user['university_id'],
      };
    }
    return null;
  }

  Future<bool> register({
    required UserRole role,
    required String phone,
    String? universityId,
    String? name,
    String? plateNumber,
    DateTime? expiryDate,
  }) async {
    debugPrint('[$_tag] Registering user with role: $role');
    return UserManager().create(
      role: role,
      phone: phone,
      universityId: universityId,
      name: name,
      plateNumber: plateNumber,
      expiryDate: expiryDate,
    );
  }

  Future<bool> login({
    required String phone,
    required String identifier,
    required String loginType, // For query construction only
  }) async {
    debugPrint('[$_tag] Attempting login: phone=$phone, identifier=$identifier, type=$loginType');

    try {
      final query = loginType == 'lecturer_student'
        ? 'SELECT * FROM USER WHERE phone_number = ? AND university_id = ?'
        : 'SELECT * FROM USER WHERE phone_number = ? AND name = ?';
      
      final result = await _db.executePrepared(query, [phone, identifier]);

      if (result.isEmpty) {
        debugPrint('[$_tag] Login failed: No matching user found');
        throw 'Login failed: Invalid credentials';
      }

      final user = result[0];
      
      // Check if user has expired
      final expiredInfo = await _handleExpiredUser(user);
      if (expiredInfo != null) {
        debugPrint('[$_tag] Login failed: User has expired');
        // Return specific expiry error code
        throw 'USER_EXPIRED';
      }

      authProvider.login(
        id: user['id'],
        universityId: user['university_id'],
        name: user['name'],
        phoneNumber: user['phone_number'],
        role: UserRoleExtension.fromString(user['role']),
        expiryDate: user['expiry_date'] != null
          ? DateTime.parse(user['expiry_date'])
          : null,
        carPlateNo: user['car_plate_no'],
      );

      await persistCurrentAuth();
      debugPrint('[$_tag] Login successful for user: ${user['id']}');
      return true;
    } catch (e, stack) {
      debugPrint('[$_tag] Login failed: $e\n$stack');
      rethrow;
    }
  }
}