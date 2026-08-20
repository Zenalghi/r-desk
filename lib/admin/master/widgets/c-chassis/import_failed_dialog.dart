import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../repository/master_data_repository.dart';

class ImportFailedDialog extends ConsumerStatefulWidget {
  final List<dynamic> failedRows;
  final String message;

  const ImportFailedDialog({
    super.key,
    required this.failedRows,
    required this.message,
  });

  @override
  ConsumerState<ImportFailedDialog> createState() => _ImportFailedDialogState();
}

class _ImportFailedDialogState extends ConsumerState<ImportFailedDialog> {
  Future<void> _forceDelete(int id, int index) async {
    try {
      await ref.read(masterDataRepositoryProvider).forceDeleteTypeChassis(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data lama (konflik) berhasil dihapus permanen. Silakan Import ulang Excel untuk baris ini.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          // Remove the failed row after deleting permanently so the user sees it's resolved
          widget.failedRows.removeAt(index);
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        final message =
            e.response?.data['errors']?['general']?[0] ??
            'Gagal menghapus data';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Selesai (Ada Data Gagal)'),
      content: SizedBox(
        width: 950,
        height: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(widget.message),
            const SizedBox(height: 10),
            const SelectableText(
              'Detail Gagal:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: widget.failedRows.isEmpty
                  ? const Center(
                      child: Text("Semua data berhasil diselesaikan."),
                    )
                  : ListView.builder(
                      itemCount: widget.failedRows.length,
                      itemBuilder: (context, index) {
                        final f = widget.failedRows[index];
                        final isDeleted =
                            f['is_deleted'] == true || f['is_deleted'] == 1;
                        final conflictId = f['conflict_id'];
                        final statusText = f['status'] ?? 'Aktif';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        'Baris ${f['baris']} - ${f['data']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText('Alasan: ${f['alasan']}'),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        'Status: $statusText',
                                        style: TextStyle(
                                          color: isDeleted
                                              ? Colors.orange[800]
                                              : Colors.blue[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDeleted && conflictId != null)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _forceDelete(conflictId, index),
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Hapus Permanen Data Lama',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
