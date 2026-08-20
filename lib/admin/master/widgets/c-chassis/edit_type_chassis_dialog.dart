// File: lib/admin/master/widgets/c-chassis/edit_type_chassis_dialog.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/app/core/providers.dart';
import '../../models/type_chassis.dart';
// import '../../providers/master_data_providers.dart';
import '../../repository/master_data_repository.dart';
import '../../../management/widgets/document/components/pdf_preview_box.dart';

class EditTypeChassisDialog extends ConsumerStatefulWidget {
  final TypeChassis item;
  final VoidCallback onUpdated;

  const EditTypeChassisDialog({
    super.key,
    required this.item,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditTypeChassisDialog> createState() =>
      _EditTypeChassisDialogState();
}

class _EditTypeChassisDialogState extends ConsumerState<EditTypeChassisDialog> {
  late TextEditingController _controller;
  late TextEditingController _nomorSutController;
  late TextEditingController _merekDagangController;
  late TextEditingController _jenisTipeController;
  PlatformFile? _newPdfFile;
  bool _removePdf = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.name);
    _nomorSutController = TextEditingController(
      text: widget.item.nomorSut ?? '',
    );
    _merekDagangController = TextEditingController(
      text: widget.item.merekDagang ?? '',
    );
    _jenisTipeController = TextEditingController(
      text: widget.item.jenisTipe ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      // Batasi ukuran maksimal 500 KB
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
        _newPdfFile = file;
        _removePdf = false;
      });
    }
  }

  void _previewCurrentServerPdf() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        'Preview PDF SUT: ${widget.item.name}',
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
                        cacheKey:
                            'sut_edit_${widget.item.id}_${widget.item.updatedAt.millisecondsSinceEpoch}',
                        futureLoader: () async {
                          final response = await ref
                              .read(apiClientProvider)
                              .dio
                              .get(
                                '/type-chassis/${widget.item.id}/sut-pdf',
                                options: Options(
                                  responseType: ResponseType.bytes,
                                ),
                              );
                          return Uint8List.fromList(response.data);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
      ),
    );
  }

  void _previewNewPdf() {
    if (_newPdfFile == null || _newPdfFile!.bytes == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        'Preview PDF SUT Baru: ${_newPdfFile!.name}',
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
                        bytes: _newPdfFile!.bytes!,
                        cacheKey:
                            _newPdfFile!.name + _newPdfFile!.size.toString(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasServerPdf =
        widget.item.sutPdfPath != null &&
        widget.item.sutPdfPath!.isNotEmpty &&
        !_removePdf;
    final hasNewPdf = _newPdfFile != null;

    return AlertDialog(
      title: Text('Edit Type Chassis: ${widget.item.id}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nama Type Chassis',
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nomorSutController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nomor SUT (Opsional)',
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _merekDagangController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merek Dagang (Opsional)',
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _jenisTipeController,
                // textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Jenis Tipe (Opsional)',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'File PDF SUT (Maksimal 500 KB):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 15),
              if (!hasServerPdf && !hasNewPdf)
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.upload_file,
                    color: Colors.indigo,
                    size: 18,
                  ),
                  label: const Text('Input PDF SUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo.shade900,
                  ),
                  onPressed: _isLoading ? null : _pickPdf,
                )
              else if (hasNewPdf)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                      label: const Text('Preview PDF (Baru)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade50,
                        foregroundColor: Colors.teal.shade900,
                      ),
                      onPressed: _isLoading ? null : _previewNewPdf,
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Batal Ganti',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _newPdfFile = null;
                              });
                            },
                    ),
                  ],
                )
              else if (hasServerPdf)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                      label: const Text('Preview PDF SUT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade50,
                        foregroundColor: Colors.teal.shade900,
                      ),
                      onPressed: _isLoading ? null : _previewCurrentServerPdf,
                    ),
                    const SizedBox(width: 15),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Ganti'),
                      onPressed: _isLoading ? null : _pickPdf,
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Hapus PDF',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _removePdf = true;
                                _newPdfFile = null;
                              });
                            },
                    ),
                  ],
                ),
              if (_removePdf && _newPdfFile == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'PDF SUT akan dihapus saat disimpan.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _removePdf = false),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref
                        .read(masterDataRepositoryProvider)
                        .updateTypeChassis(
                          id: widget.item.id,
                          typeChassis: _controller.text,
                          nomorSut: _nomorSutController.text,
                          merekDagang: _merekDagangController.text,
                          jenisTipe: _jenisTipeController.text,
                          sutPdfFile: _newPdfFile,
                          removeSutPdf: _removePdf,
                        );
                    widget.onUpdated();
                    if (context.mounted) Navigator.of(context).pop();
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${e.response?.data['message'] ?? e.message}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
