// lib/admin/management/repository/customer_repository.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../data/models/customer.dart';
import '../../../app/core/providers.dart';
import '../../../data/models/paginated_response.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository(ref));

class CustomerRepository {
  final Ref _ref;
  CustomerRepository(this._ref);

  Future<PaginatedResponse<Customer>> getCustomers({
    required int page,
    required int rowsPerPage,
    required String sortBy,
    required bool sortAscending,
    String? searchQuery,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .get(
          '/admin/customers',
          queryParameters: {
            'page': page,
            'per_page': rowsPerPage,
            'sort_by': sortBy,
            'sort_asc': sortAscending.toString(),
            if (searchQuery != null && searchQuery.isNotEmpty)
              'search': searchQuery,
          },
        );
    // Parse response menggunakan PaginatedResponse
    return PaginatedResponse.fromJson(response.data, Customer.fromJson);
  }

  Future<Customer> addCustomer({
    required String namaPt,
    required String pj,
    String? namaLengkap,
    String? jabatan,
    String? namaDrafter,
    String? namaPemeriksa,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post(
          '/admin/customers',
          data: {
            'nama_pt': namaPt,
            'pj': pj,
            'nama_lengkap': namaLengkap,
            'jabatan': jabatan,
            'nama_drafter': namaDrafter,
            'nama_pemeriksa': namaPemeriksa,
          },
        );
    return Customer.fromJson(response.data);
  }

  // --- PERUBAHAN: Tambah parameter drafter & pemeriksa ---
  Future<Customer> updateCustomer({
    required int id,
    required String namaPt,
    required String pj,
    String? namaLengkap,
    String? jabatan,
    String? namaDrafter,
    String? namaPemeriksa,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .dio
        .put(
          '/admin/customers/$id',
          data: {
            'nama_pt': namaPt,
            'pj': pj,
            'nama_lengkap': namaLengkap,
            'jabatan': jabatan,
            'nama_drafter': namaDrafter,
            'nama_pemeriksa': namaPemeriksa,
          },
        );
    return Customer.fromJson(response.data);
  }

  // DELETE a customer
  Future<void> deleteCustomer({required int id}) async {
    await _ref.read(apiClientProvider).dio.delete('/admin/customers/$id');
  }

  // Upload Paraf PJ
  Future<Customer> uploadSignature({
    required int customerId,
    required Uint8List bytes, // Ubah parameter ini
    required String fileName, // Tambah parameter ini
  }) async {
    final formData = FormData.fromMap({
      'paraf_pj': MultipartFile.fromBytes(
        // Ubah dari fromFile menjadi fromBytes
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'png'),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/customers/$customerId/paraf', data: formData);
    return Customer.fromJson(response.data);
  }

  // --- LAKUKAN HAL YANG SAMA UNTUK DRAFTER ---
  Future<Customer> uploadSignatureDrafter({
    required int customerId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'paraf_drafter': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'png'),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/customers/$customerId/paraf', data: formData);
    return Customer.fromJson(response.data);
  }

  // --- LAKUKAN HAL YANG SAMA UNTUK PEMERIKSA ---
  Future<Customer> uploadSignaturePemeriksa({
    required int customerId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'paraf_pemeriksa': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('image', 'png'),
      ),
    });

    final response = await _ref
        .read(apiClientProvider)
        .dio
        .post('/admin/customers/$customerId/paraf', data: formData);
    return Customer.fromJson(response.data);
  }
}
