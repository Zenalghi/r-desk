// File: lib/app/core/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../elements/auth/repository/auth_repository.dart';
import '../../data/providers/api_client.dart'; // Import class ApiClient
import '../../elements/auth/auth_service.dart';

final baseUrlProvider = StateProvider<String>((ref) {
  return 'http://192.168.100.111/api';
});

// Provider untuk instance ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  // 1. Baca baseUrl dari provider baru
  final baseUrl = ref.watch(baseUrlProvider);

  // 2. Kirim baseUrl ke constructor ApiClient
  return ApiClient(baseUrl);
});

// Provider untuk AuthRepository (tidak berubah)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // 1. Ambil instance ApiClient dari provider-nya
  final apiClient = ref.watch(apiClientProvider);

  // 2. Kirimkan instance tersebut ke constructor AuthRepository
  return AuthRepository(apiClient);
});

// StateProvider untuk role pengguna (tidak berubah)
final userRoleProvider = StateProvider<String?>((ref) => null);

// StateProvider untuk menyimpan nama pengguna secara aktif
final userNameProvider = StateProvider<String?>((ref) => null);
// FutureProvider untuk pengecekan awal (sekarang juga memuat nama)
final initialAuthProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  // Set semua state awal, termasuk token
  ref.read(authTokenProvider.notifier).state = token;

  if (token != null) {
    final role = prefs.getString('user_role');
    final name = prefs.getString('user_name');
    final userId = prefs.getInt('user_id');
    ref.read(userRoleProvider.notifier).state = role;
    ref.read(userNameProvider.notifier).state = name;
    ref.read(currentUserIdProvider.notifier).state = userId;
  }

  return token;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});
final currentUserIdProvider = StateProvider<int?>((ref) => null);
final authTokenProvider = StateProvider<String?>((ref) => null);
final darkModeProvider = StateProvider<bool>((ref) => false);
