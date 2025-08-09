import '../app/user_role.dart';

class ValidationUtils {
  static final RegExp universityIdRegex = RegExp(r'^[a-zA-Z0-9]{4}$|^[a-zA-Z0-9]{10}$');
  static final RegExp phoneRegex = RegExp(r'^[0-9]{10,15}$');
  static final RegExp plateRegex = RegExp(r'^[A-Za-z0-9 ]{1,10}$');

  static String? validateUniversityId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter university ID';
    }
    if (!universityIdRegex.hasMatch(value)) {
      return 'ID must be 4 or 10 alphanumeric characters';
    }
    return null;
  }

  static String? validateUniversityIdForRole(String? value, UserRole role) {
    // No validation required for guest and admin roles
    if (role == UserRole.student || role == UserRole.lecturer) {
      return validateUniversityId(value);
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    if (!phoneRegex.hasMatch(value)) {
      return 'Phone must be 10-15 digits';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  static String? validatePlate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter plate number';
    }
    if (!plateRegex.hasMatch(value)) {
      return 'Plate must be 1-10 alphanumeric characters and spaces';
    }
    return null;
  }

  static String? validatePlateForRole(String? value, UserRole role) {
    // Allow null for admin role
    if (role != UserRole.admin) {
      return validatePlate(value);
    }
    return null;
  }

  static String validateAndNormalizeDuration(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1) {
      return '1';
    }
    return '$parsed';
  }
}