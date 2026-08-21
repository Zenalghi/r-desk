// File: lib/admin/master/widgets/c-chassis/type_chassis_form_card.dart

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/master_data_providers.dart';
import '../../repository/master_data_repository.dart';
import '../../../management/widgets/document/components/pdf_preview_box.dart';

class TypeChassisFormCard extends ConsumerStatefulWidget {
  const TypeChassisFormCard({super.key});

  @override
  ConsumerState<TypeChassisFormCard> createState() =>
      _TypeChassisFormCardState();
}

class _TypeChassisFormCardState extends ConsumerState<TypeChassisFormCard> {
  final _chassisController = TextEditingController();
  final _nomorSutController = TextEditingController();
  final _merekDagangController = TextEditingController();
  final _jenisTipeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlatformFile? _sutPdfFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _chassisController.dispose();
    _nomorSutController.dispose();
    _merekDagangController.dispose();
    _jenisTipeController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 500 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file PDF tidak boleh melebihi 500 KB!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _sutPdfFile = file;
      });
    }
  }

  void _showPreviewDialog() {
    if (_sutPdfFile == null || _sutPdfFile!.bytes == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 900, maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Preview SUT: ${_sutPdfFile!.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        // border: Border.all(color: Colors.grey.shade400),
                        child: A4PdfPreviewer(
                          bytes: _sutPdfFile!.bytes!,
                          cacheKey:
                              _sutPdfFile!.name + _sutPdfFile!.size.toString(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Hapus PDF',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          setState(() {
                            _sutPdfFile = null;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Ganti PDF'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _pickPdf();
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(masterDataRepositoryProvider)
          .addTypeChassis(
            typeChassis: _chassisController.text,
            nomorSut: _nomorSutController.text,
            merekDagang: _merekDagangController.text,
            jenisTipe: _jenisTipeController.text,
            sutPdfFile: _sutPdfFile,
          );
      _chassisController.clear();
      _nomorSutController.clear();
      _merekDagangController.clear();
      _jenisTipeController.clear();
      setState(() {
        _sutPdfFile = null;
      });
      // Refresh tabel via provider filter
      ref
          .read(typeChassisFilterProvider.notifier)
          .update((state) => Map.from(state));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Type Chassis berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.response?.data['message'] ?? e.message}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _chassisController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Nama Type Chassis Baru',
                    hintText: 'Contoh: FM 260 JD',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama type chassis tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _nomorSutController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Nomor SUT (Opsional)',
                    hintText: 'Contoh: 1234/SUT/2026',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _merekDagangController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Merek Dagang (Opsional)',
                    hintText: 'Contoh: HINO / MITSUBISHI',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  style: const TextStyle(fontSize: 14),
                  controller: _jenisTipeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: 'Jenis Tipe (Opsional)',
                    hintText: 'Contoh: Mobil Angkutan Barang',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (_sutPdfFile == null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.indigo),
                  label: const Text('Input SUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo.shade900,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  onPressed: _isLoading ? null : _pickPdf,
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.blueAccent,
                      ),
                      label: const Text('Preview PDF SUT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        shadowColor: Colors.amber.shade100,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      onPressed: _isLoading ? null : _showPreviewDialog,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Hapus PDF',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _sutPdfFile = null;
                              });
                            },
                    ),
                  ],
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
