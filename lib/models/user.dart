import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final double? rating;
  final int rentalCount;

  AppUser({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.rating,
    this.rentalCount = 0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      rating: data['rating']?.toDouble(),
      rentalCount: data['rentalCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'rentalCount': rentalCount,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    double? rating,
    int? rentalCount,
  }) {
    return AppUser(
      id: id,
      phoneNumber: phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      rating: rating ?? this.rating,
      rentalCount: rentalCount ?? this.rentalCount,
    );
  }
}