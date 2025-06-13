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
      icon: Icons.public_outlined,
    ),
    OnboardingData(
      title: 'Conecta Globalmente',
      description: 'Conoce personas de diferentes continentes y culturas',
      icon: Icons.language_outlined,
    ),
    OnboardingData(
      title: 'Comparte Experiencias',
      description: 'Intercambia historias y aprende de experiencias únicas',
      icon: Icons.share_outlined,
    ),
    OnboardingData(
      title: 'Comunidad Segura',
      description: 'Disfruta de un entorno seguro y respetuoso para todos',
      icon: Icons.security_outlined,
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
      duration: const Duration(seconds: 8),
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
    
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
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
      backgroundColor: Colors.grey[50],
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
        child: SafeArea(
          child: Column(
            children: [
              // Header con progreso y botón skip
              _buildHeader(),
              
              // Contenido principal
              Expanded(
                child: _buildSlideContent(currentSlide),
              ),
              
              // Footer con navegación
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Botón skip alineado a la derecha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          
          const SizedBox(height: 20),
          
          // Barras de progreso
          _buildProgressBars(),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(_slides.length, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < _slides.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  )
                : index < _currentIndex
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    : const SizedBox(),
          ),
        );
      }),
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal con container estilizado
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  slide.icon,
                  size: 50,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Título
              Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Descripción
              Text(
                slide.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
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
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón anterior
          if (_currentIndex > 0)
            _buildNavigationButton(
              icon: Icons.arrow_back_ios,
              label: 'Anterior',
              onTap: _previousSlide,
            )
          else
            const SizedBox(width: 80),
          
          // Indicadores de página
          _buildPageIndicators(),
          
          // Botón siguiente
          if (_currentIndex < _slides.length - 1)
            _buildNavigationButton(
              icon: Icons.arrow_forward_ios,
              label: 'Siguiente',
              onTap: _nextSlide,
              isForward: true,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isForward = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isForward
              ? [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    icon,
                    size: 12,
                    color: Colors.grey[700],
                  ),
                ]
              : [
                  Icon(
                    icon,
                    size: 12,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_slides.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: index == _currentIndex ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == _currentIndex ? Colors.black : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}