class Staff {
  late String name;
  late String department;
  String? createdBy;
  late String image;
  late String createdAt;
  late String username; // NEW: Primary authentication field
  late String email; // OPTIONAL: For display/contact only
  String? phone;
  late String role;
  String? documentId;
  late String clinicId;
  late String userId;
  late List<String> authorities;
  late bool isActive;
  late String updatedAt;
  late bool isDoctor;

  Staff({
    required this.name,
    required this.department,
    this.createdBy,
    required this.image,
    required this.createdAt,
    required this.username, // NEW: Required field
    String? email, // OPTIONAL: Made optional
    this.phone,
    required this.role,
    this.documentId,
    required this.clinicId,
    required this.userId,
    required this.authorities,
    this.isDoctor = false,
    this.isActive = true,
    String? updatedAt,
  })  : email = email ?? '', // Default to empty string if not provided
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Staff.fromMap(Map<String, dynamic> map) {
    name = map["name"] ?? 'Unknown';
    department = map["department"] ?? 'Unknown';
    createdBy = map["createdBy"]?.toString() ?? 'Unknown';
    image = map["image"] ?? '';
    createdAt = map["createdAt"] ?? '';
    username = map["username"] ?? ''; // NEW: Parse username
    email = map["email"] ?? ''; // Optional contact email
    phone = map["phone"];
    role = map["role"] ?? 'staff';
    documentId = map["\$id"] ?? '';
    clinicId = map["clinicId"] ?? '';
    userId = map["userId"] ?? '';
    authorities = List<String>.from(map["authorities"] ?? []);
    isActive = map["isActive"] ?? true;
    updatedAt = map["updatedAt"] ?? DateTime.now().toIso8601String();
    isDoctor = map["isDoctor"] ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "department": department,
      "createdBy": createdBy ?? 'Unknown',
      "image": image,
      "createdAt": createdAt,
      "username": username, // NEW: Include username
      "email": email, // Optional contact email
      "phone": phone,
      "role": role,
      "clinicId": clinicId,
      "userId": userId,
      "authorities": authorities,
      "isActive": isActive,
      "updatedAt": updatedAt,
      "isDoctor": isDoctor,
    };
  }

  Staff copyWith({
    String? name,
    String? department,
    String? createdBy,
    String? image,
    String? createdAt,
    String? username, // NEW: Add to copyWith
    String? email,
    String? phone,
    String? role,
    String? documentId,
    String? clinicId,
    String? userId,
    List<String>? authorities,
    bool? isActive,
    String? updatedAt,
    bool? isDoctor,
  }) {
    return Staff(
      name: name ?? this.name,
      department: department ?? this.department,
      createdBy: createdBy ?? this.createdBy,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username, // NEW: Include username
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      authorities: authorities ?? this.authorities,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      isDoctor: isDoctor ?? this.isDoctor,
    );
  }
}
