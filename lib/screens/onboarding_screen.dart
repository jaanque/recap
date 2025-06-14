import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  late AnimationController _contentController;
  late AnimationController _iconController;
  late AnimationController _textController;
  
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: '🌍',
      title: 'Conecta con el mundo',
      description: 'Descubre personas increíbles de todos los continentes y expande tu círculo social global.',
      color: Colors.blue,
    ),
    OnboardingData(
      icon: '💬',
      title: 'Conversaciones auténticas',
      description: 'Chatea en tiempo real con usuarios verificados y construye amistades genuinas.',
      color: Colors.green,
    ),
    OnboardingData(
      icon: '🎯',
      title: 'Encuentra tu tribu',
      description: 'Usa nuestros filtros inteligentes para conectar con personas que comparten tus intereses.',
      color: Colors.purple,
    ),
    OnboardingData(
      icon: '🚀',
      title: '¡Empezar es fácil!',
      description: 'Crea tu perfil en minutos y comienza a explorar un mundo lleno de posibilidades.',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _startProgressAnimation();
    _startContentAnimations();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _contentController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startProgressAnimation() {
    _progressController.reset();
    _progressController.forward();
  }

  void _startContentAnimations() {
    _contentController.forward();
    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textController.forward();
    });
  }

  void _resetContentAnimations() {
    _contentController.reset();
    _iconController.reset();
    _textController.reset();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      }
    } catch (e) {
      // En caso de error, navegar de todas formas
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Barras de progreso estilo Instagram Stories
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildProgressBars(),
            ),
            
            // Contenido principal
            Positioned.fill(
              top: 80,
              bottom: 120, // Aumentado de 100 a 120 para dar más espacio
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _startProgressAnimation();
                  _resetContentAnimations();
                  _startContentAnimations();
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Botones de navegación
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(_totalPages, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < _totalPages - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double progressWidth = 0;
                
                if (index < _currentPage) {
                  // Fully completed
                  progressWidth = constraints.maxWidth;
                } else if (index == _currentPage) {
                  // Currently in progress
                  progressWidth = constraints.maxWidth * _progressController.value;
                }
                // else: not started yet, progressWidth = 0
                
                return Stack(
                  children: [
                    if (progressWidth > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: progressWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal con animaciones mejoradas
              ScaleTransition(
                scale: Tween<double>(
                  begin: 0.5,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _iconController,
                  curve: Curves.elasticOut,
                )),
                child: RotationTransition(
                  turns: Tween<double>(
                    begin: -0.1,
                    end: 0.0,
                  ).animate(CurvedAnimation(
                    parent: _iconController,
                    curve: Curves.easeOutBack,
                  )),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withOpacity(0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        data.icon,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Título con animación de slide
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _textController,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: _textController,
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Descripción con animación retrasada
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _textController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _textController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botón anterior
        AnimatedScale(
          scale: _currentPage > 0 ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: _currentPage > 0 ? _previousPage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentPage > 0 ? Colors.white : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: _currentPage > 0 ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ] : [],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: _currentPage > 0 ? Colors.black : Colors.grey[500],
                size: 20,
              ),
            ),
          ),
        ),
        
        // Botón siguiente/empezar con animación mejorada
        AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: _currentPage == _totalPages - 1 ? 140 : 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: _currentPage == _totalPages - 1
                  ? const Center(
                      child: Text(
                        'Empezar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}