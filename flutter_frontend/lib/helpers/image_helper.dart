import 'dart:io';
import 'package:flutter/material.dart'; // ✅ TAMBAHKAN IMPORT INI
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageLocally(image);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImageLocally(image);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      return null;
    }
  }

  /// Save image to local app directory
  static Future<String> _saveImageLocally(XFile image) async {
    try {
      // Get application directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // Create products_images folder
      final String productImagesPath = path.join(appDir.path, 'products_images');
      final Directory productImagesDir = Directory(productImagesPath);
      
      if (!await productImagesDir.exists()) {
        await productImagesDir.create(recursive: true);
        print('📂 Created products_images directory');
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path);
      final String fileName = 'product_$timestamp$extension';
      final String savedPath = path.join(productImagesPath, fileName);

      // Copy file to app directory
      final File imageFile = File(image.path);
      await imageFile.copy(savedPath);

      print('✅ Image saved: $savedPath');
      return savedPath;
    } catch (e) {
      print('❌ Error saving image: $e');
      rethrow;
    }
  }

  /// Delete image from local storage
  static Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;

    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print('✅ Image deleted: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  /// Check if image exists
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get image file
  static File? getImageFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return File(imagePath);
  }

  /// Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String productImagesPath = path.join(appDir.path, 'products_images');
      final Directory productImagesDir = Directory(productImagesPath);

      int imageCount = 0;
      int totalSize = 0;

      if (await productImagesDir.exists()) {
        final List<FileSystemEntity> files = productImagesDir.listSync();
        imageCount = files.length;

        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return {
        'image_count': imageCount,
        'total_size_bytes': totalSize,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'storage_path': productImagesPath,
      };
    } catch (e) {
      print('❌ Error getting storage info: $e');
      return {
        'image_count': 0,
        'total_size_bytes': 0,
        'total_size_mb': '0.00',
        'storage_path': 'Error',
      };
    }
  }

  /// Clean up orphaned images (images not referenced in database)
  static Future<int> cleanupOrphanedImages(List<String?> usedImagePaths) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String productImagesPath = path.join(appDir.path, 'products_images');
      final Directory productImagesDir = Directory(productImagesPath);

      if (!await productImagesDir.exists()) return 0;

      int deletedCount = 0;
      final List<FileSystemEntity> files = productImagesDir.listSync();

      for (var file in files) {
        if (file is File) {
          final String filePath = file.path;
          if (!usedImagePaths.contains(filePath)) {
            await file.delete();
            deletedCount++;
            print('🗑️ Deleted orphaned image: $filePath');
          }
        }
      }

      print('✅ Cleanup completed: $deletedCount orphaned images deleted');
      return deletedCount;
    } catch (e) {
      print('❌ Error cleaning up images: $e');
      return 0;
    }
  }
}