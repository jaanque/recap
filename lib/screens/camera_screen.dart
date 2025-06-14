import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

// Importar las cámaras del main.dart
import '../main.dart' show cameras;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Verificar si tenemos cámaras disponibles
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No se encontraron cámaras disponibles en el dispositivo.';
        });
        return;
      }

      // Inicializar el controlador con la primera cámara
      _controller = CameraController(
        cameras[0], // Usar la primera cámara (generalmente la trasera)
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error inicializando cámara: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error inicializando cámara: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _switchCamera() async {
    if (cameras.length <= 1) return;
    
    try {
      final currentIndex = cameras.indexOf(_controller!.description);
      final nextIndex = (currentIndex + 1) % cameras.length;
      
      await _controller!.dispose();
      
      _controller = CameraController(
        cameras[nextIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error cambiando cámara: $e');
    }
  }

  void _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
        }
      });
    } catch (e) {
      print('Error iniciando grabación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error iniciando grabación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      final video = await _controller!.stopVideoRecording();
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      
      print('Video guardado en: ${video.path}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video guardado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deteniendo grabación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de cerrar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido de error centrado
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.red,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Error de Cámara',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                        });
                        _initializeCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de cerrar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido de carga centrado
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Inicializando cámara...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista de la cámara
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Overlay superior con texto "BeReal." y tiempo de grabación
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'BeReal.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(_recordingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Controles inferiores
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón flash (lado izquierdo)
                GestureDetector(
                  onTap: () {
                    // Aquí puedes implementar toggle de flash
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Flash no implementado'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flash_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Botón principal de grabación (centro)
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isRecording
                        ? const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 40,
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                
                // Botón cambiar cámara (lado derecho)
                GestureDetector(
                  onTap: cameras.length > 1 ? _switchCamera : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(cameras.length > 1 ? 0.3 : 0.1),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.flip_camera_ios,
                      color: cameras.length > 1 ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Botón de cerrar/volver
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                if (_isRecording) {
                  _stopRecording();
                }
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}