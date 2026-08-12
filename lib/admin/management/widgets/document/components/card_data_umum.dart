// lib/admin/management/widgets/document/components/card_data_umum.dart
import 'package:flutter/material.dart';

import 'pdf_preview_box.dart';
import 'shared_widgets.dart';

/// Card 2 – Data Umum Perusahaan.
class CardDataUmum extends StatelessWidget {
  final bool isAdmin;
  final ColorScheme colorScheme;
  final bool hasExisting;
  final bool hasNew;
  final String? fileName;
  final int? fileSize;
  final Widget? previewWidget;
  final VoidCallback onPick;

  const CardDataUmum({
    super.key,
    required this.isAdmin,
    required this.colorScheme,
    required this.hasExisting,
    required this.hasNew,
    required this.fileName,
    this.fileSize,
    required this.previewWidget,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Label & file picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Data Umum Perusahaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // const RequiredBadge(),
                    ],
                  ),
                  if (!hasExisting && !hasNew) ...[
                    const SizedBox(height: 8),
                    Text(
                      'File (Harus diisi)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (isAdmin)
                    DocFilePicker(
                      hasFile: hasExisting || hasNew,
                      fileName: fileName,
                      fileSize: fileSize,
                      onPick: onPick,
                      onPreview: (hasExisting || hasNew) && previewWidget != null
                          ? () => showPdfPreviewDialog(
                                context,
                                previewWidget: previewWidget!,
                                title: 'Preview PDF - Data Umum Perusahaan',
                              )
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Column 2: Preview A4
            DocPreviewBox(
              previewContent: previewWidget,
              colorScheme: colorScheme,
              title: 'Preview PDF - Data Umum Perusahaan',
            ),
          ],
        ),
      ),
    );
  }
}
