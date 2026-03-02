import 'package:flutter/material.dart';
import '../../models/tool.dart';
import '../../services/firestore_service.dart';
import '../listing/tool_detail_screen.dart';

class BrowseToolsScreen extends StatefulWidget {
  const BrowseToolsScreen({super.key});

  @override
  State<BrowseToolsScreen> createState() => _BrowseToolsScreenState();
}

class _BrowseToolsScreenState extends State<BrowseToolsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  ToolCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: ToolCategory.values.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(null, 'All');
              }
              final category = ToolCategory.values[index - 1];
              return _buildCategoryChip(category, category.displayName);
            },
          ),
        ),
        
        // Tools list
        Expanded(
          child: StreamBuilder<List<Tool>>(
            stream: _firestoreService.getToolsStream(
              category: _selectedCategory,
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tools = snapshot.data!;

              if (tools.isEmpty) {
                return const Center(
                  child: Text('No tools available in this category'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  return _ToolCard(tool: tools[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(ToolCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Tool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ToolDetailScreen(tool: tool),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
            
            // Content
            Padding(
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
                  const SizedBox(height: 8),
                  Text(
                    tool.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}