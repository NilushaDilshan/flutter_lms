class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // STUDENT, INSTRUCTOR, ADMIN
  final bool isEmailVerified;
  final String? profileImage;
  final String? bio;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isEmailVerified = false,
    this.profileImage,
    this.bio,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isStudent => role.toUpperCase() == 'STUDENT';
  bool get isInstructor => role.toUpperCase() == 'INSTRUCTOR';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String? ?? 'STUDENT').toUpperCase(),
      isEmailVerified: (json['isEmailVerified'] ?? json['emailVerified']) as bool? ?? false,
      profileImage: (json['profileImage'] ?? json['profileImageUrl']) as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'profileImage': profileImage,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    bool? isEmailVerified,
    String? profileImage,
    String? bio,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
    );
  }
}
