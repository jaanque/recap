import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'movie_screen.dart';
import 'camera_screen.dart';
import 'video_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  
  List<Map<String, dynamic>> _userVideos = [];
  bool _isLoadingVideos = false;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _startAnimations();
    _loadUserVideos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _fadeController.forward();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  Future<void> _loadUserVideos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user != null) {
        final response = await Supabase.instance.client
            .from('videos')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        if (mounted) {
          setState(() {
            _userVideos = List<Map<String, dynamic>>.from(response);
            _isLoadingVideos = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando videos: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideos = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final authService = AuthService();
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Perfil'),
          content: const Text('Función de perfil próximamente disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuración'),
          content: const Text('Configuraciones próximamente disponibles.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleSignOut();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user == null) {
      return {
        'user': null,
        'displayName': 'Usuario',
        'email': '',
      };
    }

    try {
      // Obtener datos del perfil desde Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, email')
          .eq('id', user.id)
          .single();
      
      final username = response['username'] as String?;
      
      return {
        'user': user,
        'displayName': username?.isNotEmpty == true ? username! : user.email?.split('@')[0] ?? 'Usuario',
        'email': user.email ?? '',
      };
    } catch (error) {
      print('Error obteniendo datos del usuario: $error');
      // Fallback si no se pueden obtener los datos del perfil
      return {
        'user': user,
        'displayName': user.email?.split('@')[0] ?? 'Usuario',
        'email': user.email ?? '',
      };
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Fecha desconocida';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        // Hoy
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return 'Hoy a las $hour:$minute';
      } else if (difference.inDays == 1) {
        // Ayer
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return 'Ayer a las $hour:$minute';
      } else if (difference.inDays < 7) {
        // Esta semana
        final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        final weekday = weekdays[dateTime.weekday - 1];
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$weekday a las $hour:$minute';
      } else {
        // Fecha completa
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        final year = dateTime.year;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$day/$month/$year a las $hour:$minute';
      }
    } catch (e) {
      print('Error formateando fecha: $e');
      return 'Fecha inválida';
    }
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.videocam,
            color: Colors.blue,
            size: 30,
          ),
        ),
        title: Text(
          video['title'] ?? 'Video sin título',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDateTime(video['created_at']),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (video['duration'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Duración: ${video['duration']}s',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onSelected: (String value) {
            switch (value) {
              case 'view':
                _viewVideo(video);
                break;
              case 'delete':
                _showDeleteConfirmation(video);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 12),
                  Text('Ver'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewVideo(video),
      ),
    );
  }

  void _viewVideo(Map<String, dynamic> video) {
    // Aquí puedes implementar la visualización del video
    // Por ejemplo, abrir un reproductor de video o mostrar detalles
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video['title'] ?? 'Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${_formatDateTime(video['created_at'])}'),
            if (video['duration'] != null)
              Text('Duración: ${video['duration']}s'),
            if (video['file_path'] != null)
              Text('Archivo: ${video['file_path']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (video['file_path'] != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Abrir el editor de video
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VideoEditorScreen(
                      videoPath: video['file_path'],
                    ),
                  ),
                );
              },
              child: const Text('Editar'),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar video'),
        content: Text('¿Estás seguro de que quieres eliminar "${video['title'] ?? 'este video'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVideo(video);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    try {
      await Supabase.instance.client
          .from('videos')
          .delete()
          .eq('id', video['id']);
      
      // Recargar la lista de videos
      _loadUserVideos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error eliminando video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVideosList() {
    if (_isLoadingVideos) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      );
    }

    if (_userVideos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes videos aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón de cámara para grabar tu primer video',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Videos (${_userVideos.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: _loadUserVideos,
                icon: const Icon(Icons.refresh),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userVideos.length,
            itemBuilder: (context, index) {
              return _buildVideoItem(_userVideos[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeTransition(
          opacity: _fadeController,
          child: const Text(
            'Inicio',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                offset: const Offset(0, 50),
                onSelected: (String value) {
                  switch (value) {
                    case 'profile':
                      _showProfileDialog();
                      break;
                    case 'settings':
                      _showSettingsDialog();
                      break;
                    case 'logout':
                      _showSignOutConfirmation();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Configuración'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón de cámara
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
            )),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                  // Si se grabó un video, recargar la lista
                  if (result == true) {
                    _loadUserVideos();
                  }
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                heroTag: "camera_fab",
                child: const Icon(
                  Icons.camera_alt,
                  size: 28,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón de películas
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            )),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MovieScreen()),
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                heroTag: "movie_fab",
                child: const Icon(
                  Icons.movie,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar los datos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final userData = snapshot.data ?? {};
            final displayName = userData['displayName'] ?? 'Usuario';
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Sección de bienvenida
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono de bienvenida con animación
                        ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.5,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: _scaleController,
                            curve: Curves.elasticOut,
                          )),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '👋',
                                style: TextStyle(fontSize: 50),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Título de bienvenida
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: FadeTransition(
                            opacity: _slideController,
                            child: const Text(
                              '¡Bienvenido de vuelta!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Nombre de usuario
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                          )),
                          child: FadeTransition(
                            opacity: Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                            )),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Hola, $displayName',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Lista de videos
                  _buildVideosList(),
                  
                  const SizedBox(height: 100), // Espacio para los FABs
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}