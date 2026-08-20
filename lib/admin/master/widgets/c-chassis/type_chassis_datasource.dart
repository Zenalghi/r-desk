import 'dart:typed_data';
import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'edit_type_chassis_dialog.dart';
import 'package:master_gambar/app/core/providers.dart';
import '../../models/type_chassis.dart';
import '../../providers/master_data_providers.dart';
import '../../repository/master_data_repository.dart';
import '../../../management/widgets/document/components/pdf_preview_box.dart';

class TypeChassisDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;

  TypeChassisDataSource(this._ref, this.context) {
    _ref.listen(typeChassisFilterProvider, (_, __) => refreshDatasource());
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(typeChassisFilterProvider);
    try {
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getTypeChassisPaginated(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: filters['search']!,
            sortBy: filters['sortBy']!,
            sortDirection: filters['sortDirection']!,
          );

      return AsyncRowsResponse(
        response.total,
        response.data.map((item) {
          final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
          return DataRow(
            key: ValueKey(item.id),
            cells: [
              DataCell(SelectableText(item.id.toString())),
              DataCell(SelectableText(item.name)),
              DataCell(SelectableText(item.nomorSut ?? '-')),
              DataCell(SelectableText(item.merekDagang ?? '-')),
              DataCell(SelectableText(item.jenisTipe ?? '-')),
              // DataCell(SelectableText('${item.merk.name} (${item.merk.id})')),
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
                    if (item.sutPdfPath != null && item.sutPdfPath!.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          size: 15,
                          color: Colors.blueAccent,
                        ),
                        tooltip: 'Preview PDF SUT',
                        onPressed: () => _showPreviewPdfDialog(item),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.orange,
                      ),
                      onPressed: () => _showEditDialog(item),
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
      debugPrint('Error fetching Type Chassis: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  void _showPreviewPdfDialog(TypeChassis item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 900, maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Preview PDF SUT: ${item.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      // border: Border.all(color: Colors.grey.shade400),
                      child: A4PdfPreviewer(
                        cacheKey:
                            'sut_pdf_${item.id}_${item.updatedAt.millisecondsSinceEpoch}',
                        futureLoader: () async {
                          final response = await _ref
                              .read(apiClientProvider)
                              .dio
                              .get(
                                '/type-chassis/${item.id}/sut-pdf',
                                options: Options(
                                  responseType: ResponseType.bytes,
                                ),
                              );
                          return Uint8List.fromList(response.data);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(TypeChassis item) {
    showDialog(
      context: context,
      builder: (context) =>
          EditTypeChassisDialog(item: item, onUpdated: refreshDatasource),
    );
  }

  void _showDeleteDialog(TypeChassis item) {
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
                    .deleteTypeChassis(id: item.id);
                refreshDatasource();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Type Chassis berhasil dihapus'),
                      backgroundColor: Colors.orange[400],
                    ),
                  );
                }
              } on DioException catch (e) {
                final errorMessages = e.response?.data['errors'];
                final message = errorMessages != null
                    ? errorMessages['general'][0]
                    : 'Terjadi kesalahan: ${e.response?.data['message']}';

                if (context.mounted) {
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
