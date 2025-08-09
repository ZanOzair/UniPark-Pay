enum UserRole {
  admin,
  lecturer,
  student,
  guest
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin: return 'admin';
      case UserRole.lecturer: return 'lecturer';
      case UserRole.student: return 'student';
      case UserRole.guest: return 'guest';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin': return UserRole.admin;
      case 'lecturer': return UserRole.lecturer;
      case 'student': return UserRole.student;
      default: return  UserRole.guest; // Default to guest if the value is not recognized
    }
  }
}