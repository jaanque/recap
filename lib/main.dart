import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'config/database_config.dart';
import 'screens/splash_screen.dart';

// Variable global para las cámaras
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: DatabaseConfig.supabaseUrl,
      anonKey: DatabaseConfig.supabaseAnonKey,
    );

    // Inicializar cámaras
    cameras = await availableCameras();
    print('Cámaras inicializadas: ${cameras.length}');
  } catch (e) {
    print('Error durante la inicialización: $e');
    // Continuar sin cámaras si hay error
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectWorld',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}