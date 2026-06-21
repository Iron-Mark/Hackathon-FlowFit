import '../../domain/entities/user.dart';

/// Data model for User that maps to/from Supabase Auth.
/// Handles JSON serialization for API communication.
class UserModel {
  final String id;
  final String email;
  final Map<String, dynamic> userMetadata;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.userMetadata,
    required this.createdAt,
  });

  /// Creates a UserModel from JSON data received from Supabase.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      userMetadata: json['user_metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String,
    );
  }

  /// Converts this UserModel to JSON for sending to Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': userMetadata,
      'created_at': createdAt,
    };
  }

  /// Converts this data model to a domain entity.
  User toDomain() {
    return User(
      id: id,
      email: email,
      fullName: userMetadata['full_name'] as String?,
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Creates a UserModel from a domain entity.
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      userMetadata: {if (user.fullName != null) 'full_name': user.fullName},
      createdAt: user.createdAt.toIso8601String(),
    );
  }
}
