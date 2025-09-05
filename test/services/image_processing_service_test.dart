import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../lib/services/image_processing_service.dart';

// Generate mocks
@GenerateMocks([])
class MockImageProcessingService extends Mock implements ImageProcessingServiceInterface {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ImageProcessingService', () {
    late ImageProcessingService service;
    late Directory tempDir;
    late String testImagePath;

    setUpAll(() async {
      // Create test directory
      tempDir = await Directory.systemTemp.createTemp('image_processing_test');
      
      // Create a test image
      testImagePath = await _createTestImage(tempDir);
    });

    setUp(() {
      service = ImageProcessingService();
    });

    tearDown(() {
      service.dispose();
    });

    tearDownAll(() async {
      // Clean up test directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Image Validation', () {
      test('should validate good quality image', () async {
        final bool isValid = await service.validateImageQuality(testImagePath);
        expect(isValid, isTrue);
      });

      test('should reject non-existent image', () async {
        final bool isValid = await service.validateImageQuality('/non/existent/path.jpg');
        expect(isValid, isFalse);
      });

      test('should reject empty image file', () async {
        final String emptyImagePath = path.join(tempDir.path, 'empty.jpg');
        await File(emptyImagePath).create();
        
        final bool isValid = await service.validateImageQuality(emptyImagePath);
        expect(isValid, isFalse);
      });

      test('should reject too small image', () async {
        final String smallImagePath = await _createSmallTestImage(tempDir);
        final bool isValid = await service.validateImageQuality(smallImagePath);
        expect(isValid, isFalse);
      });

      test('should reject too large image', () async {
        final String largeImagePath = await _createLargeTestImage(tempDir);
        final bool isValid = await service.validateImageQuality(largeImagePath);
        expect(isValid, isFalse);
      });
    });

    group('Image Processing', () {
      test('should process image and return base64', () async {
        final ImageProcessingResult result = await service.processImageForAPI(testImagePath);
        
        expect(result.base64Image, isNotEmpty);
        expect(result.originalSize, greaterThan(0));
        expect(result.processedSize, greaterThan(0));
        expect(result.processingTime, greaterThanOrEqualTo(0));
        expect(result.cacheKey, isNotEmpty);
        
        // Verify base64 is valid
        expect(() => base64Decode(result.base64Image), returnsNormally);
      });

      test('should compress large images', () async {
        final String largeImagePath = await _createLargeValidTestImage(tempDir);
        final ImageProcessingResult result = await service.processImageForAPI(largeImagePath);
        
        expect(result.processedSize, lessThan(result.originalSize));
        expect(result.compressionRatio, lessThan(1.0));
      });

      test('should cache processed images', () async {
        // First processing
        final ImageProcessingResult result1 = await service.processImageForAPI(testImagePath);
        expect(result1.fromCache, isFalse);
        
        // Second processing should use cache
        final ImageProcessingResult result2 = await service.processImageForAPI(testImagePath);
        expect(result2.fromCache, isTrue);
        expect(result2.base64Image, equals(result1.base64Image));
        expect(result2.cacheKey, equals(result1.cacheKey));
      });

      test('should handle concurrent processing requests', () async {
        // Start multiple processing requests for the same image
        final List<Future<ImageProcessingResult>> futures = List.generate(
          5,
          (_) => service.processImageForAPI(testImagePath),
        );
        
        final List<ImageProcessingResult> results = await Future.wait(futures);
        
        // All results should be identical
        for (int i = 1; i < results.length; i++) {
          expect(results[i].base64Image, equals(results[0].base64Image));
          expect(results[i].cacheKey, equals(results[0].cacheKey));
        }
      });
    });

    group('Performance Tests', () {
      test('should process small image quickly', () async {
        final Stopwatch stopwatch = Stopwatch()..start();
        
        await service.processImageForAPI(testImagePath);
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be under 1 second
      });

      test('should handle multiple images efficiently', () async {
        final List<String> imagePaths = await _createMultipleTestImages(tempDir, 5);
        
        final Stopwatch stopwatch = Stopwatch()..start();
        
        final List<Future<ImageProcessingResult>> futures = imagePaths
            .map((path) => service.processImageForAPI(path))
            .toList();
        
        await Future.wait(futures);
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should process 5 images under 5 seconds
      });

      test('should show performance improvement with caching', () async {
        // First processing (no cache)
        final Stopwatch stopwatch1 = Stopwatch()..start();
        await service.processImageForAPI(testImagePath);
        stopwatch1.stop();
        
        // Second processing (with cache)
        final Stopwatch stopwatch2 = Stopwatch()..start();
        await service.processImageForAPI(testImagePath);
        stopwatch2.stop();
        
        // Cached version should be significantly faster
        expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
      });

      test('should maintain quality while compressing', () async {
        final String largeImagePath = await _createLargeValidTestImage(tempDir);
        final ImageProcessingResult result = await service.processImageForAPI(largeImagePath);
        
        // Decode the processed image to verify it's still valid
        final Uint8List processedBytes = base64Decode(result.base64Image);
        final img.Image? processedImage = img.decodeImage(processedBytes);
        
        expect(processedImage, isNotNull);
        expect(processedImage!.width, lessThanOrEqualTo(1024));
        expect(processedImage.height, lessThanOrEqualTo(1024));
        expect(processedImage.width, greaterThanOrEqualTo(100));
        expect(processedImage.height, greaterThanOrEqualTo(100));
      });
    });

