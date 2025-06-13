import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Registro
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Registro con datos adicionales
  Future<bool> signUpWithProfile({
    required String email,
    required String password,
    required String username,
    required String continent,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Guardar datos adicionales en la tabla profiles
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'continent': continent,
        });
        return true;
      }
      return false;
    } catch (error) {
      throw error;
    }
  }

  // Registro con datos adicionales
  Future<bool> signUpWithProfile2({
    required String email,
    required String password,
    required String username,
    required String continent,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Guardar datos adicionales en la tabla profiles
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'continent': continent,
        });
        return true;
      }
      return false;
    } catch (error) {
      throw error;
    }
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Resetear contraseña
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Verificar si está autenticado
  bool get isAuthenticated => currentUser != null;
}