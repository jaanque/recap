import 'package:flutter/material.dart';
import 'package:recap/services/video_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
// Importar el servicio de video que creamos
// import 'services/video_service.dart'; // Ajusta la ruta según tu estructura

class VideoEditorScreen extends StatefulWidget {
  final String videoPath;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isUploading = false;
  
  // Variables para el selector de tiempo
  double _startTime = 0.0;
  double _endTime = 5.0; // Máximo 5 segundos por defecto
  double _currentPosition = 0.0;
  Duration _videoDuration = Duration.zero;
  Timer? _positionTimer;
  
  // Controladores para el formulario
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Constantes
  static const double maxSelectionDuration = 5.0; // 5 segundos máximo
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _videoDuration = _controller!.value.duration;
          
          // Ajustar el tiempo final si el video es menor a 5 segundos
          if (_videoDuration.inSeconds < maxSelectionDuration) {
            _endTime = _videoDuration.inSeconds.toDouble();
          }
          
          _hasError = false;
        });
        
        // Iniciar el timer para actualizar la posición
        _startPositionTimer();
        
        // Escuchar cambios en el controller
        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      print('Error inicializando video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error cargando el video: ${e.toString()}';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {
        _currentPosition = _controller!.value.position.inSeconds.toDouble();
        _isPlaying = _controller!.value.isPlaying;
      });
      
      // Si el video llega al final de la selección, pausar
      if (_currentPosition >= _endTime && _isPlaying) {
        _pauseVideo();
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _controller != null) {
        final position = _controller!.value.position.inSeconds.toDouble();
        if (position != _currentPosition) {
          setState(() {
            _currentPosition = position;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _playVideo() async {
    if (_controller == null) return;
    
    // Ir al inicio de la selección
    await _controller!.seekTo(Duration(seconds: _startTime.toInt()));
    await _controller!.play();
  }

  void _pauseVideo() async {
    if (_controller == null) return;
    await _controller!.pause();
  }

  void _seekToStart() async {
    if (_controller == null) return;
    await _controller!.seekTo(Duration(seconds: _startTime.toInt()));
  }

  void _onStartTimeChanged(double value) {
    setState(() {
      _startTime = value;
      
      // Asegurar que la duración de selección no exceda 5 segundos
      if (_endTime - _startTime > maxSelectionDuration) {
        _endTime = _startTime + maxSelectionDuration;
      }
      
      // Asegurar que no se pase del final del video
      if (_endTime > _videoDuration.inSeconds) {
        _endTime = _videoDuration.inSeconds.toDouble();
        _startTime = _endTime - maxSelectionDuration;
        if (_startTime < 0) _startTime = 0;
      }
    });
  }

  void _onEndTimeChanged(double value) {
    setState(() {
      _endTime = value;
      
      // Asegurar que la duración de selección no exceda 5 segundos
      if (_endTime - _startTime > maxSelectionDuration) {
        _startTime = _endTime - maxSelectionDuration;
      }
      
      // Asegurar que no sea menor que el inicio
      if (_startTime < 0) {
        _startTime = 0;
        _endTime = maxSelectionDuration;
      }
    });
  }

  String _formatTime(double seconds) {
    final minutes = (seconds ~/ 60);
    final remainingSeconds = (seconds % 60).toInt();
    final milliseconds = ((seconds % 1) * 100).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  double get _selectionDuration => _endTime - _startTime;

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 300,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildVideoInfoForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo título
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Título *',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Ingresa un título para tu video',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Campo descripción
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Describe tu video...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSelector() {
    if (!_isInitialized) {
      return Container();
    }

    final totalDuration = _videoDuration.inSeconds.toDouble();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona hasta ${maxSelectionDuration.toInt()} segundos del video',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Timeline visual
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Barra completa del video
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                // Área seleccionada
                Positioned(
                  left: (_startTime / totalDuration) * MediaQuery.of(context).size.width * 0.8,
                  width: ((_endTime - _startTime) / totalDuration) * MediaQuery.of(context).size.width * 0.8,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                // Indicador de posición actual
                if (_currentPosition >= _startTime && _currentPosition <= _endTime)
                  Positioned(
                    left: (_currentPosition / totalDuration) * MediaQuery.of(context).size.width * 0.8 - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Controles de tiempo de inicio
          Row(
            children: [
              const Text(
                'Inicio: ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(
                child: Slider(
                  value: _startTime,
                  min: 0.0,
                  max: totalDuration - 0.1,
                  divisions: (totalDuration * 10).toInt(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[600],
                  onChanged: _onStartTimeChanged,
                ),
              ),
              Text(
                _formatTime(_startTime),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          
          // Controles de tiempo final
          Row(
            children: [
              const Text(
                'Final: ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(
                child: Slider(
                  value: _endTime,
                  min: _startTime + 0.1,
                  max: totalDuration,
                  divisions: (totalDuration * 10).toInt(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[600],
                  onChanged: _onEndTimeChanged,
                ),
              ),
              Text(
                _formatTime(_endTime),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información de duración seleccionada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectionDuration <= maxSelectionDuration 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectionDuration <= maxSelectionDuration 
                    ? Colors.green 
                    : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duración seleccionada: ${_formatTime(_selectionDuration)}',
                  style: TextStyle(
                    color: _selectionDuration <= maxSelectionDuration 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectionDuration <= maxSelectionDuration)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                else
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 20,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón ir al inicio
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: _seekToStart,
            label: 'Inicio',
          ),
          
          // Botón play/pause
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: _isPlaying ? _pauseVideo : _playVideo,
            label: _isPlaying ? 'Pausar' : 'Reproducir',
            isPrimary: true,
          ),
          
          // Botón vista previa de selección
          _buildControlButton(
            icon: Icons.preview,
            onTap: () async {
              await _controller!.seekTo(Duration(seconds: _startTime.toInt()));
              await _controller!.play();
            },
            label: 'Vista previa',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 60 : 50,
            height: isPrimary ? 60 : 50,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.blue : Colors.grey[800],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 30 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Botón cancelar
          Expanded(
            child: ElevatedButton(
              onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botón confirmar/subir
          Expanded(
            child: ElevatedButton(
              onPressed: _isUploading || 
                         _selectionDuration > maxSelectionDuration ||
                         _titleController.text.trim().isEmpty
                  ? null
                  : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Subiendo...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : const Text(
                      'Subir Video',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadVideo() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, ingresa un título para el video');
      return;
    }

    if (_selectionDuration > maxSelectionDuration) {
      _showErrorDialog('La selección no puede exceder ${maxSelectionDuration.toInt()} segundos');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Pausar el video antes de subir
      _pauseVideo();

      final videoFile = File(widget.videoPath);
      
      // Aquí puedes agregar lógica para generar un thumbnail si lo deseas
      // File? thumbnailFile = await _generateThumbnail();

      final videoId = await VideoService.uploadVideo(
        videoFile: videoFile,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        durationSeconds: _videoDuration.inSeconds.toDouble(),
        // thumbnailFile: thumbnailFile,
      );

      // Marcar como listo una vez subido
      await VideoService.updateVideoStatus(videoId, 'ready');

      if (mounted) {
        _showSuccessDialog(videoId);
      }
    } catch (e) {
      print('Error subiendo video: $e');
      if (mounted) {
        _showErrorDialog('Error subiendo el video: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String videoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '¡Video Subido Exitosamente!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu video "${_titleController.text}" ha sido subido correctamente.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Título: ${_titleController.text}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (_descriptionController.text.trim().isNotEmpty)
              Text(
                'Descripción: ${_descriptionController.text}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            Text(
              'Duración: ${_formatTime(_selectionDuration)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'ID: $videoId',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a la pantalla anterior
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  bool get _canUpload {
    return _titleController.text.trim().isNotEmpty &&
           _selectionDuration <= maxSelectionDuration &&
           !_isUploading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Editor de Video',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Formulario de información del video
                        _buildVideoInfoForm(),
                        
                        const SizedBox(height: 20),
                        
                        // Reproductor de video
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildVideoPlayer(),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Controles de reproducción
                        _buildControls(),
                        
                        const SizedBox(height: 20),
                        
                        // Selector de tiempo
                        _buildTimelineSelector(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Botones de acción
                _buildBottomActions(),
              ],
            ),
    );
  }
}