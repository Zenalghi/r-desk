import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/app/core/providers.dart';
import '../../../data/providers/api_endpoints.dart';
import '../providers/input_gambar_providers.dart';

final prosesTransaksiRepositoryProvider = Provider(
  (ref) => ProsesTransaksiRepository(ref),
);

class ProsesTransaksiRepository {
  final Ref _ref;
  ProsesTransaksiRepository(this._ref);

  String _parseDioError(DioException e, String defaultPrefix) {
    if (e.response != null && e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is List<int>) {
          final decodedStr = utf8.decode(data);
          final jsonMap = jsonDecode(decodedStr);
          if (jsonMap is Map && jsonMap['message'] != null) {
            return '$defaultPrefix: ${jsonMap['message']}';
          }
        } else if (data is Map && data['message'] != null) {
          return '$defaultPrefix: ${data['message']}';
        }
      } catch (_) {}
    }
    return '$defaultPrefix: ${e.message}';
  }

  Future<void> saveDraft({
    required String transaksiId,
    required int? pemeriksaId,
    required String pihakPenyetujuan,
    required int jumlahGambar,
    required List<Map<String, dynamic>> dataGambarUtama,
    List<int>? orderedIndependentIds,
    String? deskripsiOptional,
    int descSpace = 0,
    int? iGambarKelistrikanId,
  }) async {
    final kelistrikanId = _ref.read(selectedKelistrikanIdProvider);
    print("DEBUG SAVE: Kelistrikan ID yang akan dikirim: $kelistrikanId");
    try {
      await _ref
          .read(apiClientProvider)
          .dio
          .post(
            '${ApiEndpoints.transaksi}/$transaksiId/save',
            data: {
              'pemeriksa_id': pemeriksaId,
              'pihak_penyetujuan': pihakPenyetujuan,
              'jumlah_gambar': jumlahGambar,
              'data_gambar_utama': dataGambarUtama,
              'ordered_independent_ids': orderedIndependentIds,
              'deskripsi_optional': deskripsiOptional,
              'desc_space': descSpace,
              'i_gambar_kelistrikan_id': iGambarKelistrikanId,
            },
          );
    } on DioException catch (e) {
      throw Exception(
        'Gagal menyimpan draft: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Uint8List> getPreviewPdf({
    required String transaksiId,
    int? pemeriksaId,
    required String pihakPenyetujuan,
    List<Map<String, dynamic>>? dataGambarUtama,
    required List<int> varianBodyIds,
    required List<int> judulGambarIds,
    required List<int>? hGambarOptionalIds,
    required int pageNumber,
    String? deskripsiOptional,
    int descSpace = 0,
    required List<int> orderedIndependentIds,
    int? iGambarKelistrikanId,
    required bool isEditMode,
  }) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .dio
          .post(
            '${ApiEndpoints.transaksi}/$transaksiId/proses',
            data: {
              'pemeriksa_id': pemeriksaId,
              'pihak_penyetujuan': pihakPenyetujuan,
              if (dataGambarUtama != null) 'data_gambar_utama': dataGambarUtama,
              'varian_body_ids': varianBodyIds,
              'judul_gambar_ids': judulGambarIds,
              'h_gambar_optional_ids': hGambarOptionalIds,
              'i_gambar_kelistrikan_id': iGambarKelistrikanId,
              'aksi': 'preview',
              'preview_page': pageNumber,
              'deskripsi_optional': deskripsiOptional,
              'desc_space': descSpace,
              'ordered_independent_ids': orderedIndependentIds,
              'is_edit_mode': isEditMode,
            },
            options: Options(responseType: ResponseType.bytes),
          );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_parseDioError(e, 'Gagal memuat preview'));
    }
  }

  Future<void> downloadProcessedPdfs({
    required String transaksiId,
    required String suggestedFileName,
    required String extension,
    int? pemeriksaId,
    required String pihakPenyetujuan,
    required List<int> varianBodyIds,
    required List<int> judulGambarIds,
    required List<int>? hGambarOptionalIds,
    String? deskripsiOptional,
    int descSpace = 0,
    List<int>? orderedIndependentIds,
    int? iGambarKelistrikanId,
  }) async {
    try {
      // 1. Pilih Lokasi Simpan
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan file...',
        fileName: suggestedFileName,
        allowedExtensions: [extension],
        type: FileType.custom,
      );

      if (outputPath == null) throw Exception('Proses penyimpanan dibatalkan.');

      // 2. Request ke Backend
      final response = await _ref
          .read(apiClientProvider)
          .dio
          .post(
            '${ApiEndpoints.transaksi}/$transaksiId/proses',
            data: {
              'pemeriksa_id': pemeriksaId,
              'pihak_penyetujuan': pihakPenyetujuan,
              'varian_body_ids': varianBodyIds,
              'judul_gambar_ids': judulGambarIds,
              'h_gambar_optional_ids': hGambarOptionalIds,
              'aksi': 'proses',
              'ordered_independent_ids': orderedIndependentIds,
              'deskripsi_optional': deskripsiOptional,
              'desc_space': descSpace,
              'i_gambar_kelistrikan_id': iGambarKelistrikanId,
            },
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(minutes: 5),
              sendTimeout: const Duration(minutes: 1),
            ),
          );

      // 3. Tulis File (Dengan Penanganan Error File Locked)
      try {
        await File(outputPath).writeAsBytes(response.data);
      } on FileSystemException catch (e) {
        // Error Code 32 pada Windows = Sharing violation (File sedang dipakai)
        if (e.osError?.errorCode == 32 ||
            e.message.contains('used by another process')) {
          throw Exception(
            'Gagal menyimpan file. File dengan nama yang sama sedang dibuka oleh aplikasi lain.\n\n'
            'Mohon tutup file tersebut terlebih dahulu, lalu coba lagi.',
          );
        } else if (e.osError?.errorCode == 13) {
          throw Exception(
            'Gagal menyimpan file. Aplikasi tidak memiliki izin akses (Permission Denied).',
          );
        }
        // Lempar error file system lainnya apa adanya
        throw Exception('Gagal menulis file: ${e.message}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Proses server terlalu lama (Timeout). Coba lagi nanti.',
        );
      }
      throw Exception('Gagal memuat proses: ${e.message}');
    } catch (e) {
      // Tangkap Exception custom yang kita lempar di atas (File Locked)
      rethrow;
    }
  }

  // Helper: Ambil Info Kelistrikan berdasarkan Master Data ID
  Future<Map<String, dynamic>?> getKelistrikanByMasterData(
    int masterDataId,
  ) async {
    try {
      // Panggil API baru yang sudah Anda buat di Laravel
      final response = await _ref
          .read(apiClientProvider)
          .dio
          .get('/options/kelistrikan-status/$masterDataId');

      // Response backend: {status_code, display_text, file_id, desc_id}
      // Kita kembalikan mentah-mentah karena formatnya sudah pas
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteTransaksi(String transaksiId) async {
    try {
      await _ref
          .read(apiClientProvider)
          .dio
          .delete('${ApiEndpoints.transaksi}/$transaksiId');
    } on DioException catch (e) {
      throw Exception(
        'Gagal menghapus transaksi: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