    group('Cache Management', () {
      test('should clear cache', () async {
        // Process an image to create cache
        await service.processImageForAPI(testImagePath);
        
        // Clear cache
        await service.clearCache();
        
        // Next processing should not be from cache
        final ImageProcessingResult result = await service.processImageForAPI(testImagePath);
        expect(result.fromCache, isFalse);
      });

      test('should calculate cache size', () async {
        // Process multiple images to create cache
        final List<String> imagePaths = await _createMultipleTestImages(tempDir, 3);
        
        for (final String imagePath in imagePaths) {
          await service.processImageForAPI(imagePath);
        }
        
        final int cacheSize = await service.getCacheSize();
        expect(cacheSize, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('should handle invalid image gracefully', () async {
        final String invalidImagePath = path.join(tempDir.path, 'invalid.txt');
        await File(invalidImagePath).writeAsString('This is not an image');
        
        expect(
          () => service.processImageForAPI(invalidImagePath),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('should handle corrupted image gracefully', () async {
        final String corruptedImagePath = path.join(tempDir.path, 'corrupted.jpg');
        await File(corruptedImagePath).writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // Invalid JPEG header
        
        expect(
          () => service.processImageForAPI(corruptedImagePath),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });
  });
}

// Helper functions for creating test images
Future<String> _createTestImage(Directory tempDir) async {
  final img.Image image = img.Image(width: 500, height: 500);
  img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Red image
  
  final List<int> imageBytes = img.encodeJpg(image);
  final String imagePath = path.join(tempDir.path, 'test_image.jpg');
  await File(imagePath).writeAsBytes(imageBytes);
  
  return imagePath;
}

Future<String> _createSmallTestImage(Directory tempDir) async {
  final img.Image image = img.Image(width: 50, height: 50);
  img.fill(image, color: img.ColorRgb8(0, 255, 0)); // Green image
  
  final List<int> imageBytes = img.encodeJpg(image);
  final String imagePath = path.join(tempDir.path, 'small_image.jpg');
  await File(imagePath).writeAsBytes(imageBytes);
  
  return imagePath;
}

Future<String> _createLargeTestImage(Directory tempDir) async {
  // Create a very large image that exceeds size limits
  final img.Image image = img.Image(width: 5000, height: 5000);
  img.fill(image, color: img.ColorRgb8(0, 0, 255)); // Blue image
  
  final List<int> imageBytes = img.encodeJpg(image, quality: 100); // High quality to increase size
  final String imagePath = path.join(tempDir.path, 'large_image.jpg');
  await File(imagePath).writeAsBytes(imageBytes);
  
  return imagePath;
}

Future<String> _createLargeValidTestImage(Directory tempDir) async {
  // Create a large but valid image for compression testing
  final img.Image image = img.Image(width: 2000, height: 2000);
  img.fill(image, color: img.ColorRgb8(128, 128, 128)); // Gray image
  
  final List<int> imageBytes = img.encodeJpg(image, quality: 90);
  final String imagePath = path.join(tempDir.path, 'large_valid_image.jpg');
  await File(imagePath).writeAsBytes(imageBytes);
  
  return imagePath;
}

Future<List<String>> _createMultipleTestImages(Directory tempDir, int count) async {
  final List<String> imagePaths = [];
  
  for (int i = 0; i < count; i++) {
    final img.Image image = img.Image(width: 300 + i * 50, height: 300 + i * 50);
    img.fill(image, color: img.ColorRgb8(i * 50, i * 40, i * 30));
    
    final List<int> imageBytes = img.encodeJpg(image);
    final String imagePath = path.join(tempDir.path, 'test_image_$i.jpg');
    await File(imagePath).writeAsBytes(imageBytes);
    
    imagePaths.add(imagePath);
  }
  
  return imagePaths;
}