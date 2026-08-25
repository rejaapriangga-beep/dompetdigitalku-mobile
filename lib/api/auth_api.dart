// lib/api/auth_api.dart
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

// Web Client ID yang sama dengan GOOGLE_CLIENT_ID di backend — dipakai
// sebagai serverClientId supaya idToken yang dihasilkan Google Sign-In SDK
// audience-nya cocok saat diverifikasi server (lihat
// app/api/mobile/auth/google/route.ts di backend).
const _googleServerClientId =
    '681675792324-2dda7a7fnjqqb184nrlk50rgrqrh7tud.apps.googleusercontent.com';

class AuthApi {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _googleServerClientId,
  );

  static Future<void> login(String email, String password) async {
    try {
      final res = await ApiClient.instance.dio.post(
        '/mobile/auth/login',
        data: {'email': email, 'password': password, 'deviceInfo': 'Android'},
      );
      await TokenStorage.instance.save(
        accessToken: res.data['accessToken'] as String,
        refreshToken: res.data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['error'] ??
            'Gagal masuk. Periksa koneksi internet Anda.',
      );
    }
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String householdName,
  }) async {
    try {
      // Endpoint ini dipakai bersama dengan halaman /register di web
      // (app/api/register/route.ts) — tidak mengembalikan token, jadi
      // setelah berhasil user diarahkan ke layar Login untuk masuk seperti
      // biasa (sama seperti alur di web).
      await ApiClient.instance.dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'householdName': householdName,
        },
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['error'] ??
            'Gagal mendaftar. Periksa koneksi internet Anda.',
      );
    }
  }

  static Future<void> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User membatalkan pemilihan akun Google — bukan error.
        throw ApiException('Login Google dibatalkan.');
      }
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw ApiException('Gagal mendapatkan token dari Google.');
      }
      final res = await ApiClient.instance.dio.post(
        '/mobile/auth/google',
        data: {'idToken': idToken, 'deviceInfo': 'Android'},
      );
      await TokenStorage.instance.save(
        accessToken: res.data['accessToken'] as String,
        refreshToken: res.data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['error'] ??
            'Gagal masuk dengan Google. Periksa koneksi internet Anda.',
      );
    }
  }

  static Future<void> logout() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    try {
      if (refreshToken != null) {
        await ApiClient.instance.dio.post(
          '/mobile/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // tidak apa kalau gagal — tetap hapus token lokal di bawah ini
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await TokenStorage.instance.clear();
  }

  static Future<bool> isLoggedIn() async {
    final token = await TokenStorage.instance.getRefreshToken();
    return token != null;
  }
}
