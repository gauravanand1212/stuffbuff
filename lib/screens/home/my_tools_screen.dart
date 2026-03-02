import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/tool.dart';
import '../../services/firestore_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../listing/add_tool_screen.dart';
import '../listing/tool_detail_screen.dart';

class MyToolsScreen extends StatelessWidget {
  const MyToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Center(child: Text('Please sign in'));
        }

        final userId = state.user.id;
        final firestoreService = FirestoreService();

        return StreamBuilder<List<Tool>>(
          stream: firestoreService.getUserToolsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tools = snapshot.data!;

            if (tools.isEmpty) {
              return _EmptyState(
                onAddTool: () => _navigateToAddTool(context),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _MyToolCard(
                  tool: tool,
                  onTap: () => _navigateToDetail(context, tool),
                  onEdit: () => _navigateToEdit(context, tool),
                  onDelete: () => _confirmDelete(context, tool),
                  onToggleAvailability: () => _toggleAvailability(context, tool),
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToAddTool(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddToolScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, Tool tool) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)),
    );
  }

  void _navigateToEdit(BuildContext context, Tool tool) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddToolScreen(tool: tool)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Tool tool) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool?'),
        content: Text('Are you sure you want to delete "${tool.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService().deleteTool(tool.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tool deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tool: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleAvailability(BuildContext context, Tool tool) async {
    try {
      final updatedTool = tool.copyWith(isAvailable: !tool.isAvailable);
      await FirestoreService().updateTool(updatedTool);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tool.isAvailable 
              ? 'Tool marked as unavailable' 
              : 'Tool marked as available'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tool: $e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTool;

  const _EmptyState({required this.onAddTool});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Tools Listed Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'List your tools and start earning by renting them out to your neighbors!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddTool,
              icon: const Icon(Icons.add),
              label: const Text('List Your First Tool'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _MyToolCard({
    required this.tool,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image with availability badge
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: tool.images.isNotEmpty
                    ? Image.network(
                        tool.images.first,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.handyman,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tool.isAvailable ? Colors.green : Colors.grey[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tool.isAvailable ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${tool.pricePerDay.toStringAsFixed(0)}/day',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.category.displayName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onToggleAvailability,
                          icon: Icon(tool.isAvailable 
                            ? Icons.visibility_off 
                            : Icons.visibility),
                          label: Text(tool.isAvailable 
                            ? 'Mark Unavailable' 
                            : 'Mark Available'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
