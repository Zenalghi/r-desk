// File: lib/elements/home/widgets/skrb/buat_skrb_dialog.dart
// Dialog konfirmasi sebelum membuat Permohonan SKRB.
// Menampilkan preview ID SKRB sistem dan memungkinkan user memasukkan nomor urut manual.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/skrb.dart';
import '../../repository/skrb_repository.dart';

/// Hasil dari dialog ini.
class BuatSkrbDialogResult {
  final bool useManual;
  final int? nomorUrutManual;
  const BuatSkrbDialogResult({required this.useManual, this.nomorUrutManual});
}

/// Dialog untuk mengkonfirmasi ID SKRB sebelum membuat permohonan.
/// Ditampilkan saat tombol "BUAT PERMOHONAN SKRB" ditekan.
///
/// Return: [BuatSkrbDialogResult] atau null jika dibatalkan.
class BuatSkrbDialog extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;
  // Preview info untuk Cara 1 (transaksi) atau Cara 2 (standalone)
  final SkrbAvailableTransaction? selectedTransaction; // Cara 1
  final String? caraDua_merk; // Cara 2
  final String? caraDua_jenisPengajuan; // Cara 2

  const BuatSkrbDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    this.selectedTransaction,
    this.caraDua_merk,
    this.caraDua_jenisPengajuan,
  });

  @override
  ConsumerState<BuatSkrbDialog> createState() => _BuatSkrbDialogState();
}

class _BuatSkrbDialogState extends ConsumerState<BuatSkrbDialog> {
  final TextEditingController _nomorController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _previewIdSkrb;
  bool _loadingPreview = true;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _loadPreviewId();
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreviewId() async {
    try {
      final repo = ref.read(skrbRepositoryProvider);
      final result = await repo.getPreviewIdSkrb(widget.customerId);
      if (mounted) {
        setState(() {
          _previewIdSkrb = result['preview_id_skrb'] as String?;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is DioException) {
          errMsg =
              e.response?.data?['message']?.toString() ?? e.message ?? errMsg;
        }
        final msg = errMsg.toLowerCase();
        if (msg.contains('data customer belum ditambahkan') ||
            msg.contains('hubungi admin')) {
          errMsg = 'Data Customer belum ditambahkan\nhubungi admin';
        }
        setState(() {
          _previewError = errMsg;
          _loadingPreview = false;
        });
      }
    }
  }

  /// Validasi nomor urut: hanya digit, min 1, pad jika 1 digit
  int? _parseNomor() {
    final raw = _nomorController.text.trim();
    if (raw.isEmpty) return null;
    final val = int.tryParse(raw);
    if (val == null || val < 1) return null;
    return val;
  }

  void _handleSubmit({required bool useManual}) {
    int? nomor;
    if (useManual) {
      nomor = _parseNomor();
      if (nomor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan nomor urut yang valid (angka, min 1)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    Navigator.of(
      context,
    ).pop(BuatSkrbDialogResult(useManual: useManual, nomorUrutManual: nomor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final hasManual = _nomorController.text.trim().isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Icon(Icons.assignment_add, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Konfirmasi Pembuatan SKRB',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 1200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info customer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.selectedTransaction != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ID DWG: ${widget.selectedTransaction!.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.caraDua_merk != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 15,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.caraDua_merk} • ${widget.caraDua_jenisPengajuan ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tanpa ID DWG',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Preview ID SKRB sistem
            Text(
              'ID SKRB Sistem (otomatis):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (_loadingPreview)
              const SizedBox(
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_previewError != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _previewError!.contains(
                              'Data Customer belum ditambahkan',
                            )
                            ? _previewError!
                            : 'Gagal memuat preview: $_previewError',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _previewIdSkrb ?? '-',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            // Field nomor urut manual
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Atau masukkan nomor urut manual:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setInnerState) {
                return TextField(
                  controller: _nomorController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Contoh: 03  (akan jadi 03/...)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.numbers, size: 18),
                    helperText:
                        '*Hanya angka. Satu digit akan dipadding 0 di depannya (1→01).',
                    helperMaxLines: 2,
                    helperStyle: const TextStyle(fontSize: 15),
                  ),
                  onChanged: (_) => setInnerState(() {}),
                );
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 4),
        StatefulBuilder(
          builder: (context, setInnerState) {
            _nomorController.addListener(() => setInnerState(() {}));
            final hasManualNow = _nomorController.text.trim().isNotEmpty;
            final isBlocked =
                _previewError != null &&
                _previewError!.contains('Data Customer belum ditambahkan');

            return hasManualNow
                ? FilledButton.tonal(
                    onPressed: isBlocked
                        ? null
                        : () => _handleSubmit(useManual: true),
                    child: const Text('Gunakan ID Manual'),
                  )
                : FilledButton(
                    onPressed: _loadingPreview || isBlocked
                        ? null
                        : () => _handleSubmit(useManual: false),
                    child: const Text('Gunakan ID Sistem'),
                  );
          },
        ),
      ],
    );
  }
}
