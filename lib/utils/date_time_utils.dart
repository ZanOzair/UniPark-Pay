import 'package:flutter/material.dart';

class DateTimeUtils {
  /// Formats time remaining from a given end time to now
  /// Handles both String and DateTime input types
  static String formatTimeRemaining(dynamic endTime) {
    DateTime endDateTime;
    
    try {
      if (endTime == null) return "00:00:00";
      
      if (endTime is String) {
        endDateTime = DateTime.parse(endTime);
      } else if (endTime is DateTime) {
        endDateTime = endTime;
      } else {
        return "00:00:00";
      }
    } catch (e) {
      debugPrint('Error parsing end time: $e');
      return "00:00:00";
    }
    
    final now = DateTime.now();
    final difference = endDateTime.difference(now);
    
    if (difference.isNegative) {
      return "00:00:00";
    }
    
    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
    
    return "$hours:$minutes:$seconds";
  }

  /// Formats database time for display in 12-hour format
  /// Handles both String and DateTime input types
  static String formatSessionTime(dynamic dbTime) {
    DateTime dateTime;
    
    try {
      if (dbTime == null) return 'Invalid time';
      
      if (dbTime is String) {
        dateTime = DateTime.parse(dbTime);
      } else if (dbTime is DateTime) {
        dateTime = dbTime;
      } else {
        return 'Invalid time';
      }
    } catch (e) {
      debugPrint('Error parsing session time: $e');
      return 'Invalid time';
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$hour:$minute:$second $period';
  }

  /// Safely parses any input to DateTime
  /// Returns null if parsing fails
  static DateTime? safeParseDateTime(dynamic input) {
    if (input == null) return null;
    
    try {
      if (input is String) {
        return DateTime.parse(input);
      } else if (input is DateTime) {
        return input;
      }
    } catch (e) {
      debugPrint('Error parsing DateTime: $e');
    }
    
    return null;
  }

  /// Formats DateTime to database-compatible string
  static String toDatabaseString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Gets current DateTime as database-compatible string
  static String getCurrentDatabaseString() {
    return DateTime.now().toIso8601String();
  }
}