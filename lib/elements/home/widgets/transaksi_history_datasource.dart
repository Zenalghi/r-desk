import 'dart:ui';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/app/core/providers.dart';
import 'package:master_gambar/data/models/skrb.dart';
import 'package:master_gambar/elements/home/providers/page_state_provider.dart';
import 'package:master_gambar/elements/home/providers/skrb_providers.dart';
import 'package:master_gambar/elements/home/providers/transaksi_providers.dart';
import 'package:master_gambar/elements/home/repository/skrb_repository.dart';
import 'package:master_gambar/elements/home/widgets/skrb/tambah_permohonan_skrb_dialog.dart';
import '../../../data/models/transaksi.dart';
import '../repository/options_repository.dart';
import 'edit_transaksi_dialog.dart';

class TransaksiDataSource extends AsyncDataTableSource {
  final WidgetRef _ref;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  TransaksiDataSource(this._ref, this.context);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    final filters = _ref.read(transaksiFilterProvider);
    final authService = _ref.read(authServiceProvider);
    final currentUserId = _ref.read(currentUserIdProvider);

    try {
      final response = await _ref
          .read(transaksiRepositoryProvider)
          .getTransaksiHistory(
            perPage: count,
            page: (startIndex ~/ count) + 1,
            search: filters['search'] as String,
            sortBy: filters['sortBy'] as String,
            sortDirection: filters['sortDirection'] as String,
            advancedFilters: filters,
          );

      return AsyncRowsResponse(
        response.total,
        response.data.map((trx) {
          final canEdit =
              authService.canViewAdminTabs() || (trx.user.id == currentUserId);

          // Cek apakah ada draft tersimpan
          final bool hasDraft = trx.detail != null;

          return DataRow(
            key: ValueKey(trx.id),
            cells: [
              // 0. ID
              DataCell(SelectableText(trx.id.toString())),
              // 1. Customer
              DataCell(SelectableText(trx.customer.namaPt)),
              // 2. Engine
              DataCell(SelectableText(trx.aTypeEngine.typeEngine)),
              // 3. Merk
              DataCell(SelectableText(trx.bMerk.merk)),
              // 4. Chassis
              DataCell(
                Tooltip(
                  message: 'Nomor SUT: ${trx.cTypeChassis.nomorSut ?? '-'}',
                  child: SelectableText(trx.cTypeChassis.displayName),
                ),
              ),
              // 5. Jenis Kendaraan
              DataCell(SelectableText(trx.dJenisKendaraan.jenisKendaraan)),
              // 6. Jenis Pengajuan
              DataCell(SelectableText(trx.fPengajuan.jenisPengajuan)),

              // 7. Judul Gambar (Gabungan dari detail)
              DataCell(
                SelectableText(trx.judulGambarString ?? '--judul offline--'),
              ),

              // 8. User
              DataCell(SelectableText(trx.user.name)),

              // 9. Created At
              DataCell(
                SelectableText(dateFormat.format(trx.createdAt.toLocal())),
              ),

              // 10. Updated At
              DataCell(
                SelectableText(dateFormat.format(trx.updatedAt.toLocal())),
              ),

              // Options
              DataCell(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 15,
                          color: canEdit ? Colors.orange.shade700 : Colors.grey,
                        ),
                        tooltip: canEdit
                            ? 'Edit Data Transaksi'
                            : 'Anda tidak punya akses',
                        onPressed: canEdit ? () => _showEditDialog(trx) : null,
                      ),

                      // Tombol input gambar / Lanjut Draft
                      IconButton(
                        icon: Icon(
                          // Ganti Icon jika ada Draft
                          hasDraft ? Icons.edit_document : Icons.open_in_new,
                          size: 15,
                          // Ganti Warna jika ada Draft
                          color: hasDraft
                              ? Colors.lightBlueAccent
                              : Colors.blue,
                        ),
                        tooltip: hasDraft
                            ? 'Detail Transaksi'
                            : 'Proses Transaksi Baru',
                        onPressed: () {
                          _ref.read(pageStateProvider.notifier).state =
                              PageState(pageIndex: 1, data: trx);
                        },
                      ),

                      // Tombol Buat / Lihat SKRB
                      // Disembunyikan jika jenis pengajuan adalah GAMBAR TU (id=4)
                      if (trx.fPengajuan.id != 4)
                        IconButton(
                          icon: Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 16,
                            color: hasDraft ? Colors.teal : Colors.grey,
                          ),
                          tooltip: hasDraft
                              ? 'Buat / Lihat Permohonan SKRB'
                              : 'Buat / Lihat Permohonan SKRB (Detail/Draft belum dibuat)',
                          onPressed: !hasDraft
                              ? null
                              : () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: Dialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 28,
                                            vertical: 24,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text(
                                                'Harap tunggu sebentar...\nMemeriksa Status SKRB',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  try {
                                    final skrbRepo = _ref.read(
                                      skrbRepositoryProvider,
                                    );
                                    final existingSkrb = await skrbRepo
                                        .getSkrbByTransaksi(trx.id);

                                    if (context.mounted) {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Tutup loading dialog

                                      if (existingSkrb != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Mengalihkan ke Detail SKRB yang sudah dibuat sebelumnya (${existingSkrb.idSkrb}).',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade700,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                        _ref
                                            .read(pageStateProvider.notifier)
                                            .state = PageState(
                                          pageIndex: 3,
                                          skrbId: existingSkrb.id,
                                        );
                                      } else {
                                        final newSkrb = await showDialog<Skrb?>(
                                          context: context,
                                          builder: (_) =>
                                              TambahPermohonanSkrbDialog(
                                                initialTransaksiId: trx.id,
                                              ),
                                        );

                                        if (newSkrb != null &&
                                            context.mounted) {
                                          _ref.invalidate(skrbListProvider);
                                          _ref.invalidate(
                                            availableTransactionsProvider,
                                          );

                                          if (newSkrb.alreadyExists) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'SKRB untuk transaksi ini sudah ada (${newSkrb.idSkrb}). Mengalihkan ke tabel Permohonan SKRB.',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blue.shade700,
                                                duration: const Duration(
                                                  seconds: 4,
                                                ),
                                              ),
                                            );
                                          } else if (newSkrb.idSkrb.contains(
                                                '-SKRB',
                                              ) &&
                                              newSkrb.idSkrb.contains('/x')) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Permohonan SKRB berhasil dibuat dengan ID sementara: ${newSkrb.idSkrb}\nPERHATIAN: "Permohonan SKRB" Customer belum ditambahkan admin! Segera minta admin untuk update.',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.orange.shade800,
                                                duration: const Duration(
                                                  seconds: 10,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Permohonan SKRB berhasil dibuat: ${newSkrb.idSkrb}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }

                                          _ref
                                              .read(pageStateProvider.notifier)
                                              .state = PageState(
                                            pageIndex: 2,
                                          );
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Tutup loading dialog jika error
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error membuka SKRB: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error fetching Transaksi: $e');
      return AsyncRowsResponse(0, []);
    }
  }

  void _showEditDialog(Transaksi trx) {
    showDialog(
      context: context,
      builder: (_) => EditTransaksiDialog(transaksi: trx),
    );
  }
}
