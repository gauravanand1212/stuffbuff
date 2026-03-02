import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus {
  pending,
  approved,
  active,
  completed,
  cancelled,
  rejected,
}

extension RentalStatusExtension on RentalStatus {
  String get displayName {
    switch (this) {
      case RentalStatus.pending:
        return 'Pending';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.active:
        return 'Active';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.cancelled:
        return 'Cancelled';
      case RentalStatus.rejected:
        return 'Rejected';
    }
  }
}

class Rental {
  final String id;
  final String toolId;
  final String ownerId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final RentalStatus status;
  final DateTime createdAt;
  final String? message;
  final String? ownerNotes;

  Rental({
    required this.id,
    required this.toolId,
    required this.ownerId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = RentalStatus.pending,
    required this.createdAt,
    this.message,
    this.ownerNotes,
  });

  factory Rental.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rental(
      id: doc.id,
      toolId: data['toolId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: RentalStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => RentalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      message: data['message'],
      ownerNotes: data['ownerNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toolId': toolId,
      'ownerId': ownerId,
      'renterId': renterId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'message': message,
      'ownerNotes': ownerNotes,
    };
  }

  int get days {
    return endDate.difference(startDate).inDays + 1;
  }

  Rental copyWith({
    RentalStatus? status,
    String? ownerNotes,
  }) {
    return Rental(
      id: id,
      toolId: toolId,
      ownerId: ownerId,
      renterId: renterId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: status ?? this.status,
      createdAt: createdAt,
      message: message,
      ownerNotes: ownerNotes ?? this.ownerNotes,
    );
  }
}