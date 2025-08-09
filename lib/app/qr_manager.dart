import 'dart:typed_data';
import 'package:uniparkpay/database/db_manager.dart';
import 'package:uniparkpay/utils/image_data_converter.dart';

/// Manages QR code operations for admin users
class QRManager {
  static final QRManager _instance = QRManager._internal();
  factory QRManager() => _instance;
  QRManager._internal();

  /// Retrieves the latest QR code
  Future<Map<String, dynamic>?> getCurrentQR() async {
    try {
      final result = await DatabaseManager().execute(
        'SELECT id, filename, bank_name, qr_image, proof_mime_type, created_at '
        'FROM PAYMENT_QR_CODE '
        'ORDER BY created_at DESC '
        'LIMIT 1',
      );

      if (result.isEmpty) return null;

      final originalData = result.first;
      final data = Map<String, dynamic>.from(originalData);

      // Handle BLOB data conversion using shared ImageDataConverter
      if (data['qr_image'] != null) {
        try {
          data['qr_image'] = ImageDataConverter.convertToImageBytes(
            data['qr_image'],
          );
        } catch (e) {
          data['qr_image'] = null;
        }
      }

      return data;
    } catch (e) {
      throw Exception('Failed to load QR code: $e');
    }
  }

  /// Uploads a new QR code (latest upload overwrites previous)
  Future<void> uploadQR({
    required String filename,
    required String bankName,
    required Uint8List imageData,
    required String mimeType,
    required String userId,
  }) async {
    try {
      // Convert Uint8List to base64 String for storage using shared converter
      final imageString = ImageDataConverter.uint8ListToString(imageData);

      // Check if a QR code exists
      final existing = await DatabaseManager().execute(
        'SELECT id FROM PAYMENT_QR_CODE LIMIT 1',
      );

      if (existing.isEmpty) {
        // First QR code - insert
        await DatabaseManager().executePrepared(
          'INSERT INTO PAYMENT_QR_CODE (filename, bank_name, qr_image, proof_mime_type, user_id) '
          'VALUES (?, ?, ?, ?, ?)',
          [filename, bankName, imageString, mimeType, userId],
        );
      } else {
        // Update existing QR code
        final id = existing.first['id'];
        await DatabaseManager().executePrepared(
          'UPDATE PAYMENT_QR_CODE SET filename = ?, bank_name = ?, qr_image = ?, proof_mime_type = ?, user_id = ?, created_at = NOW() WHERE id = ?',
          [filename, bankName, imageString, mimeType, userId, id],
        );
      }
    } catch (e) {
      throw Exception('Failed to upload QR code: $e');
    }
  }

  /// Checks if a QR code exists
  Future<bool> hasQRCode() async {
    try {
      final result = await DatabaseManager().execute(
        'SELECT COUNT(*) as count FROM PAYMENT_QR_CODE',
      );
      return (result.first['count'] as int) > 0;
    } catch (e) {
      return false;
    }
  }
}
