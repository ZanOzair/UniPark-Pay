import 'dart:typed_data';
import 'dart:convert';

/// Utility class for converting between different image data formats
/// Handles conversion between string (base64) and Uint8List (longblob) formats
class ImageDataConverter {
  /// Converts base64 string to Uint8List (longblob format)
  static Uint8List stringToUint8List(String data) {
    return base64Decode(data);
  }

  /// Converts Uint8List to base64 string for database storage
  static String uint8ListToString(Uint8List data) {
    return base64Encode(data);
  }

  /// Handles various data types from database and converts to Uint8List
  /// Supports String (base64) and Uint8List inputs
  static Uint8List? convertToImageBytes(dynamic imageData) {
    if (imageData == null) return null;
    
    try {
      if (imageData is Uint8List) {
        return imageData;
      } else if (imageData is List<int>) {
        return Uint8List.fromList(imageData);
      } else if (imageData is String) {
        // Only handle base64 strings (consistent with QR code format)
        return stringToUint8List(imageData);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error converting image data: $e');
    }
    
    return null;
  }
}