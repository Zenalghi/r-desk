// File: lib/admin/master/widgets/image_status_table.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/models/g_gambar_utama.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import '../../models/image_status.dart';
import '../../repository/master_data_repository.dart';
import 'image_status_datasource.dart';
import 'gambar_utama_viewer_dialog.dart';

class ImageStatusTable extends ConsumerStatefulWidget {
  const ImageStatusTable({super.key});

  @override
  ConsumerState<ImageStatusTable> createState() => _ImageStatusTableState();
}

class _ImageStatusTableState extends ConsumerState<ImageStatusTable> {
  // Sesuaikan default UI dengan Provider (ID Descending)
  int _sortColumnIndex = 0;
  bool _sortAscending = false;
  int _rowsPerPage = 50;
  late final _ImageStatusDataSourceWithContext _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _ImageStatusDataSourceWithContext(ref, context);

    // TRICK: Pancing datasource untuk refresh setelah widget selesai dibangun
    Future.microtask(() => _dataSource.refreshDatasource());
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Pindahkan listen ke sini (di dalam build)
    ref.listen(imageStatusFilterProvider, (_, __) {
      _dataSource.refreshDatasource();
    });

    return AsyncPaginatedDataTable2(
      columnSpacing: 3,
      horizontalMargin: 10,
      minWidth: 900,
      headingRowHeight: 35,
      dataRowHeight: 30,
      rowsPerPage: _rowsPerPage,
      availableRowsPerPage: const [50, 100],
      onRowsPerPageChanged: (value) {
        if (value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _rowsPerPage = value;
            });
          });
        }
      },
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: _createColumns(),
      source: _dataSource,
      loading: const Center(child: CircularProgressIndicator()),
      empty: const Center(child: Text('Tidak ada data ditemukan')),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    // PETUNJUK MENGEMBALIKAN KOLOM CREATED AT & UPDATED AT:
    // Jika ingin mengembalikan kolom Created At & Updated At:
    // 1. Un-comment mapping 7 ('created_at') & 8 ('updated_at') di bawah ini.
    // 2. Ubah index 'deskripsi_optional' kembali menjadi 9.
    // 3. Un-comment DataColumn2 'Created At' & 'Updated At' di _createColumns().
    // 4. Un-comment DataCell 'Created At' & 'Updated At' di image_status_datasource.dart.
    final Map<int, String> columnMapping = {
      0: 'id',
      1: 'type_engine',
      2: 'merk',
      3: 'type_chassis',
      4: 'jenis_kendaraan',
      5: 'varian_body',
      // 7: 'created_at',
      // 8: 'updated_at',
      7: 'deskripsi_optional',
    };

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    ref.read(imageStatusFilterProvider.notifier).update((state) {
      return {
        ...state,
        'sortBy': columnMapping[columnIndex] ?? 'id',
        'sortDirection': ascending ? 'asc' : 'desc',
      };
    });
  }

  List<DataColumn2> _createColumns() {
    return [
      // 1. ID Varian Body
      DataColumn2(label: const Text('ID'), fixedWidth: 40, onSort: _onSort),

      // 2. Type Engine
      DataColumn2(
        label: const Text('Type\nEngine'),
        fixedWidth: 62,
        onSort: _onSort,
      ),

      // 3. Merk
      DataColumn2(label: const Text('Merk'), fixedWidth: 90, onSort: _onSort),

      // 4. Type Chassis
      DataColumn2(
        label: const Text('Type Chassis'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),

      // 5. Jenis Kendaraan
      DataColumn2(
        label: const Text('Jenis Kendaraan'),
        fixedWidth: 210,
        onSort: _onSort,
      ),

      // 6. Varian Body
      DataColumn2(
        label: const Text('Varian Body'),
        size: ColumnSize.L,
        onSort: _onSort,
      ),

      // 7. Gbr Utama (Action Column)
      const DataColumn2(
        label: Center(child: Text('Gambar Utama', textAlign: TextAlign.center)),
        fixedWidth: 123,
      ),

      /* 
      // === KOLOM CREATED AT & UPDATED AT DI-NONAKTIFKAN ===
      // Hapus tanda komentar /* ... */ ini untuk mengembalikan kolom Created At & Updated At:
      DataColumn2(
        label: const Text('Created At'),
        fixedWidth: 99,
        onSort: _onSort,
      ),
      DataColumn2(
        label: const Text('Updated At'),
        fixedWidth: 99,
        onSort: _onSort,
      ),
      */

      // 8. Gbr. Optional Paket
      DataColumn2(
        label: const Text('Gbr. Optional\nPaket'),
        size: ColumnSize.M,
        onSort: _onSort,
      ),
    ];
  }
}

class _ImageStatusDataSourceWithContext extends ImageStatusDataSource {
  final BuildContext _context;
  final WidgetRef ref;

  _ImageStatusDataSourceWithContext(this.ref, this._context) : super(ref);

  @override
  void showPreviewDialog(GGambarUtama gambarUtama) {
    showDialog(
      context: _context,
      builder: (_) => GambarUtamaViewerDialog(gambarUtama: gambarUtama),
    );
  }

  // UBAH PARAMETER MENJADI 'ImageStatus'
  @override
  void confirmDeleteDialog(ImageStatus item) {
    final gambarUtama = item.gambarUtama!;

    // --- LOGIKA DINAMIS PESAN KONFIRMASI ---
    List<String> filesToDelete = ['Gambar Utama']; // Gambar Utama selalu ada

    // Cek path (string) tidak null & tidak kosong
    if (gambarUtama.pathGambarTerurai != null &&
        gambarUtama.pathGambarTerurai!.isNotEmpty) {
      filesToDelete.add('Terurai');
    }

    if (gambarUtama.pathGambarKontruksi != null &&
        gambarUtama.pathGambarKontruksi!.isNotEmpty) {
      filesToDelete.add('Kontruksi');
    }

    if (item.deskripsiOptional != null) {
      filesToDelete.add('Optional Paket');
    }

    // Gabungkan list menjadi string (e.g., "Gambar Utama, Terurai, dan Optional Paket")
    String filesString = '';
    if (filesToDelete.length == 1) {
      filesString = filesToDelete.first;
    } else {
      final last = filesToDelete.removeLast();
      filesString = '${filesToDelete.join(", ")} dan $last';
    }

    final String contentText =
        'Apakah Anda yakin ingin menghapus data ini?\n\n'
        'PERINGATAN: File PDF ($filesString) akan dihapus permanen dari storage.';
    // ----------------------------------------

    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(contentText),
        actions: [
          // ... (Tombol Batal & Hapus TETAP SAMA) ...
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // ... logic hapus ...
              Navigator.of(context).pop();
              try {
                await ref
                    .read(masterDataRepositoryProvider)
                    .deleteGambarUtama(gambarUtama.id);
                refreshDatasource();
                if (_context.mounted) {
                  ScaffoldMessenger.of(_context).showSnackBar(
                    const SnackBar(
                      content: Text('Gambar berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (_context.mounted) {
                  ScaffoldMessenger.of(_context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus gambar: $e',
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
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }
}
