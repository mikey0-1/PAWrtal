class ConversationStarter {
  final String? documentId;
  final String clinicId;
  final String triggerText;
  final String responseText;
  final String category;
  final bool isActive;
  final int displayOrder;
  final bool isAutoReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationStarter({
    this.documentId,
    required this.clinicId,
    required this.triggerText,
    required this.responseText,
    this.category = 'general',
    this.isActive = true,
    this.displayOrder = 0,
    this.isAutoReply = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ConversationStarter.fromMap(Map<String, dynamic> map) {
    // CRITICAL FIX: Safely handle isAutoReply field that might not exist
    bool autoReply = false;
    try {
      if (map.containsKey('isAutoReply')) {
        // Explicitly convert to bool, handling null case
        final value = map['isAutoReply'];
        autoReply = value == true; // This ensures we get false for null
      }
    } catch (e) {
      autoReply = false;
    }

    return ConversationStarter(
      documentId: map['\$id'],
      clinicId: map['clinicId'] ?? '',
      triggerText: map['triggerText'] ?? '',
      responseText: map['responseText'] ?? '',
      category: map['category'] ?? 'general',
      isActive: map['isActive'] == true, // Same fix here
      displayOrder: map['displayOrder'] ?? 0,
      isAutoReply: autoReply,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'clinicId': clinicId,
      'triggerText': triggerText,
      'responseText': responseText,
      'category': category,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'isAutoReply': isAutoReply,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationStarter copyWith({
    String? documentId,
    String? clinicId,
    String? triggerText,
    String? responseText,
    String? category,
    bool? isActive,
    int? displayOrder,
    bool? isAutoReply,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationStarter(
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      triggerText: triggerText ?? this.triggerText,
      responseText: responseText ?? this.responseText,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      isAutoReply: isAutoReply ?? this.isAutoReply,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'appointment':
        return 'Appointment';
      case 'services':
        return 'Services';
      case 'emergency':
        return 'Emergency';
      case 'general':
      default:
        return 'General';
    }
  }

  static List<ConversationStarter> getDefaultStarters(String clinicId) {
    return [
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "Book an appointment",
        responseText:
            "I'd be happy to help you book an appointment! What type of service do you need for your pet?",
        category: 'appointment',
        displayOrder: 1,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "What services do you offer?",
        responseText:
            "We offer comprehensive veterinary services including general checkups, vaccinations, surgery, dental care, and emergency services. What specific service are you interested in?",
        category: 'services',
        displayOrder: 2,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "Emergency help",
        responseText:
            "This is an emergency situation. Please call our emergency line immediately or bring your pet to our clinic right away. For immediate assistance, contact us at our emergency number.",
        category: 'emergency',
        displayOrder: 3,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "What are your operating hours?",
        responseText:
            "Our regular operating hours vary by day. You can check our current hours in the clinic information. For emergencies, we have extended support available.",
        category: 'general',
        displayOrder: 4,
      ),
    ];
  }
}
