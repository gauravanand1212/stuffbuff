import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool.dart';
import '../models/rental.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tools
  Future<String> createTool(Tool tool) async {
    final doc = await _firestore.collection('tools').add(tool.toMap());
    return doc.id;
  }

  Future<void> updateTool(Tool tool) async {
    await _firestore.collection('tools').doc(tool.id).update(tool.toMap());
  }

  Future<void> deleteTool(String toolId) async {
    await _firestore.collection('tools').doc(toolId).delete();
  }

  Stream<List<Tool>> getToolsStream({
    ToolCategory? category,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection('tools')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.toString());
    }

    return query.snapshots().map((snapshot) {
      var tools = snapshot.docs.map((doc) => Tool.fromFirestore(doc)).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        tools = tools.where((tool) {
          return tool.title.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query);
        }).toList();
      }
      
      return tools;
    });
  }

  Stream<Tool> getToolStream(String toolId) {
    return _firestore
        .collection('tools')
        .doc(toolId)
        .snapshots()
        .map((doc) => Tool.fromFirestore(doc));
  }

  Stream<List<Tool>> getUserToolsStream(String userId) {
    return _firestore
        .collection('tools')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Tool.fromFirestore(doc)).toList();
    });
  }

  // Rentals
  Future<String> createRental(Rental rental) async {
    final doc = await _firestore.collection('rentals').add(rental.toMap());
    return doc.id;
  }

  Future<void> updateRentalStatus(String rentalId, RentalStatus status, {String? notes}) async {
    final update = <String, dynamic>{'status': status.toString()};
    if (notes != null) update['ownerNotes'] = notes;
    await _firestore.collection('rentals').doc(rentalId).update(update);
  }

  Stream<List<Rental>> getUserRentalsStream(String userId) {
    return _firestore
        .collection('rentals')
        .where('renterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Rental.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Rental>> getOwnerRentalsStream(String ownerId) {
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Rental.fromFirestore(doc)).toList();
    });
  }

  // Check availability
  Future<bool> isToolAvailable(String toolId, DateTime startDate, DateTime endDate) async {
    final rentals = await _firestore
        .collection('rentals')
        .where('toolId', isEqualTo: toolId)
        .where('status', whereIn: [
          RentalStatus.approved.toString(),
          RentalStatus.active.toString(),
        ])
        .get();

    for (final doc in rentals.docs) {
      final rental = Rental.fromFirestore(doc);
      if (_dateRangesOverlap(
        rental.startDate,
        rental.endDate,
        startDate,
        endDate,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _dateRangesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}