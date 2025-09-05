import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../config/environment.dart';
import '../utils/error_handler.dart';
import '../utils/retry_mechanism.dart';
import 'connectivity_service.dart';
import 'image_processing_service.dart';

// Data models for AI vision service
class Ingredient {
  final String name;
  final double confidence;
  final String category;

  const Ingredient({
    required this.name,
    required this.confidence,
    required this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'category': category,
    };
  }

  @override
  String toString() => 'Ingredient(name: $name, confidence: $confidence, category: $category)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.name == name &&
        other.confidence == confidence &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(name, confidence, category);
}

class FoodRecognitionResult {
  final List<Ingredient> ingredients;
  final double confidence;
  final int processingTime;
  final String? errorMessage;
  final bool isSuccess;

  const FoodRecognitionResult({
    required this.ingredients,
    required this.confidence,
    required this.processingTime,
    this.errorMessage,
    this.isSuccess = true,
  });

  factory FoodRecognitionResult.success({
    required List<Ingredient> ingredients,
    required double confidence,
    required int processingTime,
  }) {
    return FoodRecognitionResult(
      ingredients: ingredients,
      confidence: confidence,
      processingTime: processingTime,
      isSuccess: true,
    );
  }

  factory FoodRecognitionResult.failure({
    required String errorMessage,
    required int processingTime,
  }) {
    return FoodRecognitionResult(
      ingredients: [],
      confidence: 0.0,
      processingTime: processingTime,
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    return 'FoodRecognitionResult(ingredients: $ingredients, confidence: $confidence, '
           'processingTime: $processingTime, isSuccess: $isSuccess, errorMessage: $errorMessage)';
  }
}

// AI vision service interface
abstract class AIVisionServiceInterface {
  Future<FoodRecognitionResult> analyzeImage(String imageUri);
  Future<bool> validateImageQuality(String imageUri);
  Future<String> processImageForAPI(String imageUri);
  void dispose();
}

// AI vision service implementation
class AIVisionService with ConnectivityAware, RetryCapable implements AIVisionServiceInterface {
  static const String _visionEndpoint = '/chat/completions';
  
  late final Dio _dio;
  final String _apiKey;
  late final ImageProcessingServiceInterface _imageProcessingService;

  AIVisionService({
    required String apiKey, 
    Dio? dio,
    ImageProcessingServiceInterface? imageProcessingService,
  }) : _apiKey = apiKey {
    if (dio != null) {
      _dio = dio;
    } else {
      _initializeDio();
    }
    _imageProcessingService = imageProcessingService ?? ImageProcessingServiceFactory.create();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: EnvironmentConfig.apiTimeout,
      receiveTimeout: EnvironmentConfig.apiTimeout,
      sendTimeout: EnvironmentConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
    ));

    // Add logging interceptor in debug mode
    if (EnvironmentConfig.isDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // Don't log image data
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  @override
  Future<FoodRecognitionResult> analyzeImage(String imageUri) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      // Check network connectivity
      requireNetwork();
      
      // Validate image quality first
      final bool isValidImage = await validateImageQuality(imageUri);
      if (!isValidImage) {
        throw ProcessingError.invalidImage();
      }

      // Process image for API transmission using optimized service
      final ImageProcessingResult processingResult = await _imageProcessingService.processImageForAPI(imageUri);
      debugPrint('Image processing result: $processingResult');
      
      // Perform analysis with retry logic
      final Map<String, dynamic> response = await retryNetworkOperation(() => 
          _performAnalysis(processingResult.base64Image));
      
      // Parse the response
      final FoodRecognitionResult result = _parseAnalysisResponse(response, stopwatch.elapsedMilliseconds);
      
      debugPrint('Food recognition completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
      
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      final appError = ErrorHandler().createAppError(e);
      return FoodRecognitionResult.failure(
        errorMessage: ErrorHandler().handleError(appError),
        processingTime: stopwatch.elapsedMilliseconds,
      );
    } finally {
      stopwatch.stop();
    }
  }

