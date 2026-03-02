import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/rental.dart';
import '../../models/tool.dart';
import '../../services/firestore_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Center(child: Text('Please sign in'));
        }

        final userId = state.user.id;

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'My Requests', icon: Icon(Icons.shopping_bag)),
                Tab(text: 'Requests for My Tools', icon: Icon(Icons.handyman)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RenterRentalsList(userId: userId),
                  _OwnerRentalsList(ownerId: userId),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RenterRentalsList extends StatelessWidget {
  final String userId;

  const _RenterRentalsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Rental>>(
      stream: FirestoreService().getUserRentalsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rentals = snapshot.data!;

        if (rentals.isEmpty) {
          return _EmptyState(
            icon: Icons.search,
            title: 'No Rental Requests',
            message: 'Browse tools and request to rent something!',
            actionLabel: 'Browse Tools',
            onAction: () {
              // Navigate to browse tab
              DefaultTabController.of(context).animateTo(0);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rentals.length,
          itemBuilder: (context, index) {
            return _RentalCard(
              rental: rentals[index],
              showAsRenter: true,
            );
          },
        );
      },
    );
  }
}

class _OwnerRentalsList extends StatelessWidget {
  final String ownerId;

  const _OwnerRentalsList({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Rental>>(
      stream: FirestoreService().getOwnerRentalsStream(ownerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rentals = snapshot.data!;

        if (rentals.isEmpty) {
          return _EmptyState(
            icon: Icons.handyman_outlined,
            title: 'No Requests Yet',
            message: 'When someone requests to rent your tools, you\'ll see them here.',
            actionLabel: 'List a Tool',
            onAction: () {
              // Navigate to My Tools tab
              DefaultTabController.of(context).animateTo(1);
            },
          );
        }

        // Sort: pending first, then by date
        rentals.sort((a, b) {
          if (a.status == RentalStatus.pending && b.status != RentalStatus.pending) return -1;
          if (a.status != RentalStatus.pending && b.status == RentalStatus.pending) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rentals.length,
          itemBuilder: (context, index) {
            return _RentalCard(
              rental: rentals[index],
              showAsRenter: false,
            );
          },
        );
      },
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Rental rental;
  final bool showAsRenter;

  const _RentalCard({
    required this.rental,
    required this.showAsRenter,
  });

  Color _getStatusColor() {
    switch (rental.status) {
      case RentalStatus.pending:
        return Colors.orange;
      case RentalStatus.approved:
        return Colors.blue;
      case RentalStatus.active:
        return Colors.green;
      case RentalStatus.completed:
        return Colors.grey;
      case RentalStatus.cancelled:
        return Colors.red;
      case RentalStatus.rejected:
        return Colors.red.shade700;
    }
  }

  Future<void> _updateStatus(BuildContext context, RentalStatus status) async {
    try {
      await FirestoreService().updateRentalStatus(rental.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status.displayName.toLowerCase()}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showOwnerActions(BuildContext context) async {
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Request Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add a message for the renter...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (rental.status == RentalStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateStatus(context, RentalStatus.approved);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateStatus(context, RentalStatus.rejected);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (rental.status == RentalStatus.approved) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(context, RentalStatus.active);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Mark as Active (Picked Up)'),
                ),
              ),
            ] else if (rental.status == RentalStatus.active) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(context, RentalStatus.completed);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Completed (Returned)'),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    rental.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Requested ${DateFormat('MMM d, y').format(rental.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tool info
            FutureBuilder<Tool?>(
              future: firestoreService.getToolStream(rental.toolId).first,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final tool = snapshot.data!;
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: tool.images.isNotEmpty
                          ? Image.network(
                              tool.images.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.handyman),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(rental.startDate)} - ${dateFormat.format(rental.endDate)} · ${rental.days} days',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${rental.totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'total',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            // Message
            if (rental.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showAsRenter ? 'Your message:' : 'Renter\'s message:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rental.message!),
                  ],
                ),
              ),
            ],

            // Owner notes
            if (rental.ownerNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner notes:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rental.ownerNotes!),
                  ],
                ),
              ),
            ],

            // Action button for owner
            if (!showAsRenter && 
                (rental.status == RentalStatus.pending ||
                 rental.status == RentalStatus.approved ||
                 rental.status == RentalStatus.active)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showOwnerActions(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Update Status'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
