// File: lib/admin/master/widgets/gambar_optional_datasource.dart

import 'package:data_table_2/data_table_2.dart';
// import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/master/models/gambar_optional.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import '../../../../app/theme/app_theme.dart';
// import 'edit_gambar_optional_dialog.dart';
import '../../../../data/models/option_item.dart';
import '../pdf_viewer_dialog.dart'; // Pastikan file ini sudah ada

class GambarOptionalDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  GambarOptionalDataSource(this._ref, this.context) {
    _ref.listen(gambarOptionalFilterProvider, (_, __) => refreshDatasource());
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(gambarOptionalFilterProvider);
    try {
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getGambarOptionalListPaginated(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: filters['search'] as String,
            sortBy: filters['sortBy'] as String,
            sortDirection: filters['sortDirection'] as String,
          );

      return AsyncRowsResponse(
        response.total,
        response.data.map((item) {
          // --- PERUBAHAN UTAMA DI SINI ---
          // Kita ambil data langsung dari masterData (karena independen)
          final md = item.masterData;

          return DataRow(
            key: ValueKey(item.id),
            cells: [
              DataCell(SelectableText(item.id.toString())),
              DataCell(SelectableText(md?.typeEngine.name ?? '-')),
              DataCell(SelectableText(md?.merk.name ?? '-')),
              DataCell(
                SelectableText(
                  md?.typeChassis.displayName ?? '-',
                  style: AppTextStyles.dynamicSize(md?.typeChassis.displayName ?? ''),
                ),
              ),
              DataCell(SelectableText(md?.typeChassis.nomorSut ?? '-')),
              DataCell(SelectableText(md?.jenisKendaraan.name ?? '-')),

              // HAPUS CELL VARIAN BODY & TIPE
              DataCell(
                SelectableText(
                  item.deskripsi,
                  style: AppTextStyles.dynamicSize(item.deskripsi),
                ),
              ),
              DataCell(
                SelectableText(dateFormat.format(item.createdAt.toLocal())),
              ),
              DataCell(
                SelectableText(dateFormat.format(item.updatedAt.toLocal())),
              ),

              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy (Sesuaikan parameter copy jika perlu masterDataId)
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy,
                        size: 15,
                        color: Colors.lightBlueAccent,
                      ),
                      tooltip: 'Copy Data',
                      onPressed: () => _copyItemToForm(item),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.visibility,
                        size: 15,
                        color: Colors.blue.shade700,
                      ),
                      tooltip: 'Lihat PDF',
                      onPressed: () => _showPdfPreview(item),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        _ref
                                .read(editingGambarOptionalProvider.notifier)
                                .state =
                            item;
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 15,
                        color: Colors.red,
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
      debugPrint('Error fetching Gambar Optional: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  void _showPdfPreview(GambarOptional item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfData = await _ref
          .read(masterDataRepositoryProvider)
          .getGambarOptionalPdf(item.id);

      if (context.mounted) Navigator.of(context).pop(); // Tutup loading

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              PdfViewerDialog(pdfData: pdfData, title: item.deskripsi),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // Tutup loading

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat PDF: ${e.toString()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(GambarOptional item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus gambar "${item.deskripsi}"?'),
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
                    .deleteGambarOptional(id: item.id);
                refreshDatasource();
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _copyItemToForm(GambarOptional item) {
    // COPY LOGIC: Ambil Master Data langsung
    final md = item.masterData;

    if (md != null) {
      final masterDataName =
          '${md.typeEngine.name} / ${md.merk.name} / ${md.typeChassis.displayName} / ${md.jenisKendaraan.name}';

      // Isi Provider Initial Data (Hanya Master Data, Varian Body Kosong/Null)
      _ref.read(initialGambarUtamaDataProvider.notifier).state = {
        'masterData': OptionItem(id: md.id, name: masterDataName),
        'varianBody': OptionItem(id: 0, name: ''), // Dummy atau null
      };

      _ref.read(editingGambarOptionalProvider.notifier).state = null;
      _ref.read(copyGambarOptionalTriggerProvider.notifier).state++;
    }
  }
}
