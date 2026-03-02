import 'package:flutter/material.dart';
import '../../models/tool.dart';
import 'request_rental_screen.dart';

class ToolDetailScreen extends StatelessWidget {
  final Tool tool;

  const ToolDetailScreen({
    super.key,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: tool.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: tool.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          tool.images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.handyman,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tool.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${tool.pricePerDay.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Text('/day'),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Category
                Chip(
                  label: Text(tool.category.displayName),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                
                const SizedBox(height: 24),
                
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tool.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Availability
                if (tool.location != null) ...[
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(tool.location!),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Owner info
                const Text(
                  'Owner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tool Owner',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (tool.rating != null)
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                Text(' ${tool.rating!.toStringAsFixed(1)}'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      
      // Rent button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: tool.isAvailable
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestRentalScreen(tool: tool),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              tool.isAvailable ? 'Request to Rent' : 'Currently Unavailable',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}