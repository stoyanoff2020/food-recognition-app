import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image/image.dart' as img;

import '../../lib/services/ai_vision_service.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'ai_vision_service_test.mocks.dart';

void main() {
  group('AIVisionService', () {
    late MockDio mockDio;
    late AIVisionService aiVisionService;
    late String testImagePath;

    setUpAll(() async {
      // Create a test image file
      testImagePath = 'test/test_assets/test_image.jpg';
      await _createTestImage(testImagePath);
    });

    setUp(() {
      mockDio = MockDio();
      aiVisionService = AIVisionService(apiKey: 'test-api-key', dio: mockDio);
    });

    tearDown(() {
      aiVisionService.dispose();
    });

    tearDownAll(() async {
      // Clean up test image
      final file = File(testImagePath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    group('analyzeImage', () {
      test('should return successful result when API responds correctly', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'ingredients': [
                      {
                        'name': 'tomato',
                        'confidence': 0.95,
                        'category': 'vegetable',
                      },
                      {
                        'name': 'basil',
                        'confidence': 0.85,
                        'category': 'herb',
                      },
                    ],
                    'overall_confidence': 0.90,
                  }),
                },
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/chat/completions'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.ingredients, hasLength(2));
        expect(result.ingredients[0].name, equals('tomato'));
        expect(result.ingredients[0].confidence, equals(0.95));
        expect(result.ingredients[0].category, equals('vegetable'));
        expect(result.confidence, equals(0.90));
        expect(result.errorMessage, isNull);
        expect(result.processingTime, greaterThan(0));
      });

      test('should filter out low confidence ingredients', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'ingredients': [
                      {
                        'name': 'tomato',
                        'confidence': 0.95,
                        'category': 'vegetable',
                      },
                      {
                        'name': 'uncertain_item',
                        'confidence': 0.2, // Below threshold
                        'category': 'other',
                      },
                    ],
                    'overall_confidence': 0.80,
                  }),
                },
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/chat/completions'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.ingredients, hasLength(1)); // Low confidence item filtered out
        expect(result.ingredients[0].name, equals('tomato'));
      });

      test('should sort ingredients by confidence descending', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'ingredients': [
                      {
                        'name': 'basil',
                        'confidence': 0.75,
                        'category': 'herb',
                      },
                      {
                        'name': 'tomato',
                        'confidence': 0.95,
                        'category': 'vegetable',
                      },
                      {
                        'name': 'cheese',
                        'confidence': 0.85,
                        'category': 'dairy',
                      },
                    ],
                    'overall_confidence': 0.85,
                  }),
                },
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/chat/completions'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.ingredients, hasLength(3));
        expect(result.ingredients[0].name, equals('tomato')); // Highest confidence first
        expect(result.ingredients[1].name, equals('cheese'));
        expect(result.ingredients[2].name, equals('basil')); // Lowest confidence last
      });

      test('should return failure result when image validation fails', () async {
        // Act
        final result = await aiVisionService.analyzeImage('non_existent_file.jpg');

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.ingredients, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.errorMessage, contains('Invalid image quality'));
        expect(result.processingTime, greaterThanOrEqualTo(0));
      });

      test('should retry on network errors and eventually succeed', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'ingredients': [
                      {
                        'name': 'apple',
                        'confidence': 0.90,
                        'category': 'fruit',
                      },
                    ],
                    'overall_confidence': 0.90,
                  }),
                },
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/chat/completions'),
        );

        var callCount = 0;
        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async {
              callCount++;
              if (callCount == 1) {
                throw DioException(
                  requestOptions: RequestOptions(path: '/chat/completions'),
                  type: DioExceptionType.connectionTimeout,
                );
              }
              return mockResponse;
            });

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.ingredients, hasLength(1));
        expect(result.ingredients[0].name, equals('apple'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(2); // Retried once
      });

      test('should return failure after max retries exceeded', () async {
        // Arrange
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/chat/completions'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.ingredients, isEmpty);
        expect(result.errorMessage, contains('timed out'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(3); // Max retries
      });

      test('should not retry on authentication errors', () async {
        // Arrange
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/chat/completions'),
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: '/chat/completions'),
              ),
            ));

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Authentication failed'));
        verify(mockDio.post(any, data: anyNamed('data'))).called(1); // No retry
      });

      test('should handle malformed JSON response', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'choices': [
              {
                'message': {
                  'content': 'This is not valid JSON',
                },
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/chat/completions'),
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await aiVisionService.analyzeImage(testImagePath);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Failed to parse'));
      });
    });

    group('validateImageQuality', () {
      test('should return true for valid image', () async {
        // Act
        final result = await aiVisionService.validateImageQuality(testImagePath);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for non-existent file', () async {
        // Act
        final result = await aiVisionService.validateImageQuality('non_existent.jpg');

        // Assert
        expect(result, isFalse);
      });

      test('should return false for empty file', () async {
        // Arrange
        final emptyFilePath = 'test/test_assets/empty.jpg';
        final emptyFile = File(emptyFilePath);
        await emptyFile.create(recursive: true);
        await emptyFile.writeAsBytes([]);

        // Act
        final result = await aiVisionService.validateImageQuality(emptyFilePath);

        // Assert
        expect(result, isFalse);

        // Cleanup
        await emptyFile.delete();
      });

      test('should return false for invalid image format', () async {
        // Arrange
        final invalidFilePath = 'test/test_assets/invalid.jpg';
        final invalidFile = File(invalidFilePath);
        await invalidFile.create(recursive: true);
        await invalidFile.writeAsString('This is not an image');

        // Act
        final result = await aiVisionService.validateImageQuality(invalidFilePath);

        // Assert
        expect(result, isFalse);

        // Cleanup
        await invalidFile.delete();
      });
    });

    group('processImageForAPI', () {
      test('should return base64 encoded image', () async {
        // Act
        final result = await aiVisionService.processImageForAPI(testImagePath);

        // Assert
        expect(result, isNotEmpty);
        expect(result, isA<String>());
        
        // Verify it's valid base64
        expect(() => base64Decode(result), returnsNormally);
      });

      test('should resize large images', () async {
        // Arrange - Create a large test image (1500x1500 to trigger resize)
        final largeImagePath = 'test/test_assets/large_image.jpg';
        await _createTestImage(largeImagePath, width: 1500, height: 1500);

        // Act
        final result = await aiVisionService.processImageForAPI(largeImagePath);

        // Assert
        expect(result, isNotEmpty);
        
        // Decode and verify the image was resized
        final decodedBytes = base64Decode(result);
        final decodedImage = img.decodeImage(Uint8List.fromList(decodedBytes));
        expect(decodedImage, isNotNull);
        expect(decodedImage!.width, lessThanOrEqualTo(1024));
        expect(decodedImage.height, lessThanOrEqualTo(1024));

        // Cleanup
        await File(largeImagePath).delete();
      });

      test('should throw exception for invalid image', () async {
        // Arrange
        final invalidFilePath = 'test/test_assets/invalid_for_processing.jpg';
        final invalidFile = File(invalidFilePath);
        await invalidFile.create(recursive: true);
        await invalidFile.writeAsString('Invalid image data');

        // Act & Assert
        expect(
          () => aiVisionService.processImageForAPI(invalidFilePath),
          throwsA(isA<AIVisionServiceException>()),
        );

        // Cleanup
        await invalidFile.delete();
      });
    });

    group('Ingredient model', () {
      test('should create ingredient from JSON', () {
        // Arrange
        final json = {
          'name': 'tomato',
          'confidence': 0.95,
          'category': 'vegetable',
        };

        // Act
        final ingredient = Ingredient.fromJson(json);

        // Assert
        expect(ingredient.name, equals('tomato'));
        expect(ingredient.confidence, equals(0.95));
        expect(ingredient.category, equals('vegetable'));
      });

      test('should convert ingredient to JSON', () {
        // Arrange
        const ingredient = Ingredient(
          name: 'basil',
          confidence: 0.85,
          category: 'herb',
        );

        // Act
        final json = ingredient.toJson();

        // Assert
        expect(json['name'], equals('basil'));
        expect(json['confidence'], equals(0.85));
        expect(json['category'], equals('herb'));
      });

      test('should implement equality correctly', () {
        // Arrange
        const ingredient1 = Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable');
        const ingredient2 = Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable');
        const ingredient3 = Ingredient(name: 'basil', confidence: 0.85, category: 'herb');

        // Assert
        expect(ingredient1, equals(ingredient2));
        expect(ingredient1, isNot(equals(ingredient3)));
        expect(ingredient1.hashCode, equals(ingredient2.hashCode));
      });
    });

    group('FoodRecognitionResult model', () {
      test('should create success result', () {
        // Arrange
        const ingredients = [
          Ingredient(name: 'tomato', confidence: 0.95, category: 'vegetable'),
        ];

        // Act
        final result = FoodRecognitionResult.success(
          ingredients: ingredients,
          confidence: 0.90,
          processingTime: 1500,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.ingredients, equals(ingredients));
        expect(result.confidence, equals(0.90));
        expect(result.processingTime, equals(1500));
        expect(result.errorMessage, isNull);
      });

      test('should create failure result', () {
        // Act
        final result = FoodRecognitionResult.failure(
          errorMessage: 'Test error',
          processingTime: 500,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.ingredients, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.processingTime, equals(500));
        expect(result.errorMessage, equals('Test error'));
      });
    });

    group('AIVisionServiceFactory', () {
      test('should create AIVisionService instance', () {
        // Act
        final service = AIVisionServiceFactory.create(apiKey: 'test-key');

        // Assert
        expect(service, isA<AIVisionService>());
        
        // Cleanup
        service.dispose();
      });
    });
  });
}

// Helper function to create a test image
Future<void> _createTestImage(String path, {int width = 100, int height = 100}) async {
  final file = File(path);
  await file.create(recursive: true);
  
  // Create a simple test image
  final image = img.Image(width: width, height: height, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Red image
  
  final jpegBytes = img.encodeJpg(image);
  await file.writeAsBytes(jpegBytes);
}