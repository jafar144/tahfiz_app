enum UserRole {
  admin,
  santri,
  asatidz,
}

extension StringToRoleExtension on String {
  UserRole toRole() {
    switch (this) {
      case 'admin':
        return UserRole.admin;
      case 'santri':
        return UserRole.santri;
      case 'asatidz':
        return UserRole.asatidz;
      default:
        throw ArgumentError('Invalid role: $this');
    }
  }
}

extension RoleToStringExtension on UserRole {
  String toRoleString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.santri:
        return 'santri';
      case UserRole.asatidz:
        return 'asatidz';
    }
  }
}





