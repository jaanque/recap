import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;
  
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Controlador principal para la transformación
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animación de transformación con curva suave
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    ));
  }

  Future<void> _startSplashSequence() async {
    // Pequeña pausa inicial
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Iniciar la animación de transformación
    _morphController.forward();
    
    // Esperar que termine la animación y luego navegar
    await Future.delayed(const Duration(milliseconds: 2500));
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      
      Widget nextScreen;
      
      if (!hasCompletedOnboarding) {
        nextScreen = const OnboardingScreen();
      } else if (_authService.isAuthenticated) {
        nextScreen = const HomeScreen();
      } else {
        nextScreen = const LoginScreen();
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      // En caso de error, ir al onboarding por defecto
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedShape({
    required int index,
    required Animation<double> animation,
  }) {
    // Posiciones iniciales de los cuadrados (2x2 grid)
    final initialPositions = [
      const Offset(-40, -40), // Top-left
      const Offset(40, -40),  // Top-right
      const Offset(-40, 40),  // Bottom-left
      const Offset(40, 40),   // Bottom-right
    ];

    // Posiciones finales de las líneas verticales
    final finalPositions = [
      const Offset(-60, 0),   // Line 1
      const Offset(-20, 0),   // Line 2
      const Offset(20, 0),    // Line 3
      const Offset(60, 0),    // Line 4
    ];

    // Interpolación de posiciones
    final position = Offset.lerp(
      initialPositions[index],
      finalPositions[index],
      animation.value,
    )!;

    // Dimensiones - de cuadrado a línea vertical
    final width = Tween<double>(
      begin: 60.0,  // Ancho inicial del cuadrado
      end: 8.0,     // Ancho final de la línea
    ).evaluate(animation);

    final height = Tween<double>(
      begin: 60.0,  // Alto inicial del cuadrado
      end: 120.0,   // Alto final de la línea
    ).evaluate(animation);

    // Radio de esquinas - de redondeado a más redondeado
    final borderRadius = Tween<double>(
      begin: 12.0,  // Radio inicial
      end: 4.0,     // Radio final
    ).evaluate(animation);

    return Transform.translate(
      offset: position,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C), // Color gris oscuro como en las imágenes
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco limpio
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: AnimatedBuilder(
              animation: _morphAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Generar las 4 formas animadas
                    for (int i = 0; i < 4; i++)
                      _buildAnimatedShape(
                        index: i,
                        animation: _morphAnimation,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}