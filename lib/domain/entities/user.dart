/// Domain entity representing a user in the system.
/// Immutable for use with Riverpod state management.
class User {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;
  final DateTime? emailConfirmedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    required this.createdAt,
    this.emailConfirmedAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? emailConfirmedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          createdAt == other.createdAt &&
          emailConfirmedAt == other.emailConfirmedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      createdAt.hashCode ^
      emailConfirmedAt.hashCode;

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, createdAt: $createdAt, emailConfirmedAt: $emailConfirmedAt}';
  }
}
