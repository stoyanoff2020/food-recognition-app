import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Image processing configuration
class ImageProcessingConfig {
  static const int maxImageSizeBytes = 4 * 1024 * 1024; // 4MB
  static const int compressionQuality = 85;
  static const int maxWidth = 1024;
  static const int maxHeight = 1024;
  static const int minWidth = 100;
  static const int minHeight = 100;
  static const Duration cacheMaxAge = Duration(days: 7);
  static const int maxCacheObjects = 100;
}

// Image processing result
class ImageProcessingResult {
  final String base64Image;
  final int originalSize;
  final int processedSize;
  final int processingTime;
  final bool fromCache;
  final String cacheKey;

  const ImageProcessingResult({
    required this.base64Image,
    required this.originalSize,
    required this.processedSize,
    required this.processingTime,
    required this.fromCache,
    required this.cacheKey,
  });

  double get compressionRatio => originalSize > 0 ? processedSize / originalSize : 0.0;

  @override
  String toString() {
    return 'ImageProcessingResult(originalSize: $originalSize, processedSize: $processedSize, '
           'compressionRatio: ${compressionRatio.toStringAsFixed(2)}, '
           'processingTime: ${processingTime}ms, fromCache: $fromCache)';
  }
}

// Image processing parameters for isolate
class ImageProcessingParams {
  final String imagePath;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final SendPort sendPort;

  const ImageProcessingParams({
    required this.imagePath,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.sendPort,
  });
}

// Image processing service interface
abstract class ImageProcessingServiceInterface {
  Future<ImageProcessingResult> processImageForAPI(String imageUri);
  Future<bool> validateImageQuality(String imageUri);
  Future<void> clearCache();
  Future<int> getCacheSize();
  void dispose();
}

// Optimized image processing service with caching and background processing
class ImageProcessingService implements ImageProcessingServiceInterface {
  static const String _cacheKey = 'image_processing_cache';
  
  late final DefaultCacheManager _cacheManager;
  final Map<String, Completer<ImageProcessingResult>> _processingQueue = {};
  
  ImageProcessingService() {
    _initializeCacheManager();
  }

  void _initializeCacheManager() {
    _cacheManager = DefaultCacheManager();
  }

  @override
  Future<ImageProcessingResult> processImageForAPI(String imageUri) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      // Generate cache key based on file path and modification time
      final String cacheKey = await _generateCacheKey(imageUri);
      
      // Check if already processing this image
      if (_processingQueue.containsKey(cacheKey)) {
        debugPrint('Image already being processed, waiting for result...');
        return await _processingQueue[cacheKey]!.future;
      }
      
