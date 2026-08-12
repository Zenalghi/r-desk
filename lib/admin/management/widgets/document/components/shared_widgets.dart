// lib/admin/management/widgets/document/components/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:master_gambar/app/core/app_helpers.dart';

/// Badge merah kecil bertuliskan "Wajib".
class RequiredBadge extends StatelessWidget {
  const RequiredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Wajib',
        style: TextStyle(
          fontSize: 9,
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Row untuk memilih / mengganti file PDF tunggal.
class DocFilePicker extends StatelessWidget {
  final bool hasFile;
  final String? fileName;
  final int? fileSize;
  final bool isMultiple;
  final VoidCallback onPick;
  final VoidCallback? onPreview;

  const DocFilePicker({
    super.key,
    required this.hasFile,
    required this.fileName,
    this.fileSize,
    required this.onPick,
    this.onPreview,
    this.isMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    final showSize = hasFile && fileSize != null && fileSize! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: onPick,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                icon: const Icon(Icons.upload_file, size: 14),
                label: Text(
                  hasFile ? 'Ganti PDF' : 'Pilih File PDF',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (hasFile && onPreview != null)
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: onPreview,
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
          ],
        ),
        const SizedBox(height: 6),
        Text(
          fileName ?? 'Tidak ada file yang dipilih',
          style: TextStyle(
            fontSize: 12,
            color: hasFile ? null : Colors.grey,
            fontStyle: hasFile ? FontStyle.normal : FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          showSize
              ? 'Ukuran: ${formatFileSize(fileSize)}'
              : 'Max. 500KB',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: showSize ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Row berlabel untuk input teks (format penomoran, dll.).
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isAdmin;
  final int maxLines;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.isAdmin,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Text(
            ':',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: isAdmin,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip warna yang menampilkan status TDP (Aktif / WARNING / Expired).
class StatusTdpChip extends StatelessWidget {
  final String? status;

  const StatusTdpChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('     -     ', style: TextStyle(fontSize: 16)),
      );
    }

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Aktif':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'WARNING':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber;
        break;
      case 'Expired':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status!,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
