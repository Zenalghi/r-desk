// lib/admin/management/widgets/document/document_customer_form.dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/app_helpers.dart';
import '../../../../app/core/providers.dart';
import '../../../../data/models/document_customer.dart';
import '../../providers/customer_providers.dart';
import '../../repository/document_customer_repository.dart';
import 'components/action_buttons_bar.dart';
import 'components/card_data_umum.dart';
import 'components/card_format_penomoran.dart';
import 'components/card_kop_surat.dart';
import 'components/card_tdp.dart';
import 'components/pdf_preview_box.dart';

class DocumentCustomerForm extends ConsumerStatefulWidget {
  final int customerId;
  final DocumentCustomer? initialDocument;

  const DocumentCustomerForm({
    super.key,
    required this.customerId,
    this.initialDocument,
  });

  @override
  ConsumerState<DocumentCustomerForm> createState() =>
      _DocumentCustomerFormState();
}

class _DocumentCustomerFormState extends ConsumerState<DocumentCustomerForm> {
  // ──────────────────────────────────────────────────────────────────────────
  // STATE: File PDF
  // ──────────────────────────────────────────────────────────────────────────
  PlatformFile? _newKopSurat;
  PlatformFile? _newDataUmum;
  List<PlatformFile> _newTdpFiles = [];
  final Map<int, PlatformFile> _replacedTdpFiles = {};

  // ──────────────────────────────────────────────────────────────────────────
  // STATE: Text Controllers
  // ──────────────────────────────────────────────────────────────────────────
  late TextEditingController _masaBerlakuCtrl;
  late TextEditingController _skrbCtrl;
  late TextEditingController _rekomCtrl;
  late TextEditingController _alamatPermohonanCtrl;
  late TextEditingController _bidangUsahaCtrl;
  late TextEditingController _alamatLengkapCtrl;

  // ──────────────────────────────────────────────────────────────────────────
  // STATE: UI
  // ──────────────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _hasChanges = false;
  DocumentCustomer? _currentDoc;
  DateTime? _selectedMasaBerlaku;

  // ──────────────────────────────────────────────────────────────────────────
  // PDF bytes cache (hindari re-fetch berulang)
  // ──────────────────────────────────────────────────────────────────────────
  final Map<String, Uint8List> _pdfBytesCache = {};
  int _cacheVersion = 0;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.initialDocument;
    _selectedMasaBerlaku = _currentDoc?.tdpMasaBerlaku;
    _masaBerlakuCtrl = TextEditingController(
      text: _selectedMasaBerlaku != null
          ? _formatTanggalIndonesia(_selectedMasaBerlaku!)
          : '',
    );
    _skrbCtrl = TextEditingController(text: _currentDoc?.permohonanSkrb ?? '');
    _rekomCtrl = TextEditingController(
      text: _currentDoc?.permohonanRekom ?? '',
    );
    _alamatPermohonanCtrl = TextEditingController(
      text: _currentDoc?.alamatPermohonan ?? '',
    );
    _bidangUsahaCtrl = TextEditingController(
      text: _currentDoc?.bidangUsaha ?? '',
    );
    _alamatLengkapCtrl = TextEditingController(
      text: _currentDoc?.alamatLengkap ?? '',
    );

    for (final ctrl in [
      _masaBerlakuCtrl,
      _skrbCtrl,
      _rekomCtrl,
      _alamatPermohonanCtrl,
      _bidangUsahaCtrl,
      _alamatLengkapCtrl,
    ]) {
      ctrl.addListener(_markChanged);
    }
  }

  @override
  void dispose() {
    _masaBerlakuCtrl.dispose();
    _skrbCtrl.dispose();
    _rekomCtrl.dispose();
    _alamatPermohonanCtrl.dispose();
    _bidangUsahaCtrl.dispose();
    _alamatLengkapCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPUTED GETTERS
  // ══════════════════════════════════════════════════════════════════════════

  bool get _isAdmin => ref.read(userRoleProvider) == 'admin';

  int get _totalTdpCount =>
      (_currentDoc?.tdpFiles.length ?? 0) + _newTdpFiles.length;

  String? get _localStatusTdp {
    if (_selectedMasaBerlaku == null) return null;
    try {
      // Wajib menggunakan waktu WIB (UTC+7 / Asia/Jakarta) dan normalisasi ke startOfDay (00:00:00) agar identik dengan backend
      final nowUtc = DateTime.now().toUtc().add(const Duration(hours: 7));
      final nowWib = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

      final date = _selectedMasaBerlaku!;
      final expiryWib = DateTime(date.year, date.month, date.day);

      if (nowWib.isAfter(expiryWib)) {
        return 'Expired';
      }

      final warningThreshold = expiryWib.subtract(const Duration(days: 35));
      if (!nowWib.isBefore(warningThreshold)) {
        return 'WARNING';
      }

      return 'Aktif';
    } catch (_) {
      return null;
    }
  }

  bool get _isAllFilled {
    final isKopFilled =
        (_currentDoc?.kopSurat != null) || (_newKopSurat != null);
    final isDataUmumFilled =
        (_currentDoc?.dataUmum != null) || (_newDataUmum != null);
    final isFormatPenomoranFilled =
        _skrbCtrl.text.trim().isNotEmpty &&
        _rekomCtrl.text.trim().isNotEmpty &&
        _alamatPermohonanCtrl.text.trim().isNotEmpty &&
        _bidangUsahaCtrl.text.trim().isNotEmpty &&
        _alamatLengkapCtrl.text.trim().isNotEmpty;

    final isTdpFilled = _totalTdpCount > 0;
    final isMasaBerlakuFilled = _selectedMasaBerlaku != null;
    final isTdpValid = !isTdpFilled || (isTdpFilled && isMasaBerlakuFilled);

    return isKopFilled &&
        isDataUmumFilled &&
        isFormatPenomoranFilled &&
        isTdpValid;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  void _markChanged() => setState(() => _hasChanges = true);

  String _formatTanggalIndonesia(DateTime date) => formatTanggalIndonesia(date);

  // ──────────────────────────────────────────────────────────────────────────
  // PDF preview helpers
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPdfPreviewFromUrl(String url) {
    final token = ref.read(authTokenProvider) ?? '';
    return A4PdfPreviewer(
      cacheKey: '$url?v=$_cacheVersion',
      futureLoader: () => _fetchPdfBytes(url, token),
    );
  }

  Future<Uint8List> _fetchPdfBytes(String url, String token) async {
    if (_pdfBytesCache.containsKey(url)) return _pdfBytesCache[url]!;
    final response = await ref
        .read(apiClientProvider)
        .dio
        .get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
    final bytes = Uint8List.fromList(response.data);
    _pdfBytesCache[url] = bytes;
    return bytes;
  }

  Widget _buildPdfPreviewFromBytes(Uint8List bytes, [String? label]) {
    final cacheKey = 'bytes_${label ?? ''}_${bytes.length}_${bytes.hashCode}';
    return A4PdfPreviewer(cacheKey: cacheKey, bytes: bytes);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILE PICKERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<PlatformFile?> _pickSinglePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 500 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file melebihi batas 500 KB!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
      return file;
    }
    return null;
  }

  Future<List<PlatformFile>> _pickMultiplePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final valid = <PlatformFile>[];
      for (final file in result.files) {
        if (file.size > 500 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File "${file.name}" melebihi batas 500 KB, dilewati.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          continue;
        }
        valid.add(file);
      }
      return valid;
    }
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATE PICKER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pickDate() async {
    final initialDate =
        _selectedMasaBerlaku ?? _currentDoc?.tdpMasaBerlaku ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.input,
      locale: const Locale('id', 'ID'),
      fieldHintText: 'dd/MM/yyyy',
      fieldLabelText: 'Masa Berlaku (Tanggal/Bulan/Tahun)',
    );
    if (picked != null) {
      _selectedMasaBerlaku = picked;
      _masaBerlakuCtrl.text = _formatTanggalIndonesia(picked);
      _markChanged();
      setState(() {});
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TDP ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _deleteTdpFile(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus File TDP'),
        content: Text('Yakin hapus file TDP #${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final doc = await ref
            .read(documentCustomerRepositoryProvider)
            .deleteTdpFile(widget.customerId, index);
        ref.invalidate(documentCustomerProvider(widget.customerId));
        setState(() {
          _pdfBytesCache.clear();
          _cacheVersion++;
          _currentDoc = doc;
          _selectedMasaBerlaku = doc.tdpMasaBerlaku;
          _replacedTdpFiles.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus TDP: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _replaceTdpFile(int index) async {
    final file = await _pickSinglePdf();
    if (file != null) {
      setState(() => _replacedTdpFiles[index] = file);
      _markChanged();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (_isSaving) return;

    if (_totalTdpCount > 0 && _selectedMasaBerlaku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File TDP diisi, maka Masa Berlaku wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Kirim file TDP yang di-ganti (pending replace) terlebih dahulu
      for (final entry in _replacedTdpFiles.entries) {
        await ref
            .read(documentCustomerRepositoryProvider)
            .replaceTdpFile(widget.customerId, entry.key, entry.value);
      }

      // 2. Simpan seluruh data form
      final masaBerlaku = _selectedMasaBerlaku != null
          ? DateFormat('yyyy-MM-dd').format(_selectedMasaBerlaku!)
          : null;

      final doc = await ref
          .read(documentCustomerRepositoryProvider)
          .saveDocument(
            customerId: widget.customerId,
            kopSuratFile: _newKopSurat,
            dataUmumFile: _newDataUmum,
            newTdpFiles: _newTdpFiles.isNotEmpty ? _newTdpFiles : null,
            tdpMasaBerlaku: masaBerlaku,
            permohonanSkrb: _skrbCtrl.text,
            permohonanRekom: _rekomCtrl.text,
            alamatPermohonan: _alamatPermohonanCtrl.text,
            bidangUsaha: _bidangUsahaCtrl.text,
            alamatLengkap: _alamatLengkapCtrl.text,
          );

      ref.invalidate(documentCustomerProvider(widget.customerId));
      ref.read(customerInvalidator.notifier).state++;

      setState(() {
        _pdfBytesCache.clear();
        _cacheVersion++;
        _currentDoc = doc;
        _selectedMasaBerlaku = doc.tdpMasaBerlaku;
        _newKopSurat = null;
        _newDataUmum = null;
        _newTdpFiles = [];
        _replacedTdpFiles.clear();
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document berhasil disimpan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _isSaving = false);
      String errorMsg = e.message ?? e.toString();
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['message'] != null) errorMsg = data['message'].toString();
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final details = errors.values
              .map((v) => v is List ? v.join(', ') : v.toString())
              .join('\n');
          errorMsg = '$errorMsg\n$details';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DELETE DOCUMENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _deleteDocument() async {
    final customer = ref.read(selectedDocumentCustomerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Document'),
        content: Text(
          'Yakin hapus seluruh dokumen customer "${customer?.namaPt}"?\nSemua file PDF akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(documentCustomerRepositoryProvider)
            .deleteDocument(widget.customerId);

        ref.invalidate(documentCustomerProvider(widget.customerId));
        ref.read(customerInvalidator.notifier).state++;
        ref.read(selectedDocumentCustomerProvider.notifier).state = null;
        ref.read(configurationTabIndexProvider.notifier).state = 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CANCEL EDIT
  // ══════════════════════════════════════════════════════════════════════════

  void _cancelEdit() {
    ref.read(selectedDocumentCustomerProvider.notifier).state = null;
    ref.read(configurationTabIndexProvider.notifier).state = 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = _isAdmin;
    final repo = ref.read(documentCustomerRepositoryProvider);
    final existingTdp = _currentDoc?.tdpFiles ?? [];

    // ── Build TDP rows ──────────────────────────────────────────────────────
    final existingTdpRows = List.generate(existingTdp.length, (i) {
      final replaced = _replacedTdpFiles[i];
      return TdpRowData(
        index: i,
        fileName: replaced?.name ?? existingTdp[i].path.split('/').last,
        fileSize: replaced?.size ?? existingTdp[i].size,
        isExisting: true,
        onReplace: () => _replaceTdpFile(i),
        onDelete: i > 0 ? () => _deleteTdpFile(i) : null,
        previewWidget: (replaced?.bytes != null)
            ? _buildPdfPreviewFromBytes(replaced!.bytes!, 'tdp_replace_$i')
            : _buildPdfPreviewFromUrl(
                repo.getPdfViewUrl(widget.customerId, 'tdp', index: i),
              ),
      );
    });

    final newTdpRows = List.generate(_newTdpFiles.length, (i) {
      final globalIndex = existingTdp.length + i;
      return TdpRowData(
        index: globalIndex,
        fileName: _newTdpFiles[i].name,
        fileSize: _newTdpFiles[i].size,
        isExisting: false,
        onReplace: () async {
          final file = await _pickSinglePdf();
          if (file != null) {
            setState(() => _newTdpFiles[i] = file);
            _markChanged();
          }
        },
        onDelete: globalIndex > 0
            ? () {
                setState(() => _newTdpFiles.removeAt(i));
                _markChanged();
              }
            : null,
        previewWidget: _newTdpFiles[i].bytes != null
            ? _buildPdfPreviewFromBytes(_newTdpFiles[i].bytes!, 'tdp_new_$i')
            : null,
      );
    });

    // ── Build Kop Surat preview ─────────────────────────────────────────────
    final hasKopExisting = _currentDoc?.kopSurat != null;
    final hasKopNew = _newKopSurat != null;
    Widget? kopPreview;
    if (hasKopNew && _newKopSurat!.bytes != null) {
      kopPreview = _buildPdfPreviewFromBytes(_newKopSurat!.bytes!, 'kop_new');
    } else if (hasKopExisting) {
      kopPreview = _buildPdfPreviewFromUrl(
        repo.getPdfViewUrl(widget.customerId, 'kop'),
      );
    }

    // ── Build Data Umum preview ─────────────────────────────────────────────
    final hasDataExisting = _currentDoc?.dataUmum != null;
    final hasDataNew = _newDataUmum != null;
    Widget? dataPreview;
    if (hasDataNew && _newDataUmum!.bytes != null) {
      dataPreview = _buildPdfPreviewFromBytes(_newDataUmum!.bytes!, 'data_new');
    } else if (hasDataExisting) {
      dataPreview = _buildPdfPreviewFromUrl(
        repo.getPdfViewUrl(widget.customerId, 'data'),
      );
    }

    return Column(
      children: [
        // ── Scrollable form ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;

                final kopCard = CardKopSurat(
                  isAdmin: isAdmin,
                  colorScheme: colorScheme,
                  hasExisting: hasKopExisting,
                  hasNew: hasKopNew,
                  fileName: hasKopNew
                      ? _newKopSurat!.name
                      : (hasKopExisting
                            ? _currentDoc!.kopSurat!.split('/').last
                            : null),
                  fileSize: hasKopNew
                      ? _newKopSurat!.size
                      : (hasKopExisting ? _currentDoc!.kopSuratSize : null),
                  previewWidget: kopPreview,
                  onPick: () async {
                    final file = await _pickSinglePdf();
                    if (file != null) {
                      setState(() => _newKopSurat = file);
                      _markChanged();
                    }
                  },
                );

                final dataCard = CardDataUmum(
                  isAdmin: isAdmin,
                  colorScheme: colorScheme,
                  hasExisting: hasDataExisting,
                  hasNew: hasDataNew,
                  fileName: hasDataNew
                      ? _newDataUmum!.name
                      : (hasDataExisting
                            ? _currentDoc!.dataUmum!.split('/').last
                            : null),
                  fileSize: hasDataNew
                      ? _newDataUmum!.size
                      : (hasDataExisting ? _currentDoc!.dataUmumSize : null),
                  previewWidget: dataPreview,
                  onPick: () async {
                    final file = await _pickSinglePdf();
                    if (file != null) {
                      setState(() => _newDataUmum = file);
                      _markChanged();
                    }
                  },
                );

                final tdpCard = CardTdp(
                  isAdmin: isAdmin,
                  colorScheme: colorScheme,
                  totalTdpCount: _totalTdpCount,
                  localStatus: _localStatusTdp,
                  masaBerlakuCtrl: _masaBerlakuCtrl,
                  onPickDate: _pickDate,
                  existingRows: existingTdpRows,
                  newRows: newTdpRows,
                  onPickNextTdp: (isAdmin && _totalTdpCount < 5)
                      ? () async {
                          final files = await _pickMultiplePdf();
                          if (files.isNotEmpty) {
                            setState(() => _newTdpFiles.addAll(files));
                            _markChanged();
                          }
                        }
                      : null,
                );

                final formatCard = CardFormatPenomoran(
                  isAdmin: isAdmin,
                  colorScheme: colorScheme,
                  skrbCtrl: _skrbCtrl,
                  rekomCtrl: _rekomCtrl,
                  alamatPermohonanCtrl: _alamatPermohonanCtrl,
                  bidangUsahaCtrl: _bidangUsahaCtrl,
                  alamatLengkapCtrl: _alamatLengkapCtrl,
                );

                if (isWide) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: kopCard),
                          const SizedBox(width: 8),
                          Expanded(child: dataCard),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: tdpCard),
                          const SizedBox(width: 8),
                          Expanded(child: formatCard),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      kopCard,
                      const SizedBox(height: 8),
                      dataCard,
                      const SizedBox(height: 8),
                      tdpCard,
                      const SizedBox(height: 8),
                      formatCard,
                    ],
                  );
                }
              },
            ),
          ),
        ),

        // ── Tombol aksi ─────────────────────────────────────────────────────
        ActionButtonsBar(
          isAdmin: isAdmin,
          hasExistingDoc: _currentDoc != null,
          hasChanges: _hasChanges,
          isAllFilled: _isAllFilled,
          isSaving: _isSaving,
          colorScheme: colorScheme,
          onCancelEdit: _cancelEdit,
          onDelete: _deleteDocument,
          onSave: _save,
        ),
      ],
    );
  }
}
