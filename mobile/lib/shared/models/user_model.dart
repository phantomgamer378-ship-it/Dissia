class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final UserRole role;
  final String? phone;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    role: UserRole.fromString(json['role'] as String? ?? 'public'),
    phone: json['phone'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'role': role.value,
    'phone': phone,
    'created_at': createdAt.toIso8601String(),
  };

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}

enum UserRole {
  public('public'),
  coordinator('coordinator'),
  responder('responder'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  factory UserRole.fromString(String value) =>
      UserRole.values.firstWhere(
        (r) => r.value == value,
        orElse: () => UserRole.public,
      );

  bool get canViewPrivateReports =>
      this == coordinator || this == admin;
  bool get canManageIncidents =>
      this == coordinator || this == admin;
  bool get canUpdateTasks =>
      this == responder || this == coordinator || this == admin;
  bool get isAdmin => this == admin;
}
