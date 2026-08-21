import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/master/models/varian_body.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'edit_varian_body_dialog.dart';

class VarianBodyDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  VarianBodyDataSource(this._ref, this.context) {
    // Dengarkan Filter Teks
    _ref.listen(varianBodyFilterProvider, (_, __) => refreshDatasource());
    // Dengarkan Filter Master Data (Dropdown)
    _ref.listen(
      selectedMasterDataFilterProvider,
      (_, __) => refreshDatasource(),
    );
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(varianBodyFilterProvider);
    // Ambil nilai filter Master Data
    final selectedMasterDataItem = _ref.read(selectedMasterDataFilterProvider);
    final selectedMasterDataId = selectedMasterDataItem?.id as int?;
    try {
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getVarianBodyListPaginated(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: filters['search']!,
            sortBy: filters['sortBy']!,
            sortDirection: filters['sortDirection']!,
            masterDataId: selectedMasterDataId, // <-- Kirim ke repository
          );
      return AsyncRowsResponse(
        response.total,
        response.data.map((item) {
          final md = item.masterData;

          return DataRow(
            key: ValueKey(item.id),
            cells: [
              // --- TAMBAHKAN CELL ID DI SINI ---
              DataCell(SelectableText(item.id.toString())),
              // ---------------------------------
              DataCell(SelectableText(md.typeEngine.name)),
              DataCell(SelectableText(md.merk.name)),
              DataCell(SelectableText(md.typeChassis.displayName)),
              DataCell(SelectableText(md.typeChassis.nomorSut ?? '-')),
              DataCell(SelectableText(md.jenisKendaraan.name)),
              DataCell(SelectableText(item.name)),
              DataCell(
                SelectableText(dateFormat.format(item.createdAt!.toLocal())),
              ),
              DataCell(
                SelectableText(dateFormat.format(item.updatedAt!.toLocal())),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.orange,
                        size: 15,
                      ),
                      onPressed: () {
                        // --- PANGGIL DIALOG EDIT ---
                        showDialog(
                          context: context,
                          builder: (_) =>
                              EditVarianBodyDialog(varianBody: item),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 15,
                      ),
                      onPressed: () => _showDeleteDialog(item),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error fetching Varian Body: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  void _showDeleteDialog(VarianBody item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await _ref
                    .read(masterDataRepositoryProvider)
                    .deleteVarianBody(id: item.id);
                refreshDatasource(); // Refresh tabel setelah hapus
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Data berhasil dihapus'),
                      backgroundColor: Colors.orange[400],
                    ),
                  );
                }
              } on DioException catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();

                  final message =
                      e.response?.data['message'] ??
                      e.response?.data['errors']?['general']?[0] ??
                      'Gagal menghapus data';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        message,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
