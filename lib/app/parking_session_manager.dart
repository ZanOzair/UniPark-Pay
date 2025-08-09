import 'package:flutter/foundation.dart';
import 'package:uniparkpay/database/db_manager.dart';
import 'package:uniparkpay/utils/image_data_converter.dart';

class ParkingSessionManager {
  static final ParkingSessionManager _instance = ParkingSessionManager._internal();
  factory ParkingSessionManager() => _instance;
  ParkingSessionManager._internal();

  final DatabaseManager _db = DatabaseManager();
  static const String _tag = 'ParkingSessionManager';

  /// Creates a parking session with unverified status (as per schema)
  Future<Map<String, dynamic>> createSession({
    required String userId,
    required String parkingAreaId,
    required String paymentQrCodeId,
    required double latitude,
    required double longitude,
    required int durationHours,
    required DateTime startTime,
    Uint8List? paymentProof,
    String? proofFilename,
    String? proofMimeType,
  }) async {
    debugPrint('[$_tag] Creating parking session for user $userId');
    
    try {
      final endTime = startTime.add(Duration(hours: durationHours));
      
      String query;
      List<dynamic> params;
      
      if (paymentProof != null) {
        // Convert payment proof to base64 string for storage (like QR codes)
        final paymentProofString = ImageDataConverter.uint8ListToString(paymentProof);
        
        query = '''
          INSERT INTO PARKING_SESSION (
            start_time, end_time, latitude, longitude,
            user_id, parking_area_id, payment_qr_code_id, status,
            payment_proof, proof_filename, proof_mime_type, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 'unverified', ?, ?, ?, NOW())
        ''';
        params = [
          startTime.toIso8601String(),
          endTime.toIso8601String(),
          latitude,
          longitude,
          userId,
          parkingAreaId,
          paymentQrCodeId,
          paymentProofString,
          proofFilename,
          proofMimeType,
        ];
      } else {
        query = '''
          INSERT INTO PARKING_SESSION (
            start_time, end_time, latitude, longitude,
            user_id, parking_area_id, payment_qr_code_id, status, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 'unverified', NOW())
        ''';
        params = [
          startTime.toIso8601String(),
          endTime.toIso8601String(),
          latitude,
          longitude,
          userId,
          parkingAreaId,
          paymentQrCodeId,
        ];
      }

      await _db.executePrepared(query, params);

      final sessionId = await _db.execute('SELECT LAST_INSERT_ID() as id');
      debugPrint('[$_tag] Successfully created parking session ${sessionId.first['id']}');
      
      return {
        'id': sessionId.first['id'],
        'start_time': startTime,
        'end_time': endTime,
        'status': 'unverified',
      };
    } catch (e) {
      debugPrint('[$_tag] Failed to create parking session: $e');
      rethrow;
    }
  }

  /// Gets the current active parking session for a user
  Future<Map<String, dynamic>?> getActiveSession(int userId) async {
    debugPrint('[$_tag] Getting active session for user $userId');
    
    try {
      final result = await _db.executePrepared('''
        SELECT * FROM PARKING_SESSION 
        WHERE user_id = ? AND end_time > NOW()
        ORDER BY created_at DESC LIMIT 1
      ''', [userId]);
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('[$_tag] Failed to get active session: $e');
      rethrow;
    }
  }

  /// Gets the latest QR code for payment
  Future<Map<String, dynamic>?> getLatestPaymentQR() async {
    debugPrint('[$_tag] Getting latest payment QR code');
    
    try {
      final result = await _db.execute('''
        SELECT * FROM PAYMENT_QR_CODE 
        ORDER BY created_at DESC LIMIT 1
      ''');
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('[$_tag] Failed to get payment QR: $e');
      rethrow;
    }
  }

  /// Gets parking session by ID
  Future<Map<String, dynamic>?> getSessionById(int sessionId) async {
    debugPrint('[$_tag] Getting session $sessionId');
    
    try {
      final result = await _db.executePrepared('''
        SELECT * FROM PARKING_SESSION WHERE id = ?
      ''', [sessionId]);
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('[$_tag] Failed to get session: $e');
      rethrow;
    }
  }