      // Check cache first
      final ImageProcessingResult? cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('Using cached processed image: $cacheKey');
        return ImageProcessingResult(
          base64Image: cachedResult.base64Image,
          originalSize: cachedResult.originalSize,
          processedSize: cachedResult.processedSize,
          processingTime: stopwatch.elapsedMilliseconds,
          fromCache: true,
          cacheKey: cacheKey,
        );
      }
      
      // Create completer for this processing task
      final Completer<ImageProcessingResult> completer = Completer<ImageProcessingResult>();
      _processingQueue[cacheKey] = completer;
      
      try {
        // Get original file size
        final File imageFile = File(imageUri);
        final int originalSize = await imageFile.length();
        
        // Process image in background isolate for large images
        final ImageProcessingResult result;
        if (originalSize > 1024 * 1024) { // 1MB threshold for background processing
          debugPrint('Processing large image in background isolate...');
          result = await _processImageInIsolate(imageUri, originalSize, cacheKey, stopwatch.elapsedMilliseconds);
        } else {
          debugPrint('Processing image in main thread...');
          result = await _processImageInMainThread(imageUri, originalSize, cacheKey, stopwatch.elapsedMilliseconds);
        }
        
        // Cache the result
        await _cacheResult(cacheKey, result);
        
        completer.complete(result);
        return result;
        
      } catch (e) {
        completer.completeError(e);
        rethrow;
      } finally {
        _processingQueue.remove(cacheKey);
      }
      
    } catch (e) {
      debugPrint('Error processing image: $e');
      throw ImageProcessingException('Failed to process image: $e');
    } finally {
      stopwatch.stop();
    }
  }

  Future<String> _generateCacheKey(String imageUri) async {
    final File imageFile = File(imageUri);
    final FileStat stat = await imageFile.stat();
    final String input = '$imageUri-${stat.modified.millisecondsSinceEpoch}-${stat.size}';
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<ImageProcessingResult?> _getCachedResult(String cacheKey) async {
    try {
      final FileInfo? fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      if (fileInfo != null && fileInfo.validTill.isAfter(DateTime.now())) {
        final String cachedData = await fileInfo.file.readAsString();
        final Map<String, dynamic> json = jsonDecode(cachedData);
        
        return ImageProcessingResult(
          base64Image: json['base64Image'] as String,
          originalSize: json['originalSize'] as int,
          processedSize: json['processedSize'] as int,
          processingTime: 0, // Will be updated with actual retrieval time
          fromCache: true,
          cacheKey: cacheKey,
        );
      }
    } catch (e) {
      debugPrint('Error retrieving cached result: $e');
    }
    return null;
  }

  Future<void> _cacheResult(String cacheKey, ImageProcessingResult result) async {
    try {
      final Map<String, dynamic> cacheData = {
        'base64Image': result.base64Image,
        'originalSize': result.originalSize,
        'processedSize': result.processedSize,
        'processingTime': result.processingTime,
        'cacheKey': result.cacheKey,
      };
      
      final String jsonData = jsonEncode(cacheData);
      final Uint8List bytes = utf8.encode(jsonData);
      
      await _cacheManager.putFile(
        cacheKey,
        bytes,
        maxAge: ImageProcessingConfig.cacheMaxAge,
      );
      
      debugPrint('Cached processed image: $cacheKey (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Error caching result: $e');
    }
  }

  Future<ImageProcessingResult> _processImageInIsolate(
    String imageUri,
    int originalSize,
    String cacheKey,
    int startTime,
  ) async {
    final ReceivePort receivePort = ReceivePort();
    
    try {
      await Isolate.spawn(
        _imageProcessingIsolate,
        ImageProcessingParams(
          imagePath: imageUri,
          maxWidth: ImageProcessingConfig.maxWidth,
          maxHeight: ImageProcessingConfig.maxHeight,
          quality: ImageProcessingConfig.compressionQuality,
          sendPort: receivePort.sendPort,
        ),
      );
      
      final dynamic result = await receivePort.first;
      
      if (result is String) {
        // Success - result is base64 string
        final List<int> processedBytes = base64Decode(result);
        
        return ImageProcessingResult(
          base64Image: result,
          originalSize: originalSize,
          processedSize: processedBytes.length,
          processingTime: DateTime.now().millisecondsSinceEpoch - startTime,
          fromCache: false,
          cacheKey: cacheKey,
        );
      } else {
        // Error
        throw ImageProcessingException(result.toString());
      }
      
    } finally {
      receivePort.close();
    }
  }

  static void _imageProcessingIsolate(ImageProcessingParams params) {
    try {
      // Read and decode image
      final File imageFile = File(params.imagePath);
      final Uint8List imageBytes = imageFile.readAsBytesSync();
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        params.sendPort.send('Unable to decode image');
        return;
      }
      
      // Resize if necessary
      img.Image processedImage = image;
      if (image.width > params.maxWidth || image.height > params.maxHeight) {
        // Calculate new dimensions maintaining aspect ratio
        final double aspectRatio = image.width / image.height;
        int newWidth, newHeight;
        
        if (image.width > image.height) {
          newWidth = params.maxWidth;
          newHeight = (params.maxWidth / aspectRatio).round();
        } else {
          newHeight = params.maxHeight;
          newWidth = (params.maxHeight * aspectRatio).round();
        }
        
        processedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Compress image
      final List<int> compressedBytes = img.encodeJpg(processedImage, quality: params.quality);
      
      // Convert to base64
      final String base64Image = base64Encode(compressedBytes);
      
      params.sendPort.send(base64Image);
      
    } catch (e) {
      params.sendPort.send('Error processing image in isolate: $e');
    }
  }

  Future<ImageProcessingResult> _processImageInMainThread(
    String imageUri,
    int originalSize,
    String cacheKey,
    int startTime,
  ) async {
    final File imageFile = File(imageUri);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    // Decode image
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ImageProcessingException('Unable to decode image');
    }
    
    // Resize if necessary
    img.Image processedImage = image;
    if (image.width > ImageProcessingConfig.maxWidth || 
        image.height > ImageProcessingConfig.maxHeight) {
      
      final double aspectRatio = image.width / image.height;
      int newWidth, newHeight;
      
      if (image.width > image.height) {
        newWidth = ImageProcessingConfig.maxWidth;
        newHeight = (ImageProcessingConfig.maxWidth / aspectRatio).round();
      } else {
        newHeight = ImageProcessingConfig.maxHeight;
        newWidth = (ImageProcessingConfig.maxHeight * aspectRatio).round();
      }
      
      processedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }
    
    // Compress image
    final List<int> compressedBytes = img.encodeJpg(
      processedImage, 
      quality: ImageProcessingConfig.compressionQuality,
    );
    
    // Convert to base64
    final String base64Image = base64Encode(compressedBytes);
    
    return ImageProcessingResult(
      base64Image: base64Image,
      originalSize: originalSize,
      processedSize: compressedBytes.length,
      processingTime: DateTime.now().millisecondsSinceEpoch - startTime,
      fromCache: false,
      cacheKey: cacheKey,
    );
  }

  @override
  Future<bool> validateImageQuality(String imageUri) async {
    try {
      final File imageFile = File(imageUri);
      
      // Check if file exists
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: $imageUri');
        return false;
      }

      // Check file size
      final int fileSize = await imageFile.length();
      if (fileSize == 0) {
        debugPrint('Image file is empty');
        return false;
      }

      if (fileSize > ImageProcessingConfig.maxImageSizeBytes) {
        debugPrint('Image file too large: ${fileSize}bytes > ${ImageProcessingConfig.maxImageSizeBytes}bytes');
        return false;
      }

      // Try to decode the image to validate format
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        debugPrint('Unable to decode image - invalid format');
        return false;
      }

      // Check minimum dimensions
      if (image.width < ImageProcessingConfig.minWidth || 
          image.height < ImageProcessingConfig.minHeight) {
        debugPrint('Image too small: ${image.width}x${image.height}');
        return false;
      }

      debugPrint('Image validation passed: ${image.width}x${image.height}, ${fileSize}bytes');
      return true;
      
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('Image processing cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      // Get cache directory
      final Directory cacheDir = await getTemporaryDirectory();
      final Directory flutterCacheDir = Directory(path.join(cacheDir.path, 'libCachedImageData'));
      
      if (!await flutterCacheDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final FileSystemEntity entity in flutterCacheDir.list(recursive: true)) {
        if (entity is File) {
          final FileStat stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    // Cancel any pending processing tasks
    for (final Completer<ImageProcessingResult> completer in _processingQueue.values) {
      if (!completer.isCompleted) {
        completer.completeError(ImageProcessingException('Service disposed'));
      }
    }
    _processingQueue.clear();
    
    debugPrint('Image Processing Service disposed');
  }
}

// Image processing exceptions
class ImageProcessingException implements Exception {
  final String message;
  
  const ImageProcessingException(this.message);
  
  @override
  String toString() => 'ImageProcessingException: $message';
}

// Image processing service factory
class ImageProcessingServiceFactory {
  static ImageProcessingServiceInterface create() {
    return ImageProcessingService();
  }
}