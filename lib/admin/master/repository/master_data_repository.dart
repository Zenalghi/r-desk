// lib/admin/master/repository/master_data_repository.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/app/core/providers.dart';
import '../../../data/models/option_item.dart';
import '../../../data/models/paginated_response.dart';
import '../models/image_status.dart';
import '../models/master_data.dart';
import '../models/master_kelistrikan_file.dart';
import '../models/master_varian.dart';
import '../models/type_engine.dart';
import '../models/merk.dart';
import '../models/type_chassis.dart';
import '../models/jenis_kendaraan.dart';
import '../models/varian_body.dart';
import '../models/jenis_varian.dart';
import '../models/gambar_optional.dart';
import '../models/gambar_kelistrikan.dart';
import '../models/g_gambar_utama.dart';
import '../providers/master_data_providers.dart';
import 'package:http_parser/http_parser.dart';

final masterDataRepositoryProvider = Provider(
  (ref) => MasterDataRepository(ref),
);

class AddVarianBodyResult {
  final List<VarianBody> created;
  final List<String> skipped;

  const AddVarianBodyResult({required this.created, required this.skipped});

  factory AddVarianBodyResult.fromResponse(dynamic responseData) {
    if (responseData is List) {
      final created = responseData
          .whereType<Map>()
          .map((item) => VarianBody.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return AddVarianBodyResult(created: created, skipped: const []);
    }

    if (responseData is Map<String, dynamic>) {
      final createdData = responseData['created'];
      final skippedData = responseData['skipped'];

      final created = createdData is List
          ? createdData
                .whereType<Map>()
                .map(
                  (item) =>
                      VarianBody.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <VarianBody>[];

      final skipped = skippedData is List
          ? skippedData.whereType<String>().toList()
          : skippedData is List
          ? skippedData.map((item) => item.toString()).toList()
          : <String>[];

      return AddVarianBodyResult(created: created, skipped: skipped);
    }

    return const AddVarianBodyResult(created: [], skipped: []);
  }
}

class MasterDataRepository {
  final Ref _ref;
  MasterDataRepository(this._ref);

  MultipartFile _buildPdfMultipart(PdfFileData fileData, String fallbackName) {
    String fileName = fileData.name;

    // Pastikan nama file punya ekstensi .pdf
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }

    // --- KEMBALIKAN KE Uint8List MURNI ---
    return MultipartFile.fromBytes(
      fileData.bytes,
      filename: fileName,
      contentType: MediaType('application', 'pdf'),
    );
  }

  // --- METODE BARU YANG ANDA BUTUHKAN ---
  Future<List<OptionItem>> getMasterDataOptions(String search) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/options/master-data', queryParameters: {'search': search});

    // Backend mengirim list, kita mapping ke OptionItem
    final List<dynamic> data = response.data;
    return data.map((e) => OptionItem.fromJson(e, nameKey: 'name')).toList();
  }

  // == TYPE ENGINE ==
  Future<List<TypeEngine>> getTypeEngines() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/type-engines');
    final List<dynamic> data = response.data;
    return data.map((item) => TypeEngine.fromJson(item)).toList();
  }

  Future<TypeEngine> addTypeEngine({required String typeEngine}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/type-engines', data: {'type_engine': typeEngine});
    return TypeEngine.fromJson(response.data);
  }

  Future<TypeEngine> updateTypeEngine({
    required int id,
    required String typeEngine,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put('/type-engines/$id', data: {'type_engine': typeEngine});
    return TypeEngine.fromJson(response.data);
  }

  Future<void> deleteTypeEngine({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/type-engines/$id');
  }

  // --- FITUR RECYCLE BIN TYPE ENGINE ---
  Future<List<TypeEngine>> getDeletedTypeEngines() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/type-engines/trash');
    final List<dynamic> data = response.data;
    return data.map((item) => TypeEngine.fromJson(item)).toList();
  }

  Future<void> restoreTypeEngine(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/type-engines/$id/restore');
  }

  Future<void> forceDeleteTypeEngine(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/type-engines/$id/force-delete');
  }

  // == MERK (PAGINATED) ==
  Future<PaginatedResponse<Merk>> getMerksPaginated({
    int page = 1,
    int perPage = 25,
    String sortBy = 'id',
    String sortDirection = 'asc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/merks',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(response.data, Merk.fromJson);
  }

  Future<List<Merk>> getMerks() async {
    final response = await _ref.read(apiClientProvider).dio.get('/merks');
    final List<dynamic> data = response.data;
    return data.map((item) => Merk.fromJson(item)).toList();
  }

  Future<Merk> addMerk({required String merk}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/merks', data: {'merk': merk});
    return Merk.fromJson(response.data);
  }

  Future<Merk> updateMerk({required int id, required String merk}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put('/merks/$id', data: {'merk': merk});
    return Merk.fromJson(response.data);
  }

  Future<void> deleteMerk({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/merks/$id');
  }

  Future<List<Merk>> getDeletedMerks({String search = ''}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/merks/trash', queryParameters: {'search': search});

    final List<dynamic> data = response.data;
    return data.map((item) => Merk.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> emptyTrashMerk() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/merks/trash/empty');
    return response.data;
  }

  Future<void> restoreMerk(int id) async {
    await _ref.read(apiClientProvider).dio.post('/admin/merks/$id/restore');
  }

  Future<void> forceDeleteMerk(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/merks/$id/force-delete');
  }

  // == TYPE CHASSIS (PAGINATED) ==
  Future<PaginatedResponse<TypeChassis>> getTypeChassisPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'id',
    String sortDirection = 'asc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/type-chassis',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(response.data, TypeChassis.fromJson);
  }

  Future<List<TypeChassis>> getTypeChassis() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/type-chassis');
    final List<dynamic> data = response.data;
    return data.map((item) => TypeChassis.fromJson(item)).toList();
  }

  Future<TypeChassis> addTypeChassis({
    required String typeChassis,
    String? nomorSut,
    String? merekDagang,
    String? jenisTipe,
    PlatformFile? sutPdfFile,
  }) async {
    final Map<String, dynamic> dataMap = {
      'type_chassis': typeChassis,
      if (nomorSut != null && nomorSut.trim().isNotEmpty)
        'nomor_sut': nomorSut.trim(),
      if (merekDagang != null && merekDagang.trim().isNotEmpty)
        'merek_dagang': merekDagang.trim(),
      if (jenisTipe != null && jenisTipe.trim().isNotEmpty)
        'jenis_tipe': jenisTipe.trim(),
    };
    if (sutPdfFile != null && sutPdfFile.bytes != null) {
      dataMap['sut_file'] = MultipartFile.fromBytes(
        sutPdfFile.bytes!,
        filename: sutPdfFile.name,
      );
    }
    final formData = FormData.fromMap(dataMap);
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/type-chassis', data: formData);
    return TypeChassis.fromJson(response.data);
  }

  Future<TypeChassis> updateTypeChassis({
    required int id,
    required String typeChassis,
    String? nomorSut,
    String? merekDagang,
    String? jenisTipe,
    PlatformFile? sutPdfFile,
    bool removeSutPdf = false,
  }) async {
    final Map<String, dynamic> dataMap = {
      'type_chassis': typeChassis,
      'nomor_sut': nomorSut ?? '',
      'merek_dagang': merekDagang ?? '',
      'jenis_tipe': jenisTipe ?? '',
      '_method': 'PUT',
    };
    if (sutPdfFile != null && sutPdfFile.bytes != null) {
      dataMap['sut_file'] = MultipartFile.fromBytes(
        sutPdfFile.bytes!,
        filename: sutPdfFile.name,
      );
    }
    if (removeSutPdf) {
      dataMap['remove_sut_file'] = '1';
    }
    final formData = FormData.fromMap(dataMap);
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/type-chassis/$id', data: formData);
    return TypeChassis.fromJson(response.data);
  }

  Future<void> deleteTypeChassis({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/type-chassis/$id');
  }

  getDeletedTypeChassis({String search = ''}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/type-chassis/trash', queryParameters: {'search': search});
    final List<dynamic> data = response.data;
    return data.map((item) => TypeChassis.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> emptyTrashTypeChassis() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/type-chassis/trash/empty');
    return response.data;
  }

  Future<void> restoreTypeChassis(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/type-chassis/$id/restore');
  }

  Future<void> forceDeleteTypeChassis(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/type-chassis/$id/force-delete');
  }

  Future<String?> exportTypeChassisExcel() async {
    final now = DateTime.now();
    final timeStr =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Export Excel Master Type Chassis...',
      fileName: 'Master_Type_Chassis_$timeStr.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );

    if (outputPath == null) {
      return null;
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/type-chassis/export-excel',
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

    await File(outputPath).writeAsBytes(response.data);
    return outputPath;
  }

  Future<Map<String, dynamic>?> importTypeChassisExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel / CSV untuk Diimport...',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final Uint8List? bytes =
        file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);

    if (bytes == null) {
      throw Exception('Gagal membaca data file Excel.');
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: file.name.endsWith('.csv')
            ? MediaType('text', 'csv')
            : MediaType(
                'application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/type-chassis/import-excel',
          data: formData,
          options: Options(receiveTimeout: const Duration(minutes: 5)),
        );

    return response.data as Map<String, dynamic>;
  }

  // == JENIS KENDARAAN (PAGINATED) ==
  Future<PaginatedResponse<JenisKendaraan>> getJenisKendaraanListPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'id',
    String sortDirection = 'asc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/jenis-kendaraan',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(response.data, JenisKendaraan.fromJson);
  }

  Future<List<JenisKendaraan>> getJenisKendaraanList() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/jenis-kendaraan');
    final List<dynamic> data = response.data;
    return data.map((item) => JenisKendaraan.fromJson(item)).toList();
  }

  Future<JenisKendaraan> addJenisKendaraan({
    required String jenisKendaraan,
    String? aliasKendaraan,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/jenis-kendaraan',
          data: {
            'jenis_kendaraan': jenisKendaraan,
            if (aliasKendaraan != null && aliasKendaraan.trim().isNotEmpty)
              'alias_kendaraan': aliasKendaraan.trim(),
          },
        );
    return JenisKendaraan.fromJson(response.data);
  }

  Future<JenisKendaraan> updateJenisKendaraan({
    required int id,
    required String jenisKendaraan,
    String? aliasKendaraan,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put(
          '/jenis-kendaraan/$id',
          data: {
            'jenis_kendaraan': jenisKendaraan,
            'alias_kendaraan': aliasKendaraan ?? '',
          },
        );
    return JenisKendaraan.fromJson(response.data);
  }

  Future<void> deleteJenisKendaraan({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/jenis-kendaraan/$id');
  }

  Future<List<JenisKendaraan>> getDeletedJenisKendaraan({
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/jenis-kendaraan/trash',
          queryParameters: {'search': search},
        );
    final List<dynamic> data = response.data;
    return data.map((item) => JenisKendaraan.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> emptyTrashJenisKendaraan() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/jenis-kendaraan/trash/empty');
    return response.data;
  }

  Future<void> restoreJenisKendaraan(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/jenis-kendaraan/$id/restore');
  }

  Future<void> forceDeleteJenisKendaraan(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/jenis-kendaraan/$id/force-delete');
  }

  // ==========================================
  // == REPOSITORY MASTER VARIAN (BARU) ==
  // ==========================================

  Future<PaginatedResponse<MasterVarian>> getMasterVarianPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
    int? jenisKendaraanId,
  }) async {
    final queryParams = {
      'page': page,
      'perPage': perPage,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
      'search': search,
    };

    if (jenisKendaraanId != null) {
      queryParams['d_jenis_kendaraan_id'] = jenisKendaraanId;
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/master-varian', queryParameters: queryParams);
    return PaginatedResponse.fromJson(response.data, MasterVarian.fromJson);
  }

  Future<MasterVarian> addMasterVarian({
    required int jenisKendaraanId,
    required String namaVarian,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/master-varian',
          data: {
            'd_jenis_kendaraan_id': jenisKendaraanId,
            'nama_varian': namaVarian,
          },
        );
    return MasterVarian.fromJson(response.data);
  }

  Future<MasterVarian> updateMasterVarian({
    required int id,
    required int jenisKendaraanId,
    required String namaVarian,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put(
          '/admin/master-varian/$id',
          data: {
            'd_jenis_kendaraan_id': jenisKendaraanId,
            'nama_varian': namaVarian,
          },
        );
    return MasterVarian.fromJson(response.data);
  }

  Future<void> deleteMasterVarian({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/admin/master-varian/$id');
  }

  // Opsi Dropdown Checkbox berdasarkan Jenis Kendaraan
  Future<List<OptionItem>> getMasterVarianOptions(
    int jenisKendaraanId, {
    String search = '',
  }) async {
    // Path yang benar: /admin/options/master-varian/...
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/options/master-varian/$jenisKendaraanId',
          queryParameters: {'search': search},
        );
    final List<dynamic> data = response.data;
    return data.map((e) => OptionItem.fromJson(e, nameKey: 'name')).toList();
  }

  // --- EXPORT MASTER VARIAN KE EXCEL ---
  Future<String?> exportMasterVarianExcel() async {
    final now = DateTime.now();
    final timeStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Export Excel Master Varian Body...',
      fileName: 'Master_Varian_Body_$timeStr.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );

    if (outputPath == null) {
      return null;
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/master-varian/export-excel',
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

    await File(outputPath).writeAsBytes(response.data);
    return outputPath;
  }

  // --- IMPORT MASTER VARIAN DARI EXCEL ---
  Future<Map<String, dynamic>?> importMasterVarianExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel / CSV untuk Diimport...',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final Uint8List? bytes =
        file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);

    if (bytes == null) {
      throw Exception('Gagal membaca data file Excel.');
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: file.name.endsWith('.csv')
            ? MediaType('text', 'csv')
            : MediaType(
                'application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/master-varian/import-excel',
          data: formData,
          options: Options(receiveTimeout: const Duration(minutes: 5)),
        );

    return response.data as Map<String, dynamic>;
  }

  // --- RECYCLE BIN MASTER VARIAN ---
  Future<List<MasterVarian>> getDeletedMasterVarians({
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/master-varian-trash', queryParameters: {'search': search});
    final List<dynamic> data = response.data;
    return data.map((item) => MasterVarian.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> emptyTrashMasterVarian() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/master-varian-trash/empty');
    return response.data;
  }

  Future<void> restoreMasterVarian(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/master-varian-trash/$id/restore');
  }

  Future<void> forceDeleteMasterVarian(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/master-varian-trash/$id/force-delete');
  }

  // == VARIAN BODY (PAGINATED) ==
  Future<PaginatedResponse<VarianBody>> getVarianBodyListPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
    int? masterDataId,
  }) async {
    final queryParams = {
      'page': page,
      'perPage': perPage,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
      'search': search,
    };

    if (masterDataId != null) {
      queryParams['master_data_id'] = masterDataId;
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/varian-body', queryParameters: queryParams);
    return PaginatedResponse.fromJson(response.data, VarianBody.fromJson);
  }

  Future<List<VarianBody>> getVarianBodyList() async {
    final response = await _ref.read(apiClientProvider).dio.get('/varian-body');
    final List<dynamic> data = response.data;
    return data.map((item) => VarianBody.fromJson(item)).toList();
  }

  Future<AddVarianBodyResult> addVarianBody({
    required int masterDataId,
    required List<String> varianBodies,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/varian-body',
          data: {'master_data_id': masterDataId, 'varian_bodies': varianBodies},
        );

    return AddVarianBodyResult.fromResponse(response.data);
  }

  Future<VarianBody> updateVarianBody({
    required int id,
    required int masterDataId,
    required String varianBody,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put(
          '/varian-body/$id',
          data: {'master_data_id': masterDataId, 'varian_body': varianBody},
        );
    return VarianBody.fromJson(response.data);
  }

  Future<void> deleteVarianBody({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/varian-body/$id');
  }

  // --- EXPORT VARIAN BODY KE EXCEL ---
  Future<String?> exportVarianBodyExcel() async {
    final now = DateTime.now();
    final timeStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Export Excel Varian Body...',
      fileName: 'Varian_Body_Utama_$timeStr.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );

    if (outputPath == null) {
      return null;
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/varian-body/export-excel',
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

    await File(outputPath).writeAsBytes(response.data);
    return outputPath;
  }

  // --- IMPORT VARIAN BODY DARI EXCEL ---
  Future<Map<String, dynamic>?> importVarianBodyExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel / CSV Varian Body untuk Diimport...',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final Uint8List? bytes =
        file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);

    if (bytes == null) {
      throw Exception('Gagal membaca data file Excel.');
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: file.name.endsWith('.csv')
            ? MediaType('text', 'csv')
            : MediaType(
                'application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/varian-body/import-excel',
          data: formData,
          options: Options(receiveTimeout: const Duration(minutes: 5)),
        );

    return response.data as Map<String, dynamic>;
  }

  Future<List<VarianBody>> getDeletedVarianBodies({String search = ''}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/varian-body/trash', queryParameters: {'search': search});
    final List<dynamic> data = response.data;
    return data.map((item) => VarianBody.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> emptyTrashVarianBody() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/varian-body/trash/empty');
    return response.data;
  }

  Future<void> restoreVarianBody(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/varian-body/$id/restore');
  }

  Future<void> forceDeleteVarianBody(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/varian-body/$id/force-delete');
  }

  // == JENIS VARIAN ==
  Future<List<JenisVarian>> getJenisVarianList() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/jenis-varian');
    final List<dynamic> data = response.data;
    return data.map((item) => JenisVarian.fromJson(item)).toList();
  }

  Future<JenisVarian> addJenisVarian({required String namaJudul}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/jenis-varian', data: {'nama_judul': namaJudul});
    return JenisVarian.fromJson(response.data);
  }

  Future<JenisVarian> updateJenisVarian({
    required int id,
    required String namaJudul,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put('/admin/jenis-varian/$id', data: {'nama_judul': namaJudul});
    return JenisVarian.fromJson(response.data);
  }

  Future<void> deleteJenisVarian({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/admin/jenis-varian/$id');
  }

  Future<GGambarUtama> uploadGambarUtamaWithResult({
    required int masterDataId,
    required String varianBodyName,
    required PdfFileData gambarUtama,
    PdfFileData? gambarTerurai,
    PdfFileData? gambarKontruksi,
  }) async {
    const int maxBytes = 1024 * 1024;
    if (gambarUtama.size > maxBytes)
      throw Exception('Gambar Utama melebihi 1 MB.');

    final Map<String, dynamic> mapData = {
      'master_data_id': masterDataId,
      'varian_body': varianBodyName,
      'gambar_utama': _buildPdfMultipart(gambarUtama, 'gambar_utama.pdf'),
    };

    if (gambarTerurai != null) {
      mapData['gambar_terurai'] = _buildPdfMultipart(
        gambarTerurai,
        'gambar_terurai.pdf',
      );
    }

    if (gambarKontruksi != null) {
      mapData['gambar_kontruksi'] = _buildPdfMultipart(
        gambarKontruksi,
        'gambar_kontruksi.pdf',
      );
    }

    final formData = FormData.fromMap(mapData);
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/gambar-master/utama', data: formData);
    return GGambarUtama.fromJson(response.data);
  }

  Future<void> addGambarOptional({
    String tipe = 'independen',
    String deskripsi = '',
    required PdfFileData gambarOptionalFile,
    int? masterDataId,
    int? gambarUtamaId,
  }) async {
    if (gambarOptionalFile.size > (1024 * 1024)) {
      throw Exception(
        'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
      );
    }

    final Map<String, dynamic> dataMap = {
      'tipe': tipe,
      'deskripsi': deskripsi,
      'gambar_optional': _buildPdfMultipart(
        gambarOptionalFile,
        'gambar_optional.pdf',
      ),
    };

    if (tipe == 'independen') {
      dataMap['master_data_id'] = masterDataId;
    } else {
      dataMap['g_gambar_utama_id'] = gambarUtamaId;
    }

    final formData = FormData.fromMap(dataMap);
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/gambar-optional', data: formData);
  }

  Future<void> updateGambarOptional({
    required int id,
    String? deskripsi,
    PdfFileData? file,
  }) async {
    if (file != null && file.size > (1024 * 1024)) {
      throw Exception(
        'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
      );
    }

    final Map<String, dynamic> mapData = {};
    if (deskripsi != null && deskripsi.isNotEmpty) {
      mapData['deskripsi'] = deskripsi;
    }

    final formData = FormData.fromMap(mapData);

    if (file != null) {
      formData.files.add(
        MapEntry(
          'gambar_optional',
          _buildPdfMultipart(file, 'gambar_optional.pdf'),
        ),
      );
    }

    if (mapData.isEmpty && file == null) return;

    try {
      await _ref
          .read(apiClientProvider)
          .dio
          .post(
            '/admin/master-data/gambar-optional/$id/update-file',
            data: formData,
          );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal update gambar optional',
      );
    }
  }

  Future<void> addGambarKelistrikan({
    required int masterDataId,
    required String deskripsi,
    PdfFileData? gambarKelistrikanFile,
  }) async {
    final Map<String, dynamic> dataMap = {
      'master_data_id': masterDataId,
      'deskripsi': deskripsi,
    };

    if (gambarKelistrikanFile != null) {
      if (gambarKelistrikanFile.size > (1024 * 1024)) {
        throw Exception('Ukuran file kelistrikan melebihi 1 MB.');
      }
      dataMap['gambar_kelistrikan'] = _buildPdfMultipart(
        gambarKelistrikanFile,
        'gambar_kelistrikan.pdf',
      );
    }

    final formData = FormData.fromMap(dataMap);
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/gambar-kelistrikan', data: formData);
  }

  Future<void> uploadKelistrikanFile({
    required int typeEngineId,
    required int merkId,
    required int typeChassisId,
    required PdfFileData file,
  }) async {
    if (file.size > (1024 * 1024)) {
      throw Exception('Ukuran file kelistrikan melebihi 1 MB.');
    }

    final formData = FormData.fromMap({
      'a_type_engine_id': typeEngineId,
      'b_merk_id': merkId,
      'c_type_chassis_id': typeChassisId,
      'gambar_kelistrikan': _buildPdfMultipart(file, 'gambar_kelistrikan.pdf'),
    });

    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/gambar-kelistrikan/files', data: formData);
  }

  // == GAMBAR OPTIONAL ==
  Future<PaginatedResponse<GambarOptional>> getGambarOptionalListPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/gambar-optional',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(response.data, GambarOptional.fromJson);
  }

  Future<void> deleteGambarOptional({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/admin/gambar-optional/$id');
  }

  Future<Uint8List> getGambarOptionalPdf(int id) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/gambar-optional/$id/pdf',
          options: Options(responseType: ResponseType.bytes),
        );
    return response.data;
  }

  Future<bool> checkPaketOptionalExists(int varianBodyId) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .dio
          .get('/options/check-paket-optional/$varianBodyId');
      return response.data['exists'] as bool;
    } catch (e) {
      return false;
    }
  }

  // == REPOSITORY GAMBAR KELISTRIKAN ==
  Future<PaginatedResponse<GambarKelistrikan>>
  getGambarKelistrikanListPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/gambar-kelistrikan',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(
      response.data,
      GambarKelistrikan.fromJson,
    );
  }

  Future<Uint8List> getGambarKelistrikanPdf(int id) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/gambar-kelistrikan/$id/pdf',
          options: Options(responseType: ResponseType.bytes),
        );
    return response.data;
  }

  Future<void> deleteGambarKelistrikan({required int id}) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/gambar-kelistrikan/$id');
  }

  Future<GambarKelistrikan> updateGambarKelistrikan({
    required int id,
    required String deskripsi,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put('/admin/gambar-kelistrikan/$id', data: {'deskripsi': deskripsi});
    return GambarKelistrikan.fromJson(response.data);
  }

  Future<Map<String, dynamic>> checkKelistrikanFileStatus(int chassisId) async {
    try {
      final response = await _ref
          .read(apiClientProvider)
          .dio
          .get('/admin/gambar-kelistrikan/check-file/$chassisId');
      return response.data;
    } catch (e) {
      return {'exists': false};
    }
  }

  // == GUDANG FILE KELISTRIKAN ==
  Future<PaginatedResponse<MasterKelistrikanFile>>
  getKelistrikanFilesPaginated({
    int page = 1,
    int perPage = 50, // Default backend Anda 50
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/gambar-kelistrikan/files',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(
      response.data,
      MasterKelistrikanFile.fromJson,
    );
  }

  // 3. Hapus File Fisik
  Future<void> deleteKelistrikanFile({required int id}) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/gambar-kelistrikan/files/$id');
  }

  Future<void> saveDeskripsiKelistrikan({
    required int masterDataId,
    required String deskripsi,
    int? id,
  }) async {
    final Map<String, dynamic> data = {
      'master_data_id': masterDataId,
      'deskripsi': deskripsi,
    };

    if (id != null) {
      data['id'] = id;
    }

    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/gambar-kelistrikan/deskripsi', data: data);
  }

  // 4. Hapus Deskripsi Kelistrikan
  Future<void> deleteDeskripsiKelistrikan(int id) async {
    try {
      await _ref
          .read(apiClientProvider)
          .dio
          .delete('/admin/gambar-kelistrikan/deskripsi/$id');
    } on DioException catch (e) {
      // Lempar error agar bisa ditangkap UI (untuk menampilkan pesan 422)
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  // == IMAGE STATUS (LAPORAN) ==
  Future<PaginatedResponse<ImageStatus>> getImageStatus({
    int page = 1,
    int perPage = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
    String search = '',
    Map<String, String?>? advancedFilters,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'perPage': perPage,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
      'search': search,
    };

    if (advancedFilters != null) {
      advancedFilters.forEach((key, value) {
        if (value != null && value.isNotEmpty) {
          queryParams[key] = value;
        }
      });
    }

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/image-status', queryParameters: queryParams);
    return PaginatedResponse.fromJson(response.data, ImageStatus.fromJson);
  }

  // == GAMBAR UTAMA PREVIEW (PATHS & VIEW) ==
  Future<Map<String, String>> getGambarUtamaPaths(int gambarUtamaId) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/gambar-utama/$gambarUtamaId/paths');
    return Map<String, String>.from(response.data);
  }

  // 2. Method untuk mengunduh konten PDF berdasarkan path-nya
  Future<Uint8List> getPdfFromPath(String path) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/master-gambar/view',
          queryParameters: {'path': path},
          options: Options(responseType: ResponseType.bytes),
        );
    return response.data;
  }

  Future<void> deleteGambarUtama(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/gambar-master/utama/$id');
  }

  // == MASTER DATA (TABEL UTAMA) ==
  Future<PaginatedResponse<MasterData>> getMasterDataPaginated({
    int page = 1,
    int perPage = 50,
    String sortBy = 'id',
    String sortDirection = 'asc',
    String search = '',
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/master-data',
          queryParameters: {
            'page': page,
            'perPage': perPage,
            'sortBy': sortBy,
            'sortDirection': sortDirection,
            'search': search,
          },
        );
    return PaginatedResponse.fromJson(response.data, MasterData.fromJson);
  }

  Future<MasterData> addMasterData({
    required int typeEngineId,
    required int merkId,
    required int typeChassisId,
    required int jenisKendaraanId,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/master-data',
          data: {
            'a_type_engine_id': typeEngineId,
            'b_merk_id': merkId,
            'c_type_chassis_id': typeChassisId,
            'd_jenis_kendaraan_id': jenisKendaraanId,
          },
        );
    return MasterData.fromJson(response.data);
  }

  Future<MasterData> updateMasterData({
    required int id,
    required int typeEngineId,
    required int merkId,
    required int typeChassisId,
    required int jenisKendaraanId,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put(
          '/admin/master-data/$id',
          data: {
            'a_type_engine_id': typeEngineId,
            'b_merk_id': merkId,
            'c_type_chassis_id': typeChassisId,
            'd_jenis_kendaraan_id': jenisKendaraanId,
          },
        );
    return MasterData.fromJson(response.data);
  }

  // --- RECYCLE BIN MASTER DATA ---
  Future<List<MasterData>> getDeletedMasterData({String search = ''}) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/admin/master-data/trash', queryParameters: {'search': search});
    return (response.data as List)
        .map((item) => MasterData.fromJson(item))
        .toList();
  }

  // Method Baru: Kosongkan Sampah
  Future<Map<String, dynamic>> emptyTrashMasterData() async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/master-data/trash/empty');
    return response.data;
  }

  Future<void> restoreMasterData(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/master-data/$id/restore');
  }

  Future<void> forceDeleteMasterData(int id) async {
    await _ref
        .read(apiClientProvider)
        .dio
        .delete('/admin/master-data/$id/force-delete');
  }

  Future<void> deleteMasterData({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/admin/master-data/$id');
  }

  // == DROPDOWN OPTIONS INDEPENDEN (SEARCHABLE) ==
  Future<List<OptionItem>> getTypeEngineOptions(String search) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/options/type-engines', queryParameters: {'search': search});
    return (response.data as List)
        .map((e) => OptionItem.fromJson(e, nameKey: 'name'))
        .toList();
  }

  Future<List<OptionItem>> getMerkOptions(String search) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/options/merks', queryParameters: {'search': search});
    return (response.data as List)
        .map((e) => OptionItem.fromJson(e, nameKey: 'name'))
        .toList();
  }

  Future<List<OptionItem>> getTypeChassisOptions(String search) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/options/type-chassis', queryParameters: {'search': search});
    return (response.data as List)
        .map((e) => OptionItem.fromJson(e, nameKey: 'name'))
        .toList();
  }

  Future<List<OptionItem>> getJenisKendaraanOptions(String search) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get('/options/jenis-kendaraan', queryParameters: {'search': search});
    return (response.data as List)
        .map((e) => OptionItem.fromJson(e, nameKey: 'name'))
        .toList();
  }
}
