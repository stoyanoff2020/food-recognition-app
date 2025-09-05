import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/firebase_config.dart';
import 'providers/app_state_provider.dart';
import 'providers/camera_provider.dart';
import 'services/camera_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );
  
  // Initialize Analytics Service
  await AnalyticsService().initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Log app startup
  final startTime = DateTime.now();
  
  runApp(const FoodRecognitionApp());
  
  // Log startup time
  final startupDuration = DateTime.now().difference(startTime);
  await AnalyticsService().logAppStartup(startupDuration);
}

class FoodRecognitionApp extends StatelessWidget {
  const FoodRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppStateProvider(),
        ),
        ChangeNotifierProxyProvider<AppStateProvider, CameraProvider>(
          create: (context) => CameraProvider(
            CameraServiceFactory.create(),
            Provider.of<AppStateProvider>(context, listen: false),
          ),
          update: (context, appState, previous) => previous ?? CameraProvider(
            CameraServiceFactory.create(),
            appState,
          ),
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final router = AppRouter.createRouter();
          
          return MaterialApp.router(
            title: 'Food Recognition App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
