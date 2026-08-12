// File: lib/admin/master/screens/master_gambar_optional_screen.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../data/models/option_item.dart';
import '../models/gambar_optional.dart';
import '../widgets/i-c-optional/pilih_master_data_card.dart';
import '../widgets/i-c-optional/gambar_optional_table.dart';

class MasterGambarOptionalScreen extends ConsumerStatefulWidget {
  const MasterGambarOptionalScreen({super.key});

  @override
  ConsumerState<MasterGambarOptionalScreen> createState() =>
      _MasterGambarOptionalScreenState();
}

class _MasterGambarOptionalScreenState
    extends ConsumerState<MasterGambarOptionalScreen> {
  bool _isLoading = false;
  final _deskripsiController = TextEditingController();
  final _searchController = TextEditingController();
  PdfFileData? _selectedFile;
  Uint8List? _pdfPreviewBytes;
  final _pdfController = PdfViewerController();

  final ExpansionTileController _expansionController =
      ExpansionTileController();
  static const int _maxFileSize = 1024 * 1024;
  @override
  void dispose() {
    _deskripsiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupEditListener() {
    ref.listen<GambarOptional?>(editingGambarOptionalProvider, (
      previous,
      next,
    ) {
      if (next != null) {
        _enterEditMode(next);
      } else {
        _exitEditMode();
      }
    });
  }

  Future<void> _enterEditMode(GambarOptional item) async {
    // 1. Reset state preview lama
    setState(() {
      _isLoading = true;
      _pdfPreviewBytes = null;
      _selectedFile = null;
    });

    // 2. Isi Form Deskripsi
    _deskripsiController.text = item.deskripsi;

    // --- PERBAIKAN DI SINI ---

    // CARA LAMA (SALAH): Mengambil via Varian Body (sekarang null)
    // final vb = item.varianBody;
    // final md = vb?.masterData;

    // CARA BARU (BENAR): Mengambil langsung dari properti masterData
    final md = item.masterData;

    if (md != null) {
      // Buat nama gabungan untuk tampilan dropdown
      final masterDataName =
          '${md.typeEngine.name} / ${md.merk.name} / ${md.typeChassis.displayName} / ${md.jenisKendaraan.name}';

      // Update provider agar PilihMasterDataCard bereaksi
      ref.read(initialGambarUtamaDataProvider.notifier).state = {
        'masterData': OptionItem(id: md.id, name: masterDataName),
        // 'varianBody' tidak diperlukan lagi untuk card ini
      };

      // PENTING: Update juga ID provider yang dipakai saat submit
      ref.read(mguSelectedMasterDataIdProvider.notifier).state = md.id;
    }
    // -------------------------

    try {
      // 4. Download PDF
      final pdfBytes = await ref
          .read(masterDataRepositoryProvider)
          .getGambarOptionalPdf(item.id);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/edit_opt_${item.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await tempFile.writeAsBytes(pdfBytes);

      if (!mounted) return;

      setState(() {
        final bytesCopy = Uint8List.fromList(pdfBytes);
        _pdfPreviewBytes = bytesCopy;
      });

      if (!_expansionController.isExpanded) {
        _expansionController.expand();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat preview: $e',
              style: _snackBarTextStyle(Colors.red),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextStyle _snackBarTextStyle(Color color) {
    if (color == Colors.red) {
      return const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15,
        fontFamily: 'Poppins',
      );
    }
    return const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      fontFamily: 'Poppins',
    );
  }

  void _exitEditMode() {
    _resetForm();
    // if (_expansionController.isExpanded) {
    //   _expansionController.collapse();
    // }
  }

  void _resetForm() {
    ref.read(mguSelectedMasterDataIdProvider.notifier).state = null;
    ref.read(mguSelectedVarianBodyNameProvider.notifier).state = null;
    ref.read(initialGambarUtamaDataProvider.notifier).state =
        null; // Reset dropdown visual

    _deskripsiController.clear();
    setState(() {
      _selectedFile = null;
      _pdfPreviewBytes = null;
    });
  }

  void _triggerGambarOptionalRefresh({bool resetSearch = false}) {
    final current = ref.read(gambarOptionalFilterProvider);

    ref.read(gambarOptionalFilterProvider.notifier).state = {
      ...current,
      'search': resetSearch ? '' : (current['search'] ?? ''),
      'sortBy': current['sortBy'] ?? 'updated_at',
      'sortDirection': current['sortDirection'] ?? 'desc',
      'refreshToken': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }

  void _resetAndRefresh() {
    ref.read(editingGambarOptionalProvider.notifier).state = null;
    _searchController.clear();
    _resetForm();
    _triggerGambarOptionalRefresh(resetSearch: true);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;

      if (file.size > _maxFileSize) {
        if (mounted) {
          _showSnackBar(
            'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
            Colors.red,
          );
        }
        return;
      }

      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = File(file.path!).readAsBytesSync();
      }

      if (fileBytes != null) {
        setState(() {
          _selectedFile = PdfFileData(
            name: file.name,
            bytes: fileBytes!,
            size: file.size,
          );

          final bytesCopy = Uint8List.fromList(fileBytes);
          _pdfPreviewBytes = bytesCopy;
        });
      }
    }
  }

  Future<void> _submit() async {
    final editingItem = ref.read(editingGambarOptionalProvider);
    final isEditMode = editingItem != null;

    // --- VALIDASI MODE TAMBAH (Create) ---
    if (!isEditMode) {
      if (_selectedFile == null) {
        _showSnackBar('Harap pilih file PDF.', Colors.orange);
        return;
      }
      if (_deskripsiController.text.isEmpty) {
        _showSnackBar('Harap isi deskripsi.', Colors.orange);
        return;
      }
    }

    // --- VALIDASI MODE EDIT (Update) ---
    if (isEditMode) {
      final isDeskripsiChanged =
          _deskripsiController.text != editingItem.deskripsi;
      final isFileChanged = _selectedFile != null;

      if (!isDeskripsiChanged && !isFileChanged) {
        _showSnackBar('Tidak ada perubahan data.', Colors.blue);
        return;
      }

      if (_deskripsiController.text.isEmpty) {
        _showSnackBar('Deskripsi tidak boleh dikosongkan.', Colors.red);
        return;
      }
    }

    // --- 2. VALIDASI UKURAN FILE (DOUBLE CHECK SAAT SUBMIT) ---
    if (_selectedFile != null) {
      if (_selectedFile!.size > _maxFileSize) {
        _showSnackBar(
          'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
          Colors.red,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        // --- LOGIKA UPDATE ---
        await ref
            .read(masterDataRepositoryProvider)
            .updateGambarOptional(
              id: editingItem.id,
              deskripsi: _deskripsiController.text,
              file: _selectedFile,
            );

        _showSnackBar('Update Berhasil!', Colors.orange);
        ref.read(editingGambarOptionalProvider.notifier).state = null;
      } else {
        // --- LOGIKA CREATE ---
        final selectedMasterDataId = ref.read(mguSelectedMasterDataIdProvider);

        if (selectedMasterDataId == null) {
          _showSnackBar(
            'Master Data ID tidak ditemukan. Pilih kendaraan ulang.',
            Colors.red,
          );
          return;
        }

        await ref
            .read(masterDataRepositoryProvider)
            .addGambarOptional(
              masterDataId: selectedMasterDataId,
              deskripsi: _deskripsiController.text,
              gambarOptionalFile: _selectedFile!,
              tipe: 'independen',
            );

        _showSnackBar('Upload Berhasil!', Colors.green);
        _resetForm();
      }

      // Refresh Tabel
      _triggerGambarOptionalRefresh();
    } on DioException catch (e) {
      _showSnackBar(
        'Error: ${e.response?.data['message'] ?? e.message}',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _snackBarTextStyle(color)),
        backgroundColor: color,
      ),
    );
  }

  void _handleCopyAction() {
    // 1. Reset Form Input (Deskripsi & File) tapi JANGAN reset Dropdown
    _deskripsiController.clear();
    setState(() {
      _selectedFile = null;
      _pdfPreviewBytes = null;
    });

    // 2. Pastikan Mode Edit Mati (Jadi Mode Tambah Baru)
    ref.read(editingGambarOptionalProvider.notifier).state = null;

    // 3. Buka ExpansionTile jika tertutup
    if (!_expansionController.isExpanded) {
      _expansionController.expand();
    }

    // 4. Scroll ke atas (Opsional, agar user sadar form terbuka)
    // (Jika Anda punya ScrollController di SingleChildScrollView utama)

    // 5. Tampilkan SnackBar Instruksi
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hapus snackbar lama
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data Kendaraan disalin! Silakan isi Deskripsi dan Upload File baru.',
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 4),
        // showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    _setupEditListener();
    ref.listen(copyGambarOptionalTriggerProvider, (previous, next) {
      if (next > 0) {
        _handleCopyAction();
      }
    });
    final editingItem = ref.watch(editingGambarOptionalProvider);
    final isEditMode = editingItem != null;

    String formTitle = 'Tambah Gambar Optional Baru';
    Color headerColor = Colors.blue;
    if (isEditMode) {
      formTitle = 'Edit Gambar Optional ${editingItem.tipe.toUpperCase()}';
      headerColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              const Text(
                'Manajemen Gambar Optional',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 250,
                height: 31,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => ref
                      .read(gambarOptionalFilterProvider.notifier)
                      .update((state) => {...state, 'search': value}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh / Batal Edit',
                onPressed: _resetAndRefresh,
              ),
            ],
          ),
          const SizedBox(height: 1),

          ExpansionTile(
            controller: _expansionController,
            initiallyExpanded: isEditMode,
            title: Text(
              formTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: headerColor,
              ),
            ),
            children: [
              SizedBox(
                height: 400,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Pilih Kendaraan (Kirim Flag Edit Mode)
                            PilihMasterDataCard(isEditMode: isEditMode),
                            // 2. Input Details
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      "2. Detail Gambar",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    if (isEditMode)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        child: Text(
                                          "Mode Edit: Anda mengedit data ID #${editingItem.id}. Upload file baru jika ingin mengganti file lama.",
                                          style: TextStyle(
                                            color: colorScheme
                                                .onSecondaryContainer,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    TextFormField(
                                      controller: _deskripsiController,
                                      decoration: const InputDecoration(
                                        labelText: 'Deskripsi',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.description),
                                      ),
                                      textCapitalization:
                                          TextCapitalization.characters,
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: Text(
                                        _selectedFile == null
                                            ? (isEditMode
                                                  ? 'Ganti File (Opsional)'
                                                  : 'Pilih File PDF')
                                            : 'Ganti File Terpilih',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                      ),
                                      onPressed: _pickFile,
                                    ),
                                    if (_selectedFile != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'File Baru: ${_selectedFile!.name}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    const Divider(height: 30),
                                    Row(
                                      children: [
                                        if (isEditMode)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.cancel),
                                              label: const Text('Batal'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                              onPressed: _resetAndRefresh,
                                            ),
                                          ),
                                        if (isEditMode)
                                          const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: Icon(
                                              isEditMode
                                                  ? Icons.save
                                                  : Icons.upload,
                                            ),
                                            label: Text(
                                              isEditMode
                                                  ? 'Simpan Perubahan'
                                                  : 'Upload Baru',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isEditMode
                                                  ? Colors.orange
                                                  : Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : _submit,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _pdfPreviewBytes != null
                              ? GestureDetector(
                                  onDoubleTapDown: (details) {
                                    if (_pdfController.isReady) {
                                      final current = _pdfController.currentZoom;
                                      final fit = _pdfController.alternativeFitScale ?? _pdfController.minScale;
                                      final cover = _pdfController.coverScale;
                                      if ((current - fit).abs() < 0.05) {
                                        _pdfController.setZoom(details.localPosition, cover);
                                      } else {
                                        _pdfController.setZoom(details.localPosition, fit);
                                      }
                                    }
                                  },
                                  onDoubleTap: () {},
                                  child: PdfViewer.data(
                                    _pdfPreviewBytes!,
                                    sourceName: _selectedFile?.name ?? 'optional.pdf',
                                    key: ValueKey(
                                      _selectedFile?.name ?? _pdfPreviewBytes.hashCode.toString(),
                                    ),
                                    controller: _pdfController,
                                    params: PdfViewerParams(
                                      textSelectionParams: const PdfTextSelectionParams(enabled: false),
                                      sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                                        calculateInitialZoom: (doc, controller, altFitScale, coverScale) => altFitScale,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.picture_as_pdf_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 60,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Expanded(child: GambarOptionalTable()),
        ],
      ),
    );
  }
}
