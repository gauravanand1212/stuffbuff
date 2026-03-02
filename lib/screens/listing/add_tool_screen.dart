import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/tool.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class AddToolScreen extends StatefulWidget {
  final Tool? tool;

  const AddToolScreen({super.key, this.tool});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  
  ToolCategory _selectedCategory = ToolCategory.other;
  bool _isLoading = false;
  bool _isAvailable = true;

  bool get _isEditing => widget.tool != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.tool!.title;
      _descriptionController.text = widget.tool!.description;
      _priceController.text = widget.tool!.pricePerDay.toString();
      _locationController.text = widget.tool!.location ?? '';
      _selectedCategory = widget.tool!.category;
      _isAvailable = widget.tool!.isAvailable;
      _existingImages.addAll(widget.tool!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (final pickedFile in pickedFiles) {
          if (_newImages.length + _existingImages.length < 5) {
            _newImages.add(File(pickedFile.path));
          }
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (_newImages.length + _existingImages.length < 5) {
          _newImages.add(File(pickedFile.path));
        }
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);

    try {
      final userId = authState.user.id;
      final storageService = StorageService();
      final firestoreService = FirestoreService();

      // Upload new images
      final List<String> allImages = [..._existingImages];
      for (final imageFile in _newImages) {
        final url = await storageService.uploadToolImage(imageFile, userId);
        allImages.add(url);
      }

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final location = _locationController.text.trim();

      if (_isEditing) {
        // Update existing tool
        final updatedTool = widget.tool!.copyWith(
          title: title,
          description: description,
          pricePerDay: price,
          category: _selectedCategory,
          images: allImages,
          isAvailable: _isAvailable,
          location: location.isNotEmpty ? location : null,
        );
        await firestoreService.updateTool(updatedTool);
      } else {
        // Create new tool
        final newTool = Tool(
          id: '',
          ownerId: userId,
          title: title,
          description: description,
          pricePerDay: price,
          category: _selectedCategory,
          images: allImages,
          isAvailable: _isAvailable,
          createdAt: DateTime.now(),
          location: location.isNotEmpty ? location : null,
        );
        await firestoreService.createTool(newTool);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
              ? 'Tool updated successfully' 
              : 'Tool listed successfully'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _newImages.length + _existingImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tool' : 'List a Tool'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveTool,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 5 photos of your tool',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Image grid
            if (totalImages > 0) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Existing images
                  ..._existingImages.asMap().entries.map((entry) {
                    return _ImageTile(
                      imageUrl: entry.value,
                      onDelete: () => _removeExistingImage(entry.key),
                    );
                  }),
                  // New images
                  ..._newImages.asMap().entries.map((entry) {
                    return _ImageTile(
                      imageFile: entry.value,
                      onDelete: () => _removeNewImage(entry.key),
                    );
                  }),
                  // Add button
                  if (totalImages < 5)
                    _AddImageButton(onTap: _showImageSourceDialog),
                ],
              ),
            ] else ...[
              _AddImageButton(
                onTap: _showImageSourceDialog,
                isLarge: true,
              ),
            ],
            
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., DeWalt Cordless Drill',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<ToolCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: ToolCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the condition, features, and any usage instructions...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description should be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per Day (\$) *',
                hintText: 'e.g., 15.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                hintText: 'e.g., Downtown, Seattle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Availability (only when editing)
            if (_isEditing) ...[
              SwitchListTile(
                title: const Text('Available for Rent'),
                subtitle: const Text('Toggle to hide this tool from search'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _isEditing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveTool,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'List Tool',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback onDelete;

  const _ImageTile({
    this.imageUrl,
    this.imageFile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  imageFile!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLarge;

  const _AddImageButton({
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? double.infinity : 100,
        height: isLarge ? 200 : 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: isLarge ? 48 : 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            if (isLarge) ...[
              const SizedBox(height: 8),
              Text(
                'Add Photos',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