  /// Fetch all parking sessions for guest users with complete details for admin review
  Future<List<Map<String, dynamic>>> getGuestSessionsForAdmin() async {
    debugPrint('[$_tag] Getting guest sessions for admin review');
    
    try {
      final result = await _db.executePrepared('''
        SELECT
          ps.*,
          u.name as user_name,
          u.phone_number as user_phone,
          u.car_plate_no,
          pa.name as parking_area_name,
          pa.latitude as area_latitude,
          pa.longitude as area_longitude,
          pa.radius as area_radius,
          pqc.filename as qr_filename,
          pqc.bank_name
        FROM PARKING_SESSION ps
        JOIN USER u ON ps.user_id = u.id
        JOIN PARKING_AREA pa ON ps.parking_area_id = pa.id
        LEFT JOIN PAYMENT_QR_CODE pqc ON ps.payment_qr_code_id = pqc.id
        WHERE u.role = 'guest'
        ORDER BY ps.created_at DESC
      ''', []);
      
      // Convert payment proof data to proper format
      final convertedResult = result.map((session) {
        final convertedSession = Map<String, dynamic>.from(session);
        
        if (convertedSession['payment_proof'] != null) {
          try {
            convertedSession['payment_proof'] = ImageDataConverter.convertToImageBytes(convertedSession['payment_proof']);
          } catch (e) {
            debugPrint('[$_tag] Error converting payment proof: $e');
            convertedSession['payment_proof'] = null;
          }
        }
        
        return convertedSession;
      }).toList();
      
      return convertedResult;
    } catch (e) {
      debugPrint('[$_tag] Failed to get guest sessions: $e');
      rethrow;
    }
  }

  /// Fetch all parking sessions for non-guest users with complete details for admin review
  Future<List<Map<String, dynamic>>> getNonGuestSessionsForAdmin() async {
    debugPrint('[$_tag] Getting non-guest sessions for admin review');
    
    try {
      final result = await _db.executePrepared('''
        SELECT
          ps.*,
          u.name as user_name,
          u.phone_number as user_phone,
          u.university_id,
          u.role as user_role,
          u.car_plate_no,
          pa.name as parking_area_name,
          pa.latitude as area_latitude,
          pa.longitude as area_longitude,
          pa.radius as area_radius
        FROM PARKING_SESSION ps
        JOIN USER u ON ps.user_id = u.id
        JOIN PARKING_AREA pa ON ps.parking_area_id = pa.id
        WHERE u.role IN ('lecturer', 'student', 'admin')
        ORDER BY ps.created_at DESC
      ''', []);
      
      return result;
    } catch (e) {
      debugPrint('[$_tag] Failed to get non-guest sessions: $e');
      rethrow;
    }
  }

  /// Update session status (approve/reject/unverified) for admin review
  Future<bool> updateSessionStatus(String sessionId, String status) async {
    debugPrint('[$_tag] Updating session $sessionId status to $status');
    
    try {
      await _db.executePrepared('''
        UPDATE PARKING_SESSION
        SET status = ?
        WHERE id = ?
      ''', [status, sessionId]);
      
      debugPrint('[$_tag] Successfully updated session $sessionId status to $status');
      return true;
    } catch (e) {
      debugPrint('[$_tag] Failed to update session status: $e');
      return false;
    }
  }

  /// Get all parking areas
  Future<List<Map<String, dynamic>>> getParkingAreas() async {
    debugPrint('[$_tag] Getting all parking areas');
    
    try {
      final result = await _db.execute('''
        SELECT id, name, latitude, longitude, radius
        FROM PARKING_AREA
        ORDER BY name ASC
      ''');
      
      return result;
    } catch (e) {
      debugPrint('[$_tag] Failed to get parking areas: $e');
      rethrow;
    }
  }
}