class Pet {
  late String petId;
  late String userId;
  late String name;
  late String type;
  late String breed;
  String? color;
  String? image;
  String? notes;
  double? weight;
  String? createdAt;
  String? documentId;
  String? gender;
  DateTime? birthdate; // NEW: Birthdate field

  Pet({
    required this.petId,
    required this.userId,
    required this.name,
    required this.type,
    required this.breed,
    this.color,
    this.image,
    this.notes,
    this.weight,
    this.createdAt,
    this.documentId,
    this.gender,
    this.birthdate, // NEW
  });

  Pet.fromMap(Map<String, dynamic> map) {
    petId = map['petId'] ?? '';
    userId = map['userId'] ?? '';
    name = map['name'] ?? '';
    type = map['type'] ?? '';
    breed = map['breed'] ?? '';
    color = map['color'] ?? '';
    image = map['image'] ?? '';
    notes = map['notes'];
    weight = (map['weight'] as num?)?.toDouble() ?? 0.0;
    createdAt = map['\$createdAt'] ?? '';
    documentId = map['\$id'] ?? '';
    gender = map['gender'] ?? '';

    // NEW: Parse birthdate
    if (map['birthdate'] != null && map['birthdate'].toString().isNotEmpty) {
      try {
        birthdate = DateTime.parse(map['birthdate']);
      } catch (e) {
        birthdate = null;
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'userId': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'color': color,
      'image': image,
      'notes': notes,
      'weight': weight,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(), // NEW: Include birthdate
    };
  }

  Pet copyWith({
    String? petId,
    String? userId,
    String? name,
    String? type,
    String? breed,
    String? color,
    String? image,
    String? notes,
    double? weight,
    String? createdAt,
    String? documentId,
    String? gender,
    DateTime? birthdate, // NEW
  }) {
    return Pet(
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      image: image ?? this.image,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      documentId: documentId ?? this.documentId,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate, // NEW
    );
  }

  // NEW: Calculate age from birthdate
  String get ageString {
    if (birthdate == null) return 'Age unknown';

    final now = DateTime.now();
    final age = now.difference(birthdate!);

    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    final days = (age.inDays % 365) % 30;

    if (years > 0) {
      if (months > 0) {
        return '$years ${years == 1 ? 'year' : 'years'}, $months ${months == 1 ? 'month' : 'months'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else if (months > 0) {
      if (days > 7) {
        return '$months ${months == 1 ? 'month' : 'months'}, ${days ~/ 7} ${days ~/ 7 == 1 ? 'week' : 'weeks'}';
      }
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else if (days >= 7) {
      final weeks = days ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else {
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
  }

  // NEW: Get age in years (for sorting or comparisons)
  double get ageInYears {
    if (birthdate == null) return 0;
    final now = DateTime.now();
    final age = now.difference(birthdate!);
    return age.inDays / 365.25;
  }

  // NEW: Helper to check if birthdate is set
  bool get hasBirthdate => birthdate != null;
}
