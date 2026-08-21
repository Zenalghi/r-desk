// File: lib/admin/master/widgets/gambar_kelistrikan_datasource.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/master/models/master_kelistrikan_file.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import '../pdf_viewer_dialog.dart';

class GambarKelistrikanDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // Constructor bersih tanpa listener
  GambarKelistrikanDataSource(this._ref, this.context);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(gambarKelistrikanFilterProvider);
    try {
      // Panggil endpoint FILE FISIK
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getKelistrikanFilesPaginated(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: filters['search']!,
            sortBy: filters['sortBy']!,
            sortDirection: filters['sortDirection']!,
          );

      return AsyncRowsResponse(
        response.total,
        response.data.map((item) {
          return DataRow(
            key: ValueKey(item.id),
            cells: [
              // 1. ID
              DataCell(SelectableText(item.id.toString())),
              // 2. Info Kendaraan (String dari Model MasterKelistrikanFile)
              DataCell(SelectableText(item.engineName)),
              DataCell(SelectableText(item.merkName)),
              DataCell(SelectableText(item.chassisName)),
              DataCell(SelectableText(item.nomorSut ?? '-')),

              // 3. Tanggal
              DataCell(
                SelectableText(dateFormat.format(item.createdAt.toLocal())),
              ),
              DataCell(
                SelectableText(dateFormat.format(item.updatedAt.toLocal())),
              ),

              // 4. Options
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TOMBOL EDIT BARU
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
                      tooltip: 'Edit File',
                      onPressed: () {
                        // Set item ke provider agar Form tahu kita sedang edit
                        _ref
                                .read(editingKelistrikanFileProvider.notifier)
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
                      tooltip: 'Hapus File',
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
      debugPrint('Error fetching Kelistrikan Files: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  void _showPdfPreview(MasterKelistrikanFile item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfData = await _ref
          .read(masterDataRepositoryProvider)
          .getPdfFromPath(item.pathFile);
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => PdfViewerDialog(
            pdfData: pdfData,
            title: 'Kelistrikan - ${item.chassisName}',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat PDF: $e',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(MasterKelistrikanFile item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus File Kelistrikan?'),
        content: Text(
          'File fisik untuk chassis "${item.chassisName}" akan dihapus permanen.',
        ),
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
                    .deleteKelistrikanFile(id: item.id);
                refreshDatasource();
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus file: $e',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
