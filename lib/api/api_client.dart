// lib/api/api_client.dart
// Satu klien Dio untuk semua panggilan API, otomatis menyisipkan access
// token, dan otomatis minta access token baru (pakai refresh token) kalau
// dapat 401 — jadi user tidak perlu login ulang tiap 15 menit.
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

const String kApiBaseUrl = 'https://dompetdigitalku.my.id/api';

class AuthExpiredException implements Exception {}

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthCall = error.requestOptions.path.contains(
            '/mobile/auth/',
          );
          if (error.response?.statusCode == 401 &&
              !isAuthCall &&
              error.requestOptions.extra['retried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final token = await TokenStorage.instance.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  // Kalau app baru dibuka lagi setelah idle lama, access token (umurnya cuma
  // 15 menit) biasanya sudah kedaluwarsa — dan karena beberapa layar memuat
  // data lewat beberapa panggilan API sekaligus (Future.wait), semuanya bisa
  // dapat 401 hampir bersamaan lalu masing-masing coba refresh sendiri-sendiri.
  // Refresh token sifatnya rotating (sekali pakai): begitu refresh PERTAMA
  // berhasil, refresh token lama langsung tidak berlaku lagi di server — jadi
  // refresh KEDUA dst. yang masih pakai token lama itu akan gagal, dan
  // (sebelumnya) langsung menghapus sesi yang baru saja berhasil diperbarui
  // oleh refresh pertama. Fix-nya: gabungkan semua percobaan refresh yang
  // tumpang tindih jadi SATU permintaan saja — yang lain tinggal ikut nunggu
  // hasil yang sama, tidak masing-masing jalan sendiri.
  Future<bool>? _refreshFuture;

  Future<bool> _tryRefresh() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await Dio(
        BaseOptions(baseUrl: kApiBaseUrl),
      ).post('/mobile/auth/refresh', data: {'refreshToken': refreshToken});
      final newAccess = res.data['accessToken'] as String;
      final newRefresh = res.data['refreshToken'] as String;
      await TokenStorage.instance.save(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      return false;
    }
  }
}
