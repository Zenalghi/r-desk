// File: lib/elements/home/widgets/skrb/permohonan_skrb_datasource.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/app/core/app_helpers.dart';
import 'package:master_gambar/data/models/skrb.dart';
import '../../providers/page_state_provider.dart';
import '../../providers/skrb_providers.dart';
import '../../repository/skrb_repository.dart';
import 'edit_skrb_dialog.dart';

class PermohonanSkrbDataSource extends DataTableSource {
  final List<Skrb> skrbList;
  final WidgetRef ref;
  final BuildContext context;

  PermohonanSkrbDataSource({
    required this.skrbList,
    required this.ref,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= skrbList.length) return null;
    final skrb = skrbList[index];
    final colorScheme = Theme.of(context).colorScheme;
    final bool isUnsavedDraft = skrb.fase == 1 || skrb.histories.isEmpty;

    return DataRow2.byIndex(
      index: index,
      cells: [
        DataCell(
          SelectableText(
            skrb.idSkrb,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        DataCell(
          SelectableText(skrb.transaksiId.isNotEmpty ? skrb.transaksiId : '-'),
        ),
        DataCell(SelectableText(skrb.customerName)),
        DataCell(SelectableText(skrb.typeEngine)),
        DataCell(SelectableText(skrb.merk)),
        DataCell(
          Tooltip(
            message: 'Nomor SUT: ${skrb.nomorSut ?? '-'}',
            child: SelectableText(skrb.chassisDisplayName),
          ),
        ),
        DataCell(SelectableText(skrb.jenisKendaraan)),
        DataCell(SelectableText(skrb.jenisPengajuan)),
        DataCell(SelectableText(_formatDate(skrb.createdAt))),
        DataCell(SelectableText(_formatDate(skrb.updatedAt))),
        DataCell(
          _buildStatusTdpWidget(
            skrb.statusTdp,
            skrb.tdpMasaBerlaku,
            skrb.isTdpOutdated,
            colorScheme,
          ),
        ),
        DataCell(_buildActionButtons(skrb, isUnsavedDraft)),
      ],
    );
  }

  /// Komponen tombol tindakan (Action Buttons) untuk tabel permohonan SKRB
  Widget _buildActionButtons(Skrb skrb, bool isUnsavedDraft) {
    // Tentukan Ikon & Tooltip Navigasi Detail berdasarkan kondisi/fase
    IconData detailIcon;
    Color detailColor;
    String detailTooltip;

    if (isUnsavedDraft) {
      detailIcon = Icons.edit_note;
      detailColor = Colors.teal;
      detailTooltip = 'Masuk & Lanjutkan Proses (Belum Disimpan)';
    } else if (skrb.fase == 2) {
      detailIcon = Icons.description_outlined;
      detailColor = Colors.blue;
      detailTooltip = 'Lihat Detail SKRB';
    } else {
      // Fase 3 (Mode Edit)
      detailIcon = Icons.description_outlined;
      detailColor = Colors.orange;
      detailTooltip = 'Masuk ke Detail (Mode Edit)';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol Edit muncul pada Fase 1 dan Fase 2
        if (skrb.fase == 1 || skrb.fase == 2) ...[
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
            tooltip: 'Edit Data SKRB',
            onPressed: () => _handleOpenEditDialog(skrb),
          ),
          const SizedBox(width: 4),
        ],

        // Tombol Navigasi -> Masuk ke Screen DETAIL SKRB
        IconButton(
          icon: Icon(detailIcon, color: detailColor, size: 18),
          tooltip: detailTooltip,
          onPressed: () {
            ref.invalidate(skrbDetailProvider(skrb.id));
            ref.read(pageStateProvider.notifier).state = PageState(
              pageIndex: 3,
              skrbId: skrb.id,
            );
          },
        ),
        const SizedBox(width: 4),

        // Tombol Hapus Total SKRB
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
          tooltip: 'Hapus Permohonan SKRB',
          onPressed: () => _confirmDelete(skrb),
        ),
      ],
    );
  }

  /// Buka dialog untuk edit data inti SKRB (customer, kendaraan, jenis pengajuan)
  Future<void> _handleOpenEditDialog(Skrb skrb) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditSkrbDialog(skrb: skrb),
    );
    if (result == true) {
      ref.invalidate(skrbListProvider);
    }
  }

  /// Dialog konfirmasi untuk hapus total SKRB
  void _confirmDelete(Skrb skrb) {
    final trxInfo = skrb.transaksiId.isNotEmpty
        ? 'Transaksi ${skrb.transaksiId}' // Cara 1: dari Transaksi
        : 'tanpa ID Transaksi'; // Cara 2: mandiri / standalone
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permohonan SKRB'),
        content: Text(
          'Apakah Anda yakin ingin menghapus permohonan SKRB dengan ID ${skrb.idSkrb} ($trxInfo)?\n\nSeluruh arsip file PDF dan folder di storage server akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(skrbRepositoryProvider).deleteSkrb(skrb.id);
                ref.invalidate(skrbListProvider);
                ref.invalidate(availableTransactionsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Permohonan SKRB berhasil dihapus total.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              'Hapus Total',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget indikator status masa berlaku dan sinkronisasi TDP
  Widget _buildStatusTdpWidget(
    String status,
    String? masaBerlakuStr,
    bool isOutdated,
    ColorScheme colorScheme,
  ) {
    String tglStr = '';
    if (masaBerlakuStr != null &&
        masaBerlakuStr.isNotEmpty &&
        masaBerlakuStr != '-') {
      tglStr = '\nMasa Berlaku: ${formatTanggalIndonesia(masaBerlakuStr)}';
    }

    Color color;
    String tooltip;
    IconData icon;

    if (status.toLowerCase() == 'aktif' ||
        status.toLowerCase().contains('aktif')) {
      color = Colors.green.shade600;
      tooltip =
          'Aktif: Masa berlaku TDP masih aman (lebih dari 5 pekan).$tglStr';
      icon = Icons.check_circle;
    } else if (status.toLowerCase() == 'warning' ||
        status.toLowerCase().contains('warn')) {
      color = Colors.orange.shade800;
      tooltip =
          'WARNING: Masa berlaku TDP akan habis dalam 5 pekan atau kurang!$tglStr';
      icon = Icons.warning_amber;
    } else if (status.toLowerCase() == 'expired' ||
        status.toLowerCase().contains('exp')) {
      color = Colors.red.shade700;
      tooltip = 'Expired: Masa berlaku TDP sudah lewat / kadaluarsa!$tglStr';
      icon = Icons.cancel;
    } else if (status.toLowerCase().contains('diperbarui')) {
      color = Colors.blue.shade700;
      tooltip =
          'Diperbarui Admin: TDP telah diupdate oleh Admin pada Document Customer.$tglStr\nMohon edit dan simpan ulang SKRB ini jika ingin menggunakan file TDP terbaru.';
      icon = Icons.update;
    } else {
      color = colorScheme.onSurface;
      tooltip = 'Status: $status$tglStr';
      icon = Icons.help_outline;
    }

    if (isOutdated && !status.toLowerCase().contains('diperbarui')) {
      tooltip +=
          '\n\n💡 TIP: TDP sudah diupdate oleh admin di Document Customer.\nMohon update dan simpan ulang SKRB ini agar versi PDF tersinkronisasi.';
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('Diperbarui Admin', 'Diperbarui\nAdmin'),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          if (isOutdated && !status.toLowerCase().contains('diperbarui')) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.change_circle_outlined,
              size: 14,
              color: Colors.blue.shade700,
            ),
          ],
        ],
      ),
    );
  }

  /// Helper untuk memodifikasi format waktu ISO menjadi yyyy.MM.dd HH:mm
  String _formatDate(String iso) {
    try {
      if (iso.isEmpty || iso == '-') return '-';
      final date = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(date);
    } catch (_) {
      return iso;
    }
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => skrbList.length;
  @override
  int get selectedRowCount => 0;
}
