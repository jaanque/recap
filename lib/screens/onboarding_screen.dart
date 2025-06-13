import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late Timer _timer;
  late AnimationController _progressController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: '¡Bienvenido!',
      description: 'Descubre una nueva forma de conectar con personas de todo el mundo',
      icon: Icons.public,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    OnboardingData(
      title: 'Conecta Globalmente',
      description: 'Conoce personas de diferentes continentes y culturas',
      icon: Icons.language,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    OnboardingData(
      title: 'Comparte Experiencias',
      description: 'Intercambia historias y aprende de experiencias únicas',
      icon: Icons.share,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    OnboardingData(
      title: 'Comunidad Segura',
      description: 'Disfruta de un entorno seguro y respetuoso para todos',
      icon: Icons.security,
      gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _startTimer() {
    _progressController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentIndex < _slides.length - 1) {
        _nextSlide();
      } else {
        _navigateToLogin();
      }
    });
  }

  void _nextSlide() {
    setState(() {
      _currentIndex++;
    });
    _progressController.reset();
    _progressController.forward();
    _slideController.reset();
    _slideController.forward();
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _navigateToLogin() async {
    _timer.cancel();
    
    // Marcar que el onboarding ya se completó
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _skipOnboarding() async {
    _timer.cancel();
    
    // Marcar que el onboarding ya se completó
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentIndex];
    
    return Scaffold(
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth * 0.3) {
            // Tap en la izquierda - slide anterior
            _previousSlide();
          } else if (tapPosition > screenWidth * 0.7) {
            // Tap en la derecha - siguiente slide
            if (_currentIndex < _slides.length - 1) {
              _nextSlide();
            } else {
              _navigateToLogin();
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentSlide.gradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Barras de progreso
                _buildProgressBars(),
                
                // Botón skip
                _buildSkipButton(),
                
                // Contenido principal
                Expanded(
                  child: _buildSlideContent(currentSlide),
                ),
                
                // Indicador de navegación
                _buildNavigationHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_slides.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: index < _slides.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: index == _currentIndex
                  ? AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    )
                  : index < _currentIndex
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      : const SizedBox(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _skipOnboarding,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Saltar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(OnboardingData slide) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  slide.icon,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Título
              Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Descripción
              Text(
                slide.description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 80),
              
              // Botón de acción (solo en la última slide)
              if (_currentIndex == _slides.length - 1)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicador izquierdo
          if (_currentIndex > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Anterior',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(),
          
          // Contador de slides
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1} / ${_slides.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Indicador derecho
          if (_currentIndex < _slides.length - 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Siguiente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}