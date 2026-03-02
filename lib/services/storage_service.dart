import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadToolImage(File file, String userId) async {
    try {
      // Compress image
      final compressedFile = await _compressImage(file);
      
      // Generate unique filename
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('tools/$userId/$fileName');
      
      // Upload
      final uploadTask = await ref.putFile(compressedFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Clean up compressed file if it was created
      if (compressedFile.path != file.path) {
        await compressedFile.delete();
      }
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 1200,
      minHeight: 1200,
    );
    
    return result != null ? File(result.path) : file;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log but don't throw - image might already be deleted
      print('Failed to delete image: $e');
    }
  }
}