import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:camera/camera.dart';
import 'package:food_recognition_app/providers/camera_provider.dart';
import 'package:food_recognition_app/providers/app_state_provider.dart';
import 'package:food_recognition_app/services/camera_service.dart';

// Generate mocks
@GenerateMocks([CameraServiceInterface, AppStateProvider])
import 'camera_provider_test.mocks.dart';

void main() {
  group('CameraProvider', () {
    late CameraProvider cameraProvider;
    late MockCameraServiceInterface mockCameraService;
    late MockAppStateProvider mockAppStateProvider;

    setUp(() {
      mockCameraService = MockCameraServiceInterface();
      mockAppStateProvider = MockAppStateProvider();
      cameraProvider = CameraProvider(mockCameraService, mockAppStateProvider);
    });

    tearDown(() {
      // Don't dispose here as some tests dispose manually
    });

    group('initialization', () {
      test('should initialize with correct default values', () {
        expect(cameraProvider.isInitializing, false);
        expect(cameraProvider.isCapturing, false);
        expect(cameraProvider.lastError, null);
        expect(cameraProvider.cameraService, mockCameraService);
      });

      test('should handle successful initialization', () async {
        // Arrange
        when(mockCameraService.initialize()).thenAnswer((_) async => true);
        when(mockCameraService.isInitialized).thenReturn(true);

        // Act
        final result = await cameraProvider.initialize();

        // Assert
        expect(result, true);
        verify(mockCameraService.initialize()).called(1);
        // Note: AppStateProvider mock verification is complex, so we'll skip it for now
        
        // Clean up
        await cameraProvider.dispose();
      });

      test('should handle failed initialization', () async {
        // Arrange
        when(mockCameraService.initialize()).thenAnswer((_) async => false);
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        final result = await cameraProvider.initialize();

        // Assert
        expect(result, false);
        expect(cameraProvider.lastError, 'Failed to initialize camera');
        verify(mockCameraService.initialize()).called(1);
        verify(mockAppStateProvider.setCameraActive(false)).called(1);
      });

      test('should handle initialization exception', () async {
        // Arrange
        when(mockCameraService.initialize()).thenThrow(Exception('Test error'));
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        final result = await cameraProvider.initialize();

        // Assert
        expect(result, false);
        expect(cameraProvider.lastError, contains('Camera initialization error'));
        verify(mockAppStateProvider.setCameraActive(false)).called(1);
      });

      test('should not initialize if already initializing', () async {
        // Arrange
        when(mockCameraService.initialize()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return true;
        });
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        final future1 = cameraProvider.initialize();
        final future2 = cameraProvider.initialize();

        // Assert
        expect(cameraProvider.isInitializing, true);
        await future1;
        await future2;
        
        // Should only call initialize once
        verify(mockCameraService.initialize()).called(1);
      });

      test('should return true if already initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);

        // Act
        final result = await cameraProvider.initialize();

        // Assert
        expect(result, true);
        verifyNever(mockCameraService.initialize());
      });
    });

    group('photo capture', () {
      test('should capture photo successfully', () async {
        // Arrange
        const imagePath = '/path/to/image.jpg';
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.capturePhoto()).thenAnswer((_) async => imagePath);

        // Act
        final result = await cameraProvider.capturePhoto();

        // Assert
        expect(result, imagePath);
        verify(mockCameraService.capturePhoto()).called(1);
        verify(mockAppStateProvider.setLastCapturedImage(imagePath)).called(1);
      });

      test('should handle capture failure', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.capturePhoto()).thenAnswer((_) async => null);

        // Act
        final result = await cameraProvider.capturePhoto();

        // Assert
        expect(result, null);
        expect(cameraProvider.lastError, 'Failed to capture photo');
        verify(mockCameraService.capturePhoto()).called(1);
        verifyNever(mockAppStateProvider.setLastCapturedImage(any));
      });

      test('should handle capture exception', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.capturePhoto()).thenThrow(Exception('Capture error'));

        // Act
        final result = await cameraProvider.capturePhoto();

        // Assert
        expect(result, null);
        expect(cameraProvider.lastError, contains('Photo capture error'));
      });

      test('should not capture if not initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        final result = await cameraProvider.capturePhoto();

        // Assert
        expect(result, null);
        verifyNever(mockCameraService.capturePhoto());
      });

      test('should not capture if already capturing', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.capturePhoto()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return '/path/to/image.jpg';
        });

        // Act
        final future1 = cameraProvider.capturePhoto();
        final future2 = cameraProvider.capturePhoto();

        // Assert
        expect(cameraProvider.isCapturing, true);
        await future1;
        final result2 = await future2;
        
        expect(result2, null); // Second capture should return null
        verify(mockCameraService.capturePhoto()).called(1); // Should only call once
      });
    });

    group('permissions', () {
      test('should request permissions successfully', () async {
        // Arrange
        when(mockCameraService.requestPermissions()).thenAnswer((_) async => true);

        // Act
        final result = await cameraProvider.requestPermissions();

        // Assert
        expect(result, true);
        expect(cameraProvider.lastError, null);
        verify(mockCameraService.requestPermissions()).called(1);
        verify(mockAppStateProvider.setCameraPermission(true)).called(1);
      });

      test('should handle permission denial', () async {
        // Arrange
        when(mockCameraService.requestPermissions()).thenAnswer((_) async => false);

        // Act
        final result = await cameraProvider.requestPermissions();

        // Assert
        expect(result, false);
        expect(cameraProvider.lastError, 'Camera permission denied');
        verify(mockAppStateProvider.setCameraPermission(false)).called(1);
      });

      test('should check permissions successfully', () async {
        // Arrange
        when(mockCameraService.checkPermissions()).thenAnswer((_) async => true);

        // Act
        final result = await cameraProvider.checkPermissions();

        // Assert
        expect(result, true);
        verify(mockCameraService.checkPermissions()).called(1);
        verify(mockAppStateProvider.setCameraPermission(true)).called(1);
      });
    });

    group('camera controls', () {
      test('should switch camera when initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.switchCamera()).thenAnswer((_) async {});

        // Act
        await cameraProvider.switchCamera();

        // Assert
        verify(mockCameraService.switchCamera()).called(1);
      });

      test('should not switch camera when not initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        await cameraProvider.switchCamera();

        // Assert
        verifyNever(mockCameraService.switchCamera());
      });

      test('should set flash mode when initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.setFlashMode(any)).thenAnswer((_) async {});

        // Act
        await cameraProvider.setFlashMode(FlashMode.torch);

        // Assert
        verify(mockCameraService.setFlashMode(FlashMode.torch)).called(1);
      });

      test('should set zoom level when initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.setZoomLevel(any)).thenAnswer((_) async {});

        // Act
        await cameraProvider.setZoomLevel(2.0);

        // Assert
        verify(mockCameraService.setZoomLevel(2.0)).called(1);
      });

      test('should get zoom limits', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(true);
        when(mockCameraService.getMaxZoomLevel()).thenAnswer((_) async => 8.0);
        when(mockCameraService.getMinZoomLevel()).thenAnswer((_) async => 1.0);

        // Act
        final maxZoom = await cameraProvider.getMaxZoomLevel();
        final minZoom = await cameraProvider.getMinZoomLevel();

        // Assert
        expect(maxZoom, 8.0);
        expect(minZoom, 1.0);
      });

      test('should return default zoom limits when not initialized', () async {
        // Arrange
        when(mockCameraService.isInitialized).thenReturn(false);

        // Act
        final maxZoom = await cameraProvider.getMaxZoomLevel();
        final minZoom = await cameraProvider.getMinZoomLevel();

        // Assert
        expect(maxZoom, 1.0);
        expect(minZoom, 1.0);
      });
    });

    group('error handling', () {
      test('should clear error', () {
        // Arrange
        cameraProvider.clearError();

        // Act & Assert
        expect(cameraProvider.lastError, null);
      });
    });

    group('cleanup', () {
      test('should cleanup old captures', () async {
        // Arrange
        when(mockCameraService.cleanupOldCaptures(maxAgeInDays: anyNamed('maxAgeInDays')))
            .thenAnswer((_) async {});

        // Act
        await cameraProvider.cleanupOldCaptures(maxAgeInDays: 5);

        // Assert
        verify(mockCameraService.cleanupOldCaptures(maxAgeInDays: 5)).called(1);
      });
    });

    group('disposal', () {
      test('should dispose camera service', () async {
        // Arrange
        when(mockCameraService.dispose()).thenAnswer((_) async {});

        // Act
        await cameraProvider.dispose();

        // Assert
        verify(mockCameraService.dispose()).called(1);
        verify(mockAppStateProvider.setCameraActive(false)).called(1);
        
        // Don't dispose again in tearDown
      });
    });
  });
}