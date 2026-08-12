// File: lib/admin/master/widgets/add_gambar_kelistrikan_form.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:pdfrx/pdfrx.dart';

class AddGambarKelistrikanForm extends ConsumerStatefulWidget {
  final OptionItem? initialTypeEngine;
  final OptionItem? initialMerk;
  final OptionItem? initialTypeChassis;

  const AddGambarKelistrikanForm({
    super.key,
    this.initialTypeEngine,
    this.initialMerk,
    this.initialTypeChassis,
  });

  @override
  ConsumerState<AddGambarKelistrikanForm> createState() =>
      _AddGambarKelistrikanFormState();
}

class _AddGambarKelistrikanFormState
    extends ConsumerState<AddGambarKelistrikanForm> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedTypeEngineId;
  int? _selectedMerkId;
  int? _selectedTypeChassisId;

  // Untuk menyimpan Object OptionItem agar dropdown terisi namanya
  OptionItem? _initialEngineObj;
  OptionItem? _initialMerkObj;
  OptionItem? _initialChassisObj;

  PdfFileData? _selectedFile;
  Uint8List? _pdfPreviewBytes;
  final _pdfController = PdfViewerController();
  bool _isUploading = false;
  static const int _maxFileSize = 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Listener untuk mendeteksi perubahan mode Edit secara real-time
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final editingItem = ref.watch(editingKelistrikanFileProvider);

    if (editingItem != null) {
      _selectedTypeEngineId = editingItem.typeEngineId;
      _selectedMerkId = editingItem.merkId;
      _selectedTypeChassisId = editingItem.typeChassisId;

      _initialEngineObj = OptionItem(
        id: editingItem.typeEngineId,
        name: editingItem.engineName,
      );
      _initialMerkObj = OptionItem(
        id: editingItem.merkId,
        name: editingItem.merkName,
      );
      _initialChassisObj = OptionItem(
        id: editingItem.typeChassisId,
        name: editingItem.chassisName,
      );

      if (_loadedEditPdfId != editingItem.id && _selectedFile == null) {
        _loadEditPreview(id: editingItem.id, pathFile: editingItem.pathFile);
      }
    } else {
      _loadedEditPdfId = null;
      _selectedFile = null;
      _pdfPreviewBytes = null;
    }
  }

  void _initializeData() {
    // Logika Copy Paste (Add Baru)
    if (widget.initialTypeEngine != null) {
      _selectedTypeEngineId = widget.initialTypeEngine!.id as int;
      _initialEngineObj = widget.initialTypeEngine;
    }
    if (widget.initialMerk != null) {
      _selectedMerkId = widget.initialMerk!.id as int;
      _initialMerkObj = widget.initialMerk;
    }
    if (widget.initialTypeChassis != null) {
      _selectedTypeChassisId = widget.initialTypeChassis!.id as int;
      _initialChassisObj = widget.initialTypeChassis;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  int? _loadedEditPdfId;

  void _cancelEdit() {
    ref.read(editingKelistrikanFileProvider.notifier).state = null;
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _selectedTypeEngineId = null;
      _selectedMerkId = null;
      _selectedTypeChassisId = null;
      _initialEngineObj = null;
      _initialMerkObj = null;
      _initialChassisObj = null;
      _selectedFile = null;
      _loadedEditPdfId = null;
      _pdfPreviewBytes = null;
    });
  }

  Future<void> _loadEditPreview({
    required int id,
    required String pathFile,
  }) async {
    if (_selectedFile != null || _loadedEditPdfId == id) {
      return;
    }

    _loadedEditPdfId = id;

    setState(() {
      _pdfPreviewBytes = null;
    });

    try {
      final pdfBytes = await ref
          .read(masterDataRepositoryProvider)
          .getPdfFromPath(pathFile);

      if (!mounted || _loadedEditPdfId != id) {
        return;
      }

      final bytesCopy = Uint8List.fromList(pdfBytes);
      setState(() {
        _pdfPreviewBytes = bytesCopy;
      });
    } catch (e) {
      if (!mounted || _loadedEditPdfId != id) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat preview PDF: $e',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.red,
            ),
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap pilih file PDF')));
      return;
    }
    // --- VALIDASI SAAT SUBMIT (DOUBLE CHECK) ---
    if (_selectedFile!.size > _maxFileSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ukuran file melebihi 1 MB. Harap kompres file PDF Anda.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref
          .read(masterDataRepositoryProvider)
          .uploadKelistrikanFile(
            typeEngineId: _selectedTypeEngineId!,
            merkId: _selectedMerkId!,
            typeChassisId: _selectedTypeChassisId!,
            file: _selectedFile!,
          );

      // Setelah sukses, keluar dari mode edit
      _cancelEdit();

      ref
          .read(gambarKelistrikanFilterProvider.notifier)
          .update((state) => Map.from(state));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simpan Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data['message'] ?? e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $msg',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final editingItem = ref.watch(editingKelistrikanFileProvider);
    final bool isEditing = editingItem != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 500,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // INFO MODE EDIT
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Mode Edit: Anda tidak dapat mengubah Chassis.\nUpload file baru untuk mengganti file lama.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildSearchableDropdown(
                          label: 'Type Engine',
                          provider: mdTypeEngineOptionsProvider,
                          initialItem: _initialEngineObj,
                          enabled: !isEditing, // DISABLE SAAT EDIT
                          onChanged: (val) =>
                              _selectedTypeEngineId = val?.id as int?,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          label: 'Merk',
                          provider: mdMerkOptionsProvider,
                          initialItem: _initialMerkObj,
                          enabled: !isEditing, // DISABLE SAAT EDIT
                          onChanged: (val) => _selectedMerkId = val?.id as int?,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          label: 'Type Chassis',
                          provider: mdTypeChassisOptionsProvider,
                          initialItem: _initialChassisObj,
                          enabled: !isEditing, // DISABLE SAAT EDIT
                          onChanged: (val) =>
                              _selectedTypeChassisId = val?.id as int?,
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: Text(
                            _selectedFile == null
                                ? (isEditing ? 'Ganti PDF' : 'Pilih PDF')
                                : 'Ganti PDF',
                          ),
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: isEditing
                                ? colorScheme.secondaryContainer
                                : null,
                            foregroundColor: isEditing
                                ? colorScheme.onSecondaryContainer
                                : null,
                          ),
                        ),
                        if (_selectedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'File Baru: ${_selectedFile!.name}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else if (isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'File Saat Ini: ${editingItem.pathFile.split('/').last}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            if (isEditing) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelEdit,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Batal Edit'),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  isEditing
                                      ? 'Simpan Perubahan'
                                      : 'Upload File',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: _isUploading ? null : _submit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 4.0,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _pdfPreviewBytes != null
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
                              sourceName: _selectedFile?.name ?? 'kelistrikan.pdf',
                              key: ValueKey(_pdfPreviewBytes.hashCode),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 60,
                                ),
                                if (isEditing)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Text(
                                      'Memuat preview PDF saat ini...',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required FutureProviderFamily<List<OptionItem>, String> provider,
    required Function(OptionItem?) onChanged,
    OptionItem? initialItem,
    bool enabled = true, // Parameter Baru
  }) {
    return DropdownSearch<OptionItem>(
      items: (String filter, _) => ref.read(provider(filter).future),
      itemAsString: (OptionItem item) => item.name,
      compareFn: (i1, i2) => i1.id == i2.id,
      selectedItem: initialItem,
      enabled: enabled, // Kunci Dropdown
      onChanged: onChanged,
      decoratorProps: DropDownDecoratorProps(
        baseStyle: TextStyle(fontSize: 13, height: 1.0),
        decoration: InputDecoration(
          constraints: BoxConstraints(maxHeight: 42),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          labelStyle: TextStyle(fontSize: 12),
          labelText: label,
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          autofocus: true,
          style: TextStyle(fontSize: 13, height: 1.0),
          decoration: InputDecoration(
            constraints: BoxConstraints(maxHeight: 42),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            hintStyle: TextStyle(fontSize: 13, height: 1.0),
            hintText: "Cari...",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        itemBuilder: (context, item, isSelected, isDisabled) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            height:
                30, // Paksa tinggi item menjadi 30px (atau lebih kecil sesuai selera)
            alignment: Alignment.centerLeft,
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 12,
                height: 1.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
      validator: (item) =>
          item == null &&
              (label == 'Type Engine'
                      ? _selectedTypeEngineId
                      : label == 'Merk'
                      ? _selectedMerkId
                      : _selectedTypeChassisId) ==
                  null
          ? 'Wajib dipilih'
          : null,
    );
  }
}
