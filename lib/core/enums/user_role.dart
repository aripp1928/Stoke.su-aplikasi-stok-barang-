/// User roles in the application.
enum UserRole {
  admin('Admin'),
  crew('Crew');

  const UserRole(this.label);
  final String label;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.crew,
    );
  }
}
