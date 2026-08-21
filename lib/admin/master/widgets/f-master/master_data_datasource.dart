// File: lib/admin/master/widgets/master_data_datasource.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/master/models/master_data.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'edit_master_data_dialog.dart';
import 'kelistrikan_deskripsi_dialog.dart';

class MasterDataDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  MasterDataDataSource(this._ref, this.context);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(masterDataFilterProvider);
    try {
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getMasterDataPaginated(
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
              DataCell(SelectableText(item.id.toString())),
              DataCell(SelectableText(item.typeEngine.name)),
              DataCell(SelectableText(item.merk.name)),
              DataCell(SelectableText(item.typeChassis.displayName)),
              DataCell(SelectableText(item.typeChassis.nomorSut ?? '-')),
              DataCell(SelectableText(item.jenisKendaraan.name)),
              DataCell(
                SelectableText(
                  item.createdAt != null
                      ? dateFormat.format(item.createdAt!.toLocal())
                      : '',
                ),
              ),
              DataCell(
                SelectableText(
                  item.updatedAt != null
                      ? dateFormat.format(item.updatedAt!.toLocal())
                      : '',
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.lightBlueAccent,
                      ),
                      tooltip: 'Copy Data',
                      onPressed: () {
                        _ref.read(masterDataToCopyProvider.notifier).state =
                            item;
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.orange,
                      ),
                      tooltip: 'Edit Master Data',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => EditMasterDataDialog(masterData: item),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
                      ),
                      tooltip: 'Hapus Master Data',
                      onPressed: () => _showDeleteDialog(item),
                    ),
                  ],
                ),
              ),
              DataCell(_buildKelistrikanCell(item)),
            ],
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error MasterData: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  Widget _buildKelistrikanCell(MasterData item) {
    if (item.fileKelistrikanId == null) {
      return Center(
        child: IconButton(
          icon: const Icon(
            Icons.add_circle_outline,
            size: 16,
            color: Colors.red,
          ),
          tooltip: 'File PDF belum ada. Klik untuk upload.',
          onPressed: () => _navigateToGudangFile(item),
        ),
      );
    }

    if (item.kelistrikanId == null) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange,
            ),
            tooltip: 'File PDF tersedia. Klik untuk isi deskripsi.',
            onPressed: () => _showDeskripsiDialog(item),
          ),
          const Expanded(
            child: Text(
              "Set Deskripsi",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    final int count = item.kelistrikanCount ?? 1;

    if (count > 1) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_note, size: 18, color: Colors.blue),
            tooltip: 'Klik untuk mengelola $count opsi deskripsi',
            onPressed: () => _showDeskripsiDialog(item),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$count Opsi",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: "Data ini memiliki $count variasi deskripsi.",
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
            tooltip: 'Lengkap. Klik untuk Edit Deskripsi.',
            onPressed: () => _showDeskripsiDialog(item),
          ),
          Expanded(
            child: SelectableText(
              item.kelistrikanDeskripsi ?? '',
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              minLines: 1,
            ),
          ),
        ],
      );
    }
  }

  void _showDeskripsiDialog(MasterData item) {
    showDialog(
      context: context,
      builder: (_) => KelistrikanDeskripsiDialog(masterData: item),
    );
  }

  void _navigateToGudangFile(MasterData item) {
    final initialData = {
      'typeEngine': OptionItem(
        id: item.typeEngine.id,
        name: item.typeEngine.name,
      ),
      'merk': OptionItem(id: item.merk.id, name: item.merk.name),
      'typeChassis': OptionItem(
        id: item.typeChassis.id,
        name: item.typeChassis.displayName,
      ),
    };

    _ref.read(initialKelistrikanDataProvider.notifier).state = initialData;
    _ref.read(adminSidebarIndexProvider.notifier).state = 11;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan upload file untuk data ini.')),
    );
  }

  void _showDeleteDialog(MasterData item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus Master Data #${item.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _ref
                    .read(masterDataRepositoryProvider)
                    .deleteMasterData(id: item.id);

                if (context.mounted) {
                  Navigator.pop(context);
                }

                // PERBAIKAN: Gunakan post frame callback untuk refresh setelah dialog tertutup sempurna
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  refreshDatasource();
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error menghapus data: $e',
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
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
