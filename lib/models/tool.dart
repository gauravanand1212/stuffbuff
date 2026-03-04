import 'package:cloud_firestore/cloud_firestore.dart';

enum ToolCategory {
  powerTools,
  handTools,
  gardenTools,
  automotive,
  cleaning,
  painting,
  plumbing,
  electrical,
  other,
}

extension ToolCategoryExtension on ToolCategory {
  String get displayName {
    switch (this) {
      case ToolCategory.powerTools:
        return 'Power Tools';
      case ToolCategory.handTools:
        return 'Hand Tools';
      case ToolCategory.gardenTools:
        return 'Garden & Outdoor';
      case ToolCategory.automotive:
        return 'Automotive';
      case ToolCategory.cleaning:
        return 'Cleaning';
      case ToolCategory.painting:
        return 'Painting';
      case ToolCategory.plumbing:
        return 'Plumbing';
      case ToolCategory.electrical:
        return 'Electrical';
      case ToolCategory.other:
        return 'Other';
    }
  }
}

class Tool {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double pricePerDay;
  final ToolCategory category;
  final List<String> images;
  final bool isAvailable;
  final DateTime createdAt;
  final String? location;
  final double? rating;

  Tool({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.category,
    required this.images,
    this.isAvailable = true,
    required this.createdAt,
    this.location,
    this.rating,
  });

  factory Tool.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Tool(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      category: ToolCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => ToolCategory.other,
      ),
      images: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'],
      rating: data['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'pricePerDay': pricePerDay,
      'category': category.toString(),
      'images': images,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'rating': rating,
    };
  }

  Tool copyWith({
    String? title,
    String? description,
    double? pricePerDay,
    ToolCategory? category,
    List<String>? images,
    bool? isAvailable,
    String? location,
    double? rating,
  }) {
    return Tool(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      category: category ?? this.category,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      location: location ?? this.location,
      rating: rating ?? this.rating,
    );
  }
}
