// lib/admin/management/widgets/customer/edit_customer_dialog.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/management/providers/customer_providers.dart';
import 'package:master_gambar/admin/management/repository/customer_repository.dart';
import 'package:master_gambar/data/models/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/core/providers.dart';

class EditCustomerDialog extends ConsumerStatefulWidget {
  final Customer customer;
  const EditCustomerDialog({super.key, required this.customer});

  @override
  ConsumerState<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends ConsumerState<EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _namaPtController;
  late final TextEditingController _pjController;
  late final TextEditingController _namaLengkapController;
  late final TextEditingController _jabatanController;
  late final TextEditingController _namaDrafterController;
  late final TextEditingController _namaPemeriksaController;

  // Files
  Uint8List? _signaturePjBytes;
  String? _signaturePjName;

  Uint8List? _signatureDrafterBytes;
  String? _signatureDrafterName;

  Uint8List? _signaturePemeriksaBytes;
  String? _signaturePemeriksaName;

  // Drag States
  bool _isDraggingPj = false;
  bool _isDraggingDrafter = false;
  bool _isDraggingPemeriksa = false;

  bool _isLoading = false;
  String? _authToken;
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _namaPtController = TextEditingController(text: _currentCustomer.namaPt);
    _pjController = TextEditingController(text: _currentCustomer.pj);
    _namaLengkapController = TextEditingController(
      text: _currentCustomer.namaLengkap ?? '',
    );
    _jabatanController = TextEditingController(
      text: _currentCustomer.jabatan ?? '',
    );
    _namaDrafterController = TextEditingController(
      text: _currentCustomer.namaDrafter ?? '',
    );
    _namaPemeriksaController = TextEditingController(
      text: _currentCustomer.namaPemeriksa ?? '',
    );
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
  }

  @override
  void dispose() {
    _namaPtController.dispose();
    _pjController.dispose();
    _namaLengkapController.dispose();
    _jabatanController.dispose();
    _namaDrafterController.dispose();
    _namaPemeriksaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = File(file.path!).readAsBytesSync();
      }

      if (fileBytes != null) {
        setState(() {
          if (type == 'pj') {
            _signaturePjBytes = fileBytes;
            _signaturePjName = file.name;
          }
          if (type == 'drafter') {
            _signatureDrafterBytes = fileBytes;
            _signatureDrafterName = file.name;
          }
          if (type == 'pemeriksa') {
            _signaturePemeriksaBytes = fileBytes;
            _signaturePemeriksaName = file.name;
          }
        });
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(customerRepositoryProvider);

        // Update Text Data
        await repo.updateCustomer(
          id: _currentCustomer.id,
          namaPt: _namaPtController.text,
          pj: _pjController.text,
          namaLengkap: _namaLengkapController.text.isNotEmpty
              ? _namaLengkapController.text
              : null,
          jabatan: _jabatanController.text.isNotEmpty
              ? _jabatanController.text
              : null,
          namaDrafter: _namaDrafterController.text,
          namaPemeriksa: _namaPemeriksaController.text,
        );

        // Upload files if changed
        if (_signaturePjBytes != null) {
          await repo.uploadSignature(
            customerId: _currentCustomer.id,
            bytes: _signaturePjBytes!,
            fileName: _signaturePjName ?? 'pj.png',
          );
        }
        if (_signatureDrafterBytes != null) {
          await repo.uploadSignatureDrafter(
            customerId: _currentCustomer.id,
            bytes: _signatureDrafterBytes!,
            fileName: _signatureDrafterName ?? 'drafter.png',
          );
        }
        if (_signaturePemeriksaBytes != null) {
          await repo.uploadSignaturePemeriksa(
            customerId: _currentCustomer.id,
            bytes: _signaturePemeriksaBytes!,
            fileName: _signaturePemeriksaName ?? 'pemeriksa.png',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(customerInvalidator.notifier).state++;
        Navigator.of(context).pop();
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // (Method _submitDelete tetap sama seperti sebelumnya)
  Future<void> _submitDelete() async {
    final hasDocument = widget.customer.statusTdp != null || widget.customer.tdpMasaBerlaku != null;
    final hasParaf = widget.customer.signaturePj != null ||
        widget.customer.signatureDrafter != null ||
        widget.customer.signaturePemeriksa != null;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (hasDocument || hasParaf) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Peringatan: Hapus Customer & Dokumen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda yakin ingin menghapus customer "${widget.customer.namaPt}"?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perhatian! Customer ini memiliki data penting yang tersimpan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasDocument) ...[
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.folder_delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Seluruh file PDF Document Customer (Kop Surat, Data Umum, dan semua TDP) beserta tabel record akan di-HAPUS PERMANEN dari storage dan database.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (hasDocument && hasParaf) const SizedBox(height: 8),
                        if (hasParaf) ...[
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.draw, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Semua file gambar Paraf (PJ, Drafter, & Pemeriksa) akan di-HAPUS PERMANEN dari storage.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tindakan ini tidak dapat dibatalkan!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Ya, Hapus Semua'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Anda yakin ingin menghapus customer: ${widget.customer.namaPt}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(customerRepositoryProvider)
            .deleteCustomer(id: widget.customer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(customerInvalidator.notifier).state++;
        Navigator.of(context).pop();
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

  Widget _buildParafUpload({
    required String label,
    required Uint8List? currentBytes,
    required String? imageUrl,
    required bool isDragging,
    required Function(Uint8List, String) onFileDropped, // Ubah fungsi callback
    required Function(bool) onDragUpdate,
    required VoidCallback onPick,
    required String? signatureKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            DropTarget(
              onDragDone: (details) async {
                // Ubah jadi async
                if (details.files.isNotEmpty) {
                  final file = details.files.first;
                  final bytes = await file
                      .readAsBytes(); // Ambil bytes langsung dari XFile
                  onFileDropped(bytes, file.name);
                }
              },
              onDragEntered: (_) => onDragUpdate(true),
              onDragExited: (_) => onDragUpdate(false),
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: isDragging ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: currentBytes != null
                    ? Image.memory(
                        currentBytes,
                        fit: BoxFit.contain,
                        color: Theme.of(context).colorScheme.onSurface,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : (imageUrl != null
                          ? Image.network(
                              imageUrl,
                              key: ValueKey(signatureKey),
                              fit: BoxFit.contain,
                              headers: {'Authorization': 'Bearer $_authToken'},
                              color: Theme.of(context).colorScheme.onSurface,
                              colorBlendMode: BlendMode.srcIn,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            )
                          : Center(
                              child: Text(
                                'PNG',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            )),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Ganti Gambar'),
              onPressed: onPick,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;
    final timestamp = _currentCustomer.updatedAt.millisecondsSinceEpoch;

    final pjImageUrl =
        (_authToken != null && _currentCustomer.signaturePj != null)
        ? '$baseUrl/admin/customers/${_currentCustomer.id}/paraf?v=$timestamp'
        : null;
    final drafterImageUrl =
        (_authToken != null && _currentCustomer.signatureDrafter != null)
        ? '$baseUrl/admin/customers/${_currentCustomer.id}/paraf-drafter?v=$timestamp'
        : null;
    final pemeriksaImageUrl =
        (_authToken != null && _currentCustomer.signaturePemeriksa != null)
        ? '$baseUrl/admin/customers/${_currentCustomer.id}/paraf-pemeriksa?v=$timestamp'
        : null;

    return AlertDialog(
      title: Text(
        'Edit Customer: ${_currentCustomer.namaPt}',
        style: const TextStyle(fontSize: 21),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Ditambahkan agar bisa scroll
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _namaPtController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Customer (PT)',
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // --- SECTION PJ ---
                TextFormField(
                  controller: _pjController,
                  decoration: const InputDecoration(
                    labelText: 'Penanggung Jawab (PJ)',
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _namaLengkapController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap (Opsional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _jabatanController,
                  decoration: const InputDecoration(
                    labelText: 'Jabatan (Opsional)',
                  ),
                ),
                const SizedBox(height: 8),
                _buildParafUpload(
                  label: 'Paraf PJ',
                  currentBytes: _signaturePjBytes,
                  imageUrl: pjImageUrl,
                  isDragging: _isDraggingPj,
                  onFileDropped: (bytes, name) => setState(() {
                    _signaturePjBytes = bytes;
                    _signaturePjName = name;
                  }),
                  onDragUpdate: (val) => setState(() => _isDraggingPj = val),
                  onPick: () => _pickImage('pj'),
                  signatureKey: _currentCustomer.signaturePj,
                ),
                const Divider(height: 32),

                // --- SECTION DRAFTER ---
                TextFormField(
                  controller: _namaDrafterController,
                  decoration: const InputDecoration(labelText: 'Nama Drafter'),
                ),
                const SizedBox(height: 8),
                _buildParafUpload(
                  label: 'Paraf Drafter',
                  currentBytes: _signatureDrafterBytes,
                  imageUrl: drafterImageUrl,
                  isDragging: _isDraggingDrafter,
                  onFileDropped: (bytes, name) => setState(() {
                    _signatureDrafterBytes = bytes;
                    _signatureDrafterName = name;
                  }),
                  onDragUpdate: (val) =>
                      setState(() => _isDraggingDrafter = val),
                  onPick: () => _pickImage('drafter'),
                  signatureKey: _currentCustomer.signatureDrafter,
                ),
                const Divider(height: 32),

                // --- SECTION PEMERIKSA ---
                TextFormField(
                  controller: _namaPemeriksaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pemeriksa',
                  ),
                ),
                const SizedBox(height: 8),
                _buildParafUpload(
                  label: 'Paraf Pemeriksa',
                  currentBytes: _signaturePemeriksaBytes,
                  imageUrl: pemeriksaImageUrl,
                  isDragging: _isDraggingPemeriksa,
                  onFileDropped: (bytes, name) => setState(() {
                    _signaturePemeriksaBytes = bytes;
                    _signaturePemeriksaName = name;
                  }),
                  onDragUpdate: (val) =>
                      setState(() => _isDraggingPemeriksa = val),
                  onPick: () => _pickImage('pemeriksa'),
                  signatureKey: _currentCustomer.signaturePemeriksa,
                ),

                const SizedBox(height: 16),
                const Text(
                  'Saran lebar gambar ± 500px (Format PNG)',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isLoading) const CircularProgressIndicator(),
        TextButton(
          onPressed: _isLoading ? null : _submitDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
        const SizedBox(width: 200),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitUpdate,
          child: const Text('Update Customer'),
        ),
      ],
    );
  }
}
