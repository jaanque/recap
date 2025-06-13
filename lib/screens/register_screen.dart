import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  late AnimationController _animationController;
  
  int _currentPage = 0;
  String? _selectedContinent;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<Map<String, String>> _continents = [
    {'name': 'África', 'flag': '🌍'},
    {'name': 'Antártida', 'flag': '🐧'},
    {'name': 'Asia', 'flag': '🌏'},
    {'name': 'Europa', 'flag': '🇪🇺'},
    {'name': 'América del Norte', 'flag': '🌎'},
    {'name': 'Oceanía', 'flag': '🇦🇺'},
    {'name': 'América del Sur', 'flag': '🌎'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _hasValidLength(String password) {
    return password.length >= 6;
  }

  bool _hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  bool _hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  bool _isStrongPassword(String password) {
    return _hasValidLength(password) && _hasUppercase(password) && _hasNumber(password);
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _authService.signUpWithProfile(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        continent: _selectedContinent!,
      );

      if (success) {
        // Mostrar mensaje de éxito con animación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Registro exitoso. Verifica tu email.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Esperar un poco antes de navegar
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: ${error.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Barra de progreso
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildProgressBar(),
            ),
            
            // Botón de navegación
            Positioned(
              top: 60,
              left: 20,
              child: _buildNavigationButton(),
            ),
            
            // Contenido principal
            Positioned.fill(
              top: 100,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _animationController.reset();
                      _animationController.forward();
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildContinentPage(),
                      _buildEmailPage(),
                      _buildUsernamePage(),
                      _buildPasswordPage(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentPage + 1) / 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton() {
    return GestureDetector(
      onTap: _currentPage > 0 ? _previousPage : () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _currentPage > 0 ? Icons.arrow_back : Icons.close,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(String title) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutBack,
        )),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildContinentPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedTitle('¿De qué continente\neres?'),
        const SizedBox(height: 60),
        
        // Selector de continente mejorado
        _buildInputContainer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedContinent,
                hint: const Text(
                  'Selecciona tu continente',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                items: _continents.map((continent) {
                  return DropdownMenuItem<String>(
                    value: continent['name'],
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            continent['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            continent['name']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedContinent = value);
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 60),
        _buildContinueButton(
          isEnabled: _selectedContinent != null,
          onPressed: _nextPage,
        ),
      ],
    );
  }

  Widget _buildEmailPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedTitle('Ingresa tu correo\nelectrónico'),
        const SizedBox(height: 60),
        
        _buildInputContainer(
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'correo@ejemplo.com',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
        
        if (_emailController.text.isNotEmpty && !_isValidEmail(_emailController.text.trim()))
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  'Por favor ingresa un email válido',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 60),
        _buildContinueButton(
          isEnabled: _emailController.text.isNotEmpty && _isValidEmail(_emailController.text.trim()),
          onPressed: _nextPage,
        ),
      ],
    );
  }

  Widget _buildUsernamePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedTitle('Elige tu nombre\nde usuario'),
        const SizedBox(height: 60),
        
        _buildInputContainer(
          child: TextField(
            controller: _usernameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'nombre_usuario',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
        
        if (_usernameController.text.isNotEmpty && _usernameController.text.length < 3)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'El nombre de usuario debe tener al menos 3 caracteres',
                  style: TextStyle(color: Colors.orange[600], fontSize: 12),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 60),
        _buildContinueButton(
          isEnabled: _usernameController.text.length >= 3,
          onPressed: _nextPage,
        ),
      ],
    );
  }

  Widget _buildPasswordPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedTitle('Crea tu\ncontraseña'),
        const SizedBox(height: 60),
        
        _buildInputContainer(
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildInputContainer(
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Confirmar contraseña',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        
        // Indicadores de validación de contraseña
        if (_passwordController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordRequirement(
                  'Al menos 6 caracteres',
                  _hasValidLength(_passwordController.text),
                ),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                  'Al menos una mayúscula',
                  _hasUppercase(_passwordController.text),
                ),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                  'Al menos un número',
                  _hasNumber(_passwordController.text),
                ),
                if (_confirmPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordRequirement(
                    'Las contraseñas coinciden',
                    _passwordController.text == _confirmPasswordController.text,
                  ),
                ],
              ],
            ),
          ),
        
        const SizedBox(height: 60),
        _buildContinueButton(
          isEnabled: _isStrongPassword(_passwordController.text) &&
              _passwordController.text == _confirmPasswordController.text &&
              !_isLoading,
          onPressed: _register,
          text: 'Crear cuenta',
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isValid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green : Colors.grey[600],
            fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton({
    required bool isEnabled,
    required VoidCallback onPressed,
    String text = 'Continuar',
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}