// File: lib/admin/master/widgets/image_status_datasource.dart

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/master/models/g_gambar_utama.dart';
import 'package:master_gambar/admin/master/models/image_status.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';

// Hapus provider global karena diinstansiasi di UI

class ImageStatusDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  ImageStatusDataSource(this._ref);
  // ImageStatusDataSource(this._ref) {
  //   _ref.listen(imageStatusFilterProvider, (_, __) => refreshDatasource());
  // }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(imageStatusFilterProvider);
    try {
      final response = await _ref
          .read(masterDataRepositoryProvider)
          .getImageStatus(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: (filters['search'] ?? ''),
            sortBy: (filters['sortBy'] ?? 'id'),
            sortDirection: (filters['sortDirection'] ?? 'desc'),
            advancedFilters: filters,
          );

      return AsyncRowsResponse(
        response.total,
        response.data.map((item) {
          final vb = item.varianBody;
          final masterData = vb.masterData;
          final optionalDesc = item.deskripsiOptional ?? 'N/A';
          final bool hasImage = item.gambarUtama != null;

          return DataRow(
            key: ValueKey(vb.id),
            cells: [
              // 1. ID Varian Body
              DataCell(SelectableText(vb.id.toString())),

              // 2. Type Engine
              DataCell(SelectableText(masterData.typeEngine.name)),

              // 3. Merk
              DataCell(SelectableText(masterData.merk.name)),

              // 4. Type Chassis
              DataCell(SelectableText(masterData.typeChassis.displayName)),

              // 5. Jenis Kendaraan
              DataCell(SelectableText(masterData.jenisKendaraan.name)),

              // 6. Varian Body
              DataCell(SelectableText(vb.name)),

              // 7. Gbr Utama (Action Column)
              DataCell(
                Center(
                  child: hasImage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol PREVIEW (Mata)
                            IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                              tooltip: 'Preview Semua Gambar',
                              onPressed: () =>
                                  showPreviewDialog(item.gambarUtama!),
                            ),
                            // Tombol EDIT (Pensil)
                            IconButton(
                              icon: const Icon(
                                size: 16,
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              tooltip: 'Edit / Ganti Gambar',
                              onPressed: () => _navigateToEdit(item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              tooltip: 'Hapus Gambar Utama',
                              onPressed: () => confirmDeleteDialog(item),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          // Tombol ADD (Upload)
                          onPressed: () => _navigateToAdd(item),
                          icon: const Icon(Icons.upload_file, size: 13),
                          label: const Text(
                            'Upload',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 30),
                            backgroundColor: Colors.green, // Tombol hijau
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 0,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                ),
              ),
              /*
              // === KOLOM CREATED AT & UPDATED AT DI-NONAKTIFKAN ===
              // Hapus tanda komentar /* ... */ ini jika ingin mengembalikan sel Created At & Updated At:
              DataCell(
                SelectableText(
                  item.gambarUtamaCreatedAt != null
                      ? dateFormat.format(item.gambarUtamaCreatedAt!.toLocal())
                      : 'Belum ada',
                ),
              ),
              DataCell(
                SelectableText(
                  item.gambarUtamaUpdatedAt != null
                      ? dateFormat.format(item.gambarUtamaUpdatedAt!.toLocal())
                      : 'Belum ada',
                ),
              ),
              */

              // 9. Gbr Optional (Deskripsi)
              DataCell(
                optionalDesc != 'N/A'
                    ? SelectableText(optionalDesc)
                    : Text('Belum ada'),
              ),
            ],
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error fetching Image Status: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  // Method untuk di-override di Table Widget
  void showPreviewDialog(GGambarUtama gambarUtama) {}

  // --- LOGIKA TOMBOL ADD (UPLOAD BARU) ---
  void _navigateToAdd(ImageStatus item) {
    final vb = item.varianBody;
    final md = vb.masterData;

    // 1. Konstruksi Nama Master Data (Gabungan) agar sesuai tampilan Dropdown
    final masterDataName =
        '${md.typeEngine.name} / ${md.merk.name} / ${md.typeChassis.displayName} / ${md.jenisKendaraan.name}';

    // 2. Siapkan Data Paket
    final initialData = {
      // Kita butuh satu OptionItem Master Data yang utuh
      'masterData': OptionItem(id: md.id, name: masterDataName),
      // Dan satu OptionItem Varian Body
      'varianBody': OptionItem(id: vb.id, name: vb.name),
    };

    // 3. Kirim ke Provider
    _ref.read(initialGambarUtamaDataProvider.notifier).state = initialData;

    // 4. Pastikan Mode Edit MATI & Reset File
    _ref.read(mguEditingGambarProvider.notifier).state = null;
    _ref.read(mguGambarUtamaFileProvider.notifier).state = null;
    _ref.read(mguGambarTeruraiFileProvider.notifier).state = null;
    _ref.read(mguGambarKontruksiFileProvider.notifier).state = null;

    // 5. Navigasi ke Tab Gambar Utama
    _ref.read(adminSidebarIndexProvider.notifier).state = 9;
  }

  // --- LOGIKA TOMBOL EDIT (PERBAIKAN) ---
  void _navigateToEdit(ImageStatus item) {
    final vb = item.varianBody;
    final md = vb.masterData;

    // 1. Konstruksi Nama Master Data (Gabungan) agar Dropdown otomatis terisi
    final masterDataName =
        '${md.typeEngine.name} / ${md.merk.name} / ${md.typeChassis.displayName} / ${md.jenisKendaraan.name}';

    // 2. Siapkan Data untuk Dropdown (SAMA SEPERTI ADD)
    final initialData = {
      'masterData': OptionItem(id: md.id, name: masterDataName),
      'varianBody': OptionItem(id: vb.id, name: vb.name),
    };

    // Update Provider Dropdown (Ini yang membuat Form terisi teksnya)
    _ref.read(initialGambarUtamaDataProvider.notifier).state = initialData;

    // 3. Set Mode Edit AKTIF & Kirim Objek Gambar Utama
    // Screen target akan merespon ini dengan mendownload file-file lama
    _ref.read(mguEditingGambarProvider.notifier).state = item.gambarUtama;

    // 4. Navigasi ke Tab Gambar Utama
    _ref.read(adminSidebarIndexProvider.notifier).state = 9;
  }

  void confirmDeleteDialog(ImageStatus item) {}
}