  Future<Map<String, dynamic>> _performAnalysis(String base64Image) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio.post(
        _visionEndpoint,
        data: _buildAnalysisRequest(base64Image),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw NetworkError.serverError(response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  AppError _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError.timeout();
      case DioExceptionType.badResponse:
        final int? statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return NetworkError(
            message: 'Authentication failed. Please check your API key.',
            recoverable: false,
          );
        } else if (statusCode == 429) {
          return NetworkError.rateLimited();
        } else {
          return NetworkError.serverError(statusCode);
        }
      case DioExceptionType.cancel:
        return NetworkError(
          message: 'Request was cancelled.',
          recoverable: false,
        );
      case DioExceptionType.connectionError:
        return NetworkError.noConnection();
      default:
        return NetworkError(
          message: 'Network error occurred.',
          technicalDetails: e.toString(),
        );
    }
  }

  Map<String, dynamic> _buildAnalysisRequest(String base64Image) {
    return {
      'model': 'gpt-4-vision-preview',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _getStructuredPrompt(),
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'max_tokens': 1000,
      'temperature': 0.1, // Low temperature for consistent results
    };
  }

  String _getStructuredPrompt() {
    return '''
Analyze this food image and identify all visible ingredients with confidence scores.

Return your response as a JSON object with this exact structure:
{
  "ingredients": [
    {
      "name": "ingredient_name",
      "confidence": 0.95,
      "category": "category_name"
    }
  ],
  "overall_confidence": 0.90
}

Guidelines:
- Only identify ingredients you can clearly see in the image
- Use confidence scores from 0.0 to 1.0 (1.0 = completely certain)
- Categories should be: "protein", "vegetable", "fruit", "grain", "dairy", "spice", "herb", "sauce", "other"
- Be specific with ingredient names (e.g., "red bell pepper" not just "pepper")
- Include overall confidence for the entire analysis
- If no food is visible, return empty ingredients array with overall_confidence: 0.0
- Minimum confidence threshold: 0.3 (don't include ingredients below this)

Return only the JSON object, no additional text.
''';
  }

  FoodRecognitionResult _parseAnalysisResponse(Map<String, dynamic> response, int processingTime) {
    try {
      final List<dynamic>? choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AIVisionServiceException('No analysis results in response');
      }

      final Map<String, dynamic>? message = choices[0]['message'] as Map<String, dynamic>?;
      final String? content = message?['content'] as String?;
      
      if (content == null || content.isEmpty) {
        throw AIVisionServiceException('Empty response content');
      }

      // Parse JSON response
      final Map<String, dynamic> analysisResult = jsonDecode(content);
      
      final List<dynamic>? ingredientsJson = analysisResult['ingredients'] as List<dynamic>?;
      final double overallConfidence = (analysisResult['overall_confidence'] as num?)?.toDouble() ?? 0.0;
      
      if (ingredientsJson == null) {
        throw ProcessingError.serviceFailure('Invalid response format: missing ingredients');
      }

      final List<Ingredient> ingredients = ingredientsJson
          .map((json) => Ingredient.fromJson(json as Map<String, dynamic>))
          .where((ingredient) => ingredient.confidence >= 0.3) // Filter low confidence
          .toList();

      // Check if no food was detected
      if (ingredients.isEmpty && overallConfidence < 0.3) {
        throw ProcessingError.noFoodDetected();
      }

      // Sort by confidence (highest first)
      ingredients.sort((a, b) => b.confidence.compareTo(a.confidence));

      return FoodRecognitionResult.success(
        ingredients: ingredients,
        confidence: overallConfidence,
        processingTime: processingTime,
      );
      
    } catch (e) {
      debugPrint('Error parsing analysis response: $e');
      if (e is ProcessingError) {
        rethrow;
      }
      throw ProcessingError.serviceFailure('Failed to parse analysis response: $e');
    }
  }

  @override
  Future<bool> validateImageQuality(String imageUri) async {
    return await _imageProcessingService.validateImageQuality(imageUri);
  }

  @override
  Future<String> processImageForAPI(String imageUri) async {
    final ImageProcessingResult result = await _imageProcessingService.processImageForAPI(imageUri);
    return result.base64Image;
  }

  String _getErrorMessage(dynamic error) {
    if (error is AIVisionServiceException) {
      return error.message;
    } else if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final int? statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Authentication failed. Please check your API key.';
          } else if (statusCode == 429) {
            return 'Too many requests. Please try again later.';
          } else if (statusCode == 500) {
            return 'Server error. Please try again later.';
          }
          return 'Server returned error: $statusCode';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Connection error. Please check your internet connection.';
        default:
          return 'Network error occurred.';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  @override
  void dispose() {
    _dio.close();
    _imageProcessingService.dispose();
    debugPrint('AI Vision Service disposed');
  }
}

// AI vision service exceptions
class AIVisionServiceException implements Exception {
  final String message;
  final String? code;
  
  const AIVisionServiceException(this.message, {this.code});
  
  @override
  String toString() => 'AIVisionServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

// AI vision service factory
class AIVisionServiceFactory {
  static AIVisionServiceInterface create({required String apiKey}) {
    return AIVisionService(apiKey: apiKey);
  }
}