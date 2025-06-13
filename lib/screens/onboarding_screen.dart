import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _startProgressAnimation();
    _contentController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startProgressAnimation() {
    _progressController.reset();
    _progressController.forward();
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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // En caso de error, navegar de todas formas
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
              bottom: 100,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _startProgressAnimation();
                  _contentController.reset();
                  _contentController.forward();
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
            child: Row(
              children: [
                // Barra completada
                if (index < _currentPage)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // Barra en progreso
                if (index == _currentPage)
                  AnimatedBuilder(
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
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Curves.easeOutBack,
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
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
              
              const SizedBox(height: 60),
              
              // Título
              Text(
                data.title,
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
              Container(
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
              
              const SizedBox(height: 40),
              
              // Indicador visual adicional
              Container(
                height: 80,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(2),
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
        GestureDetector(
          onTap: _currentPage > 0 ? _previousPage : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _currentPage > 0 ? Colors.white : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: _currentPage > 0 ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
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
        
        // Indicador de página
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${_currentPage + 1} / $_totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        
        // Botón siguiente/empezar
        GestureDetector(
          onTap: _nextPage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _currentPage == _totalPages - 1 ? 120 : 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(
                _currentPage == _totalPages - 1 ? 28 : 28,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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