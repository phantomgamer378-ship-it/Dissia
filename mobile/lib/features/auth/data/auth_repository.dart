import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider = StreamNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final Session? session;
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.session,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    Session? session,
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AuthState(
        session: session ?? this.session,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends StreamNotifier<AuthState> {
  late final AuthRepository _repo;
  final _storage = const FlutterSecureStorage();

  @override
  Stream<AuthState> build() {
    _repo = ref.watch(authRepositoryProvider);

    return Supabase.instance.client.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session != null) {
        await _storage.write(key: 'access_token', value: session.accessToken);
        final profile = await _repo.fetchCurrentProfile(session.accessToken);
        return AuthState(session: session, user: profile);
      } else {
        // Check for local demo token
        final demoToken = await _storage.read(key: 'access_token');
        if (demoToken != null && demoToken.isNotEmpty) {
          final profile = await _repo.fetchCurrentProfile(demoToken);
          return AuthState(user: profile);
        }
        return const AuthState();
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AsyncData(state.valueOrNull?.copyWith(isLoading: true) ?? const AuthState(isLoading: true));
    try {
      final res = await _repo.signIn(email: email, password: password);
      if (res.session != null) {
        await _storage.write(key: 'access_token', value: res.session!.accessToken);
        final user = await _repo.fetchCurrentProfile(res.session!.accessToken);
        state = AsyncData(AuthState(session: res.session, user: user));
      }
    } catch (e) {
      state = AsyncData(AuthState(errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> signInWithDemoToken(String token, String role) async {
    state = const AsyncData(AuthState(isLoading: true));
    try {
      await _storage.write(key: 'access_token', value: token);
      final user = UserModel(
        id: 'demo-$role-id',
        email: '$role@sanket.ai',
        displayName: 'Demo ${role.toUpperCase()}',
        role: UserRole.fromString(role),
        createdAt: DateTime.now(),
      );
      state = AsyncData(AuthState(user: user));
    } catch (e) {
      state = AsyncData(AuthState(errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, {String? fullName}) async {
    state = const AsyncData(AuthState(isLoading: true));
    try {
      await _repo.signUp(email: email, password: password, fullName: fullName);
      state = const AsyncData(AuthState());
    } catch (e) {
      state = AsyncData(AuthState(errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'access_token');
    await _repo.signOut();
    state = const AsyncData(AuthState());
  }
}

class AuthRepository {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Session? get currentSession => Supabase.instance.client.auth.currentSession;
  User? get currentSupabaseUser => Supabase.instance.client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await _storage.delete(key: 'access_token');
  }

  Future<UserModel?> fetchCurrentProfile(String token) async {
    try {
      final res = await _apiClient.get(
        '/api/v1/auth/me',
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return UserModel(
          id: data['id'] as String? ?? 'user-id',
          email: data['email'] as String? ?? 'user@sanket.ai',
          role: UserRole.fromString(data['role'] as String? ?? 'public'),
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Fallback if auth/me is not reached
    }
    return null;
  }
}
