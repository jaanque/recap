import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class VideoService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String videoBucket = 'videos';
  static const String thumbnailBucket = 'thumbnails';

  // Modelo para los datos del video
  static Map<String, dynamic> createVideoData({
    required String title,
    required String fileName,
    required String filePath,
    required int fileSize,
    required double startTime,
    required double endTime,
    String? description,
    double? durationSeconds,
    String? thumbnailPath,
    String mimeType = 'video/mp4',
  }) {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    return {
      'user_id': user.id,
      'title': title,
      'description': description,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'duration_seconds': durationSeconds,
      'start_time': startTime,
      'end_time': endTime,
      'thumbnail_path': thumbnailPath,
      'mime_type': mimeType,
      'status': 'processing',
    };
  }

  // Subir video a Supabase Storage
  static Future<String> uploadVideo({
    required File videoFile,
    required String title,
    String? description,
    required double startTime,
    required double endTime,
    double? durationSeconds,
    File? thumbnailFile,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Generar nombre único para el archivo
      final uuid = const Uuid();
      final fileExtension = path.extension(videoFile.path);
      final fileName = '${uuid.v4()}$fileExtension';
      final filePath = '${user.id}/$fileName';

      // Leer el archivo como bytes
      final videoBytes = await videoFile.readAsBytes();
      final fileSize = videoBytes.length;

      // Subir video a Storage
      await _client.storage
          .from(videoBucket)
          .uploadBinary(filePath, videoBytes);

      // Subir thumbnail si existe
      String? thumbnailPath;
      if (thumbnailFile != null) {
        final thumbnailExtension = path.extension(thumbnailFile.path);
        final thumbnailFileName = '${uuid.v4()}$thumbnailExtension';
        thumbnailPath = '${user.id}/$thumbnailFileName';
        
        final thumbnailBytes = await thumbnailFile.readAsBytes();
        await _client.storage
            .from(thumbnailBucket)
            .uploadBinary(thumbnailPath, thumbnailBytes);
      }

      // Crear registro en la base de datos
      final videoData = createVideoData(
        title: title,
        fileName: fileName,
        filePath: filePath,
        fileSize: fileSize,
        startTime: startTime,
        endTime: endTime,
        description: description,
        durationSeconds: durationSeconds,
        thumbnailPath: thumbnailPath,
      );

      final response = await _client
          .from('videos')
          .insert(videoData)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error subiendo video: $e');
    }
  }

  // Obtener videos del usuario actual
  static Future<List<Map<String, dynamic>>> getUserVideos({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('videos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error obteniendo videos: $e');
    }
  }

  // Obtener un video específico
  static Future<Map<String, dynamic>?> getVideo(String videoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('videos')
          .select()
          .eq('id', videoId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error obteniendo video: $e');
    }
  }

  // Actualizar estado del video
  static Future<void> updateVideoStatus(String videoId, String status) async {
    try {
      await _client
          .from('videos')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', videoId);
    } catch (e) {
      throw Exception('Error actualizando estado: $e');
    }
  }

  // Obtener URL pública del video
  static String getVideoUrl(String filePath) {
    return _client.storage.from(videoBucket).getPublicUrl(filePath);
  }

  // Obtener URL pública del thumbnail
  static String? getThumbnailUrl(String? thumbnailPath) {
    if (thumbnailPath == null) return null;
    return _client.storage.from(thumbnailBucket).getPublicUrl(thumbnailPath);
  }

  // Eliminar video
  static Future<void> deleteVideo(String videoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener información del video
      final video = await getVideo(videoId);
      if (video == null) throw Exception('Video no encontrado');

      // Eliminar archivo de Storage
      await _client.storage
          .from(videoBucket)
          .remove([video['file_path']]);

      // Eliminar thumbnail si existe
      if (video['thumbnail_path'] != null) {
        await _client.storage
            .from(thumbnailBucket)
            .remove([video['thumbnail_path']]);
      }

      // Eliminar registro de la base de datos
      await _client
          .from('videos')
          .delete()
          .eq('id', videoId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error eliminando video: $e');
    }
  }

  // Actualizar información del video
  static Future<void> updateVideo({
    required String videoId,
    String? title,
    String? description,
    double? startTime,
    double? endTime,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (startTime != null) updates['start_time'] = startTime;
      if (endTime != null) updates['end_time'] = endTime;

      await _client
          .from('videos')
          .update(updates)
          .eq('id', videoId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Error actualizando video: $e');
    }
  }

  // Buscar videos por título
  static Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('videos')
          .select()
          .eq('user_id', user.id)
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error buscando videos: $e');
    }
  }

  // Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('videos')
          .select('file_size')
          .eq('user_id', user.id);

      final videos = List<Map<String, dynamic>>.from(response);
      final totalVideos = videos.length;
      final totalSize = videos.fold<int>(
        0, 
        (sum, video) => sum + (video['file_size'] as int? ?? 0)
      );

      return {
        'total_videos': totalVideos,
        'total_size_bytes': totalSize,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }
}