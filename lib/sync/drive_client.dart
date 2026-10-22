// lib/sync/drive_client.dart
// Klien REST Google Drive v3 yang minimal, khusus folder tersembunyi
// "appDataFolder" milik aplikasi ini di Drive pengguna (scope
// drive.appdata): folder itu tidak terlihat di Drive, tidak bisa dibaca
// aplikasi lain, dan kami (pengembang) tidak punya akses sama sekali.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class DriveFile {
  final String id;
  final DateTime? modifiedTime;
  DriveFile(this.id, this.modifiedTime);
}

class DriveClient {
  DriveClient(Map<String, String> authHeaders)
    : _dio = Dio(
        BaseOptions(
          headers: authHeaders,
          connectTimeout: const Duration(seconds: 20),
        ),
      );

  final Dio _dio;
  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';

  Future<DriveFile?> find(String name) async {
    final res = await _dio.get(
      _api,
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$name' and trashed = false",
        'fields': 'files(id, modifiedTime)',
        'orderBy': 'modifiedTime desc',
      },
    );
    final files = (res.data['files'] as List?) ?? const [];
    if (files.isEmpty) return null;
    final f = files.first as Map;
    return DriveFile(
      f['id'] as String,
      DateTime.tryParse((f['modifiedTime'] as String?) ?? ''),
    );
  }

  Future<Uint8List> download(String fileId) async {
    final res = await _dio.get<List<int>>(
      '$_api/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }

  Future<void> create(String name, Uint8List bytes) async {
    const boundary = 'dompetdigitalku-sync-boundary';
    final body = BytesBuilder()
      ..add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '${jsonEncode({
            'name': name,
            'parents': ['appDataFolder'],
          })}\r\n'
          '--$boundary\r\n'
          'Content-Type: application/octet-stream\r\n\r\n',
        ),
      )
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));
    await _dio.post(
      _upload,
      queryParameters: {'uploadType': 'multipart'},
      data: Stream.value(body.toBytes()),
      options: Options(
        contentType: 'multipart/related; boundary=$boundary',
        headers: {Headers.contentLengthHeader: body.length},
      ),
    );
  }

  Future<void> update(String fileId, Uint8List bytes) async {
    await _dio.patch(
      '$_upload/$fileId',
      queryParameters: {'uploadType': 'media'},
      data: Stream.value(bytes),
      options: Options(
        contentType: 'application/octet-stream',
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
    );
  }

  Future<void> delete(String fileId) async {
    await _dio.delete('$_api/$fileId');
  }
}
