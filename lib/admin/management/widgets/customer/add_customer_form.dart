import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customer_providers.dart';
import '../../repository/customer_repository.dart';

class AddCustomerForm extends ConsumerStatefulWidget {
  const AddCustomerForm({super.key});
  @override
  ConsumerState<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends ConsumerState<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaPtController = TextEditingController();
  final _pjController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _drafterController = TextEditingController();
  final _pemeriksaController = TextEditingController();

  // 1. Ubah definisi state File menjadi Uint8List dan String (untuk nama)
  Uint8List? _signatureBytespj;
  String? _signatureNamepj;

  Uint8List? _signatureBytesdrafter;
  String? _signatureNamedrafter;

  Uint8List? _signatureBytespemeriksa;
  String? _signatureNamepemeriksa;
  bool _isLoading = false;
  bool _isDragging = false; // State untuk feedback visual

  @override
  void dispose() {
    _namaPtController.dispose();
    _pjController.dispose();
    _namaLengkapController.dispose();
    _jabatanController.dispose();
    _drafterController.dispose();
    _pemeriksaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // WAJIB TRUE AGAR JALAN DI WEB
    );

    if (result != null) {
      final file = result.files.single;

      // Ambil bytes. Gunakan fallback path jika bytes kosong (biasanya aman untuk Desktop)
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = File(file.path!).readAsBytesSync();
      }

      if (fileBytes != null) {
        setState(() {
          if (type == 'pj') {
            _signatureBytespj = fileBytes;
            _signatureNamepj = file.name;
          }
          if (type == 'drafter') {
            _signatureBytesdrafter = fileBytes;
            _signatureNamedrafter = file.name;
          }
          if (type == 'pemeriksa') {
            _signatureBytespemeriksa = fileBytes;
            _signatureNamepemeriksa = file.name;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(customerRepositoryProvider);
        final newCustomer = await repo.addCustomer(
          namaPt: _namaPtController.text,
          pj: _pjController.text,
          namaLengkap: _namaLengkapController.text.isNotEmpty
              ? _namaLengkapController.text
              : null,
          jabatan: _jabatanController.text.isNotEmpty
              ? _jabatanController.text
              : null,
          namaDrafter: _drafterController.text.isNotEmpty
              ? _drafterController.text
              : null,
          namaPemeriksa: _pemeriksaController.text.isNotEmpty
              ? _pemeriksaController.text
              : null,
        );

        if (_signatureBytespj != null) {
          await repo.uploadSignature(
            customerId: newCustomer.id,
            bytes: _signatureBytespj!,
            fileName: _signatureNamepj ?? 'paraf_pj.png',
          );
        }
        if (_signatureBytesdrafter != null) {
          await repo.uploadSignatureDrafter(
            customerId: newCustomer.id,
            bytes: _signatureBytesdrafter!,
            fileName: _signatureNamedrafter ?? 'paraf_drafter.png',
          );
        }
        if (_signatureBytespemeriksa != null) {
          await repo.uploadSignaturePemeriksa(
            customerId: newCustomer.id,
            bytes: _signatureBytespemeriksa!,
            fileName: _signatureNamepemeriksa ?? 'paraf_pemeriksa.png',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _namaPtController.clear();
        _pjController.clear();
        _jabatanController.clear();
        _drafterController.clear();
        _pemeriksaController.clear();
        setState(() => _signatureBytespj = null);
        setState(() => _signatureBytesdrafter = null);
        setState(() => _signatureBytespemeriksa = null);
        ref.read(customerInvalidator.notifier).state++;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildParafItem({
    required String title,
    required Uint8List? imageBytes,
    required VoidCallback onPick,
    required Function(DropDoneDetails) onDragDone,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropTarget(
              onDragDone: onDragDone,
              onDragEntered: (details) => setState(() => _isDragging = true),
              onDragExited: (details) => setState(() => _isDragging = false),
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: _isDragging
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: _isDragging ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: imageBytes != null
                    ? Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          color: colorScheme.onSurface,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      )
                    : Center(
                        child: Text(
                          'PNG',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text(
                'Pilih\nGambar',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onPick,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Lebar ±500px',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bagian Input Teks (Dibuat Grid 2 Baris agar Tidak Memanjang ke Bawah)
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _namaPtController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Customer',
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pjController,
                            decoration: const InputDecoration(
                              labelText: 'Penanggung Jawab',
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _namaLengkapController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap (Opsional)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _jabatanController,
                            decoration: const InputDecoration(
                              labelText: 'Jabatan (Opsional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _drafterController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Drafter (Opsional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pemeriksaController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Pemeriksa (Opsional)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Bagian Upload Paraf (Dibuat lebih rapi dan ringkas)
              _buildParafItem(
                title: 'Paraf PJ',
                imageBytes: _signatureBytespj,
                onPick: () => _pickImage('pj'),
                onDragDone: (details) async {
                  if (details.files.isNotEmpty) {
                    final file = details.files.first;
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _signatureBytespj = bytes;
                      _signatureNamepj = file.name;
                    });
                  }
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),

              _buildParafItem(
                title: 'Paraf Drafter',
                imageBytes: _signatureBytesdrafter,
                onPick: () => _pickImage('drafter'),
                onDragDone: (details) async {
                  if (details.files.isNotEmpty) {
                    final file = details.files.first;
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _signatureBytesdrafter = bytes;
                      _signatureNamedrafter = file.name;
                    });
                  }
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),

              _buildParafItem(
                title: 'Paraf Pemeriksa',
                imageBytes: _signatureBytespemeriksa,
                onPick: () => _pickImage('pemeriksa'),
                onDragDone: (details) async {
                  if (details.files.isNotEmpty) {
                    final file = details.files.first;
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _signatureBytespemeriksa = bytes;
                      _signatureNamepemeriksa = file.name;
                    });
                  }
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),

              const SizedBox(
                height: 80,
                child: VerticalDivider(
                  color: Color(0xFF0D47A1),
                  thickness: 1,
                  width: 20,
                ),
              ),
              const SizedBox(width: 8),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Tambah\nCustomer',
                        textAlign: TextAlign.center,
                      ),
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 10,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
