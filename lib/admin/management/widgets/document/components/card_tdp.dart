// lib/admin/management/widgets/document/components/card_tdp.dart
import 'package:flutter/material.dart';
import 'package:master_gambar/app/core/app_helpers.dart';

import 'pdf_preview_box.dart';
import 'shared_widgets.dart';

/// Data untuk satu baris TDP yang sudah ada / belum disimpan.
class TdpRowData {
  final int index;
  final String fileName;
  final int? fileSize;
  final bool isExisting;
  final Widget? previewWidget;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  const TdpRowData({
    required this.index,
    required this.fileName,
    this.fileSize,
    required this.isExisting,
    required this.previewWidget,
    required this.onReplace,
    required this.onDelete,
  });
}

/// Card 3 – TDP (Tanda Daftar Perusahaan).
///
/// Menampilkan daftar TDP existing, daftar TDP baru (pending), slot upload
/// berikutnya, Masa Berlaku, dan Status TDP.
class CardTdp extends StatelessWidget {
  final bool isAdmin;
  final ColorScheme colorScheme;
  final int totalTdpCount;
  final String? localStatus;
  final TextEditingController masaBerlakuCtrl;
  final VoidCallback onPickDate;
  final List<TdpRowData> existingRows;
  final List<TdpRowData> newRows;
  // Slot berikutnya (jika masih < 20)
  final VoidCallback? onPickNextTdp;

  const CardTdp({
    super.key,
    required this.isAdmin,
    required this.colorScheme,
    required this.totalTdpCount,
    required this.localStatus,
    required this.masaBerlakuCtrl,
    required this.onPickDate,
    required this.existingRows,
    required this.newRows,
    required this.onPickNextTdp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Header ===
            Row(
              children: [
                Icon(Icons.folder_copy, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                const Text(
                  'TDP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                // const RequiredBadge(),
                // const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Terdapat $totalTdpCount TDP yang disimpan',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // === Existing TDP rows ===
            for (final row in existingRows) ...[
              _TdpFileRow(
                data: row,
                colorScheme: colorScheme,
                isAdmin: isAdmin,
              ),
              const SizedBox(height: 10),
              if (row != existingRows.last ||
                  newRows.isNotEmpty ||
                  onPickNextTdp != null)
                const Divider(height: 1),
              const SizedBox(height: 10),
            ],

            // === New TDP rows (belum disimpan) ===
            for (int i = 0; i < newRows.length; i++) ...[
              _TdpFileRow(
                data: newRows[i],
                colorScheme: colorScheme,
                isAdmin: isAdmin,
              ),
              const SizedBox(height: 10),
              if (i < newRows.length - 1 || onPickNextTdp != null)
                const Divider(height: 1),
              const SizedBox(height: 10),
            ],

            // === Slot kosong berikutnya ===
            if (isAdmin && onPickNextTdp != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TDP ${totalTdpCount + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalTdpCount == 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Dapat pilih multiple File',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        DocFilePicker(
                          hasFile: false,
                          fileName: null,
                          isMultiple: true,
                          onPick: onPickNextTdp!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DocPreviewBox(previewContent: null, colorScheme: colorScheme),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(),

            // === Masa Berlaku ===
            Row(
              children: [
                const Text(
                  'Masa berlaku :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // const SizedBox(width: 6),
                // const RequiredBadge(),
                const SizedBox(width: 10),
                SizedBox(
                  width: 200,
                  height: 35,
                  child: TextField(
                    controller: masaBerlakuCtrl,
                    readOnly: true,
                    enabled: isAdmin,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: isAdmin
                          ? IconButton(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              onPressed: onPickDate,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Akan ada WARNING 5 pekan sebelum Expired',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),

            // === Status TDP ===
            Row(
              children: [
                const Text(
                  'Status TDP:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                StatusTdpChip(status: localStatus),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Satu baris item TDP (info + tombol aksi + preview).
class _TdpFileRow extends StatelessWidget {
  final TdpRowData data;
  final ColorScheme colorScheme;
  final bool isAdmin;

  const _TdpFileRow({
    required this.data,
    required this.colorScheme,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom kiri: info & tombol
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TDP ${data.index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.fileName,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (data.fileSize != null && data.fileSize! > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Ukuran: ${formatFileSize(data.fileSize)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (data.previewWidget != null ||
                  (isAdmin && (data.onReplace != null || data.onDelete != null)))
                Wrap(
                  spacing: 6,
                  runSpacing: 7,
                  children: [
                    if (isAdmin && data.onReplace != null)
                      SizedBox(
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: data.onReplace,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text(
                            'Ganti PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (data.previewWidget != null)
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => showPdfPreviewDialog(
                            context,
                            previewWidget: data.previewWidget!,
                            title: 'Preview PDF - TDP ${data.index + 1}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          icon: const Icon(Icons.visibility, size: 14),
                          label: const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isAdmin && data.onDelete != null)
                      SizedBox(
                        height: 34,
                        width: 100,
                        child: ElevatedButton(
                          onPressed: data.onDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Kolom kanan: preview PDF
        DocPreviewBox(
          previewContent: data.previewWidget,
          colorScheme: colorScheme,
          title: 'Preview PDF - TDP ${data.index + 1}',
        ),
      ],
    );
  }
}
