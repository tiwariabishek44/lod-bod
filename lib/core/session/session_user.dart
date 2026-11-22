enum UserRole { shipper, carrier, driver, unknown }

UserRole userRoleFromJson(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'shipper' => UserRole.shipper,
    'carrier' => UserRole.carrier,
    'driver' => UserRole.driver,
    _ => UserRole.unknown,
  };
}

extension UserRoleJson on UserRole {
  String get value => name;
}

class SessionUser {
  const SessionUser({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role = UserRole.unknown,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final UserRole role;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? json['phoneNumber'] as String?,
      role: userRoleFromJson(json['role']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    'role': role.value,
  };
}
