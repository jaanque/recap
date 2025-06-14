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
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Controlador para el logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para el fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador para la escala
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Controlador para el pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación del logo (escala y rotación sutil)
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Animación de fade para el texto
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Animación de escala para todo el contenedor
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Animación de pulso para el efecto de carga
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startSplashSequence() async {
    // Iniciar animaciones de forma escalonada
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
    
    // Iniciar pulso continuo
    _pulseController.repeat(reverse: true);
    
    // Esperar que terminen las animaciones principales y luego navegar
    await Future.delayed(const Duration(milliseconds: 2200));
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
    _logoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistente con otras pantallas
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _fadeController,
                _scaleController,
                _pulseController,
              ]),
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo principal con contenedor elevado (consistente con otras pantallas)
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.5,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _logoController,
                          curve: Curves.elasticOut,
                        )),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white, // Fondo blanco consistente
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                      spreadRadius: -5,
                                    ),
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.15),
                                      blurRadius: 50,
                                      offset: const Offset(0, 20),
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '🌍',
                                    style: TextStyle(fontSize: 60),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Título de la app con fade y estilo consistente
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: Column(
                            children: [
                              const Text(
                                'ConnectWorld',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Color consistente
                                  letterSpacing: 1,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Conectando personas alrededor del mundo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600], // Color consistente
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // Indicador de carga moderno y consistente
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[600]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Preparando tu experiencia...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}