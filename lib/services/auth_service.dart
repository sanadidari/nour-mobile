import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream pour écouter les changements d'auth (session, logout, etc)
  Stream<AuthState> get authState {
    return _supabase.auth.onAuthStateChange;
  }

  // Connexion
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Inscription
  Future<void> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    await _supabase.auth.signUp(email: email, password: password, data: data);
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Récupérer la session actuelle
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Récupérer l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;
}
