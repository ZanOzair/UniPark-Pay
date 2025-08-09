import 'package:flutter/foundation.dart';
import 'package:uniparkpay/database/db_manager.dart';
import 'package:uniparkpay/app/user_role.dart';

class UserManager {
  final DatabaseManager _db = DatabaseManager();
  static const String _tag = 'UserManager';

  Future<bool> create({
    required UserRole role,
    required String phone,
    String? universityId,
    String? name,
    String? plateNumber,
    DateTime? expiryDate,
  }) async {
    debugPrint('[$_tag] Storing role: $role');

    try {
      final existing = await _db.executePrepared(
        'SELECT id FROM USER WHERE phone_number = ? OR university_id = ?',
        [phone, universityId],
      );

      if (existing.isNotEmpty) {
        debugPrint('[$_tag] Duplicate registration: phone=$phone, universityId=$universityId');
        throw 'Registration failed: This phone number or university ID is already in use';
      }

      await _db.executePrepared(
        '''
        INSERT INTO USER (
          university_id, name, phone_number, 
          role, expiry_date, car_plate_no
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          universityId,
          name,
          phone,
          role.name,
          expiryDate?.toIso8601String(),
          plateNumber,
        ],
      );

      debugPrint('[$_tag] Successfully registered user with phone: $phone');
      return true;
    } catch (e) {
      debugPrint('[$_tag] Registration failed: $e');
      rethrow;
    }
  }

  Future<bool> update(String userId, {
    String? universityId,
    String? name,
    String? phone,
    String? plateNumber,
    DateTime? expiryDate,
    required UserRole role,
  }) async {
    debugPrint('[$_tag] Updating user $userId');
    
    try {
      
      // Check for duplicates, excluding current user (only for fields with UNIQUE constraints)
      final existing = await _db.executePrepared(
        'SELECT id FROM USER WHERE (phone_number = ? OR university_id = ?) AND id != ?',
        [phone, universityId, userId],
      );

      if (existing.isNotEmpty) {
        debugPrint('[$_tag] Duplicate update: phone=$phone, universityId=$universityId');
        throw 'Update failed: This phone number or university ID is already in use by another user';
      }

      await _db.executePrepared(
        '''
        UPDATE USER SET
          university_id = ?,
          name = ?,
          phone_number = ?,
          car_plate_no = ?,
          expiry_date = ?,
          role = ?
        WHERE id = ?
        ''',
        [
          universityId,
          name,
          phone,
          plateNumber,
          expiryDate?.toIso8601String(),
          role.name,
          userId
        ],
      );

      debugPrint('[$_tag] Successfully updated user $userId');
      return true;
    } catch (e) {
      debugPrint('[$_tag] User update failed: $e');
      rethrow;
    }
  }

  Future<bool> delete(String userId) async {
    debugPrint('[$_tag] Deleting user $userId');
    
    try {
      await _db.executePrepared(
        'DELETE FROM USER WHERE id = ?',
        [userId],
      );

      debugPrint('[$_tag] Successfully deleted user $userId');
      return true;
    } catch (e) {
      debugPrint('[$_tag] User deletion failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    debugPrint('[$_tag] Fetching all users');
    
    try {
      final result = await _db.execute('SELECT * FROM USER');
      debugPrint('[$_tag] Successfully fetched ${result.length} users');
      return result;
    } catch (e) {
      debugPrint('[$_tag] Failed to fetch users: $e');
      rethrow;
    }
  }
}