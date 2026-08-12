// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
// import 'package:pdfrx/pdfrx.dart';

// class AddGambarOptionalForm extends ConsumerStatefulWidget {
//   final Function(int varianBodyId, String deskripsi, File file) onUpload;

//   const AddGambarOptionalForm({super.key, required this.onUpload});

//   @override
//   ConsumerState<AddGambarOptionalForm> createState() =>
//       _AddGambarOptionalFormState();
// }

// class _AddGambarOptionalFormState extends ConsumerState<AddGambarOptionalForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _deskripsiController = TextEditingController();

//   String? _selectedTypeEngineId;
//   String? _selectedMerkId;
//   String? _selectedTypeChassisId;
//   String? _selectedJenisKendaraanId;
//   int? _selectedVarianBodyId;

//   File? _selectedFile;
//   PdfController? _pdfController;

//   @override
//   void dispose() {
//     _deskripsiController.dispose();
//     _pdfController?.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//     );

//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//         _pdfController?.dispose();
//         _pdfController = PdfController(
//           document: PdfDocument.openFile(_selectedFile!.path),
//         );
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final typeEngineOptions = ref.watch(typeEngineListProvider);
//     final merkOptions = ref.watch(
//       merkOptionsFamilyProvider(_selectedTypeEngineId),
//     );
//     final typeChassisOptions = ref.watch(
//       typeChassisOptionsFamilyProvider(_selectedMerkId),
//     );
//     final jenisKendaraanOptions = ref.watch(
//       jenisKendaraanOptionsFamilyProvider(_selectedTypeChassisId),
//     );
//     final varianBodyOptions = ref.watch(
//       varianBodyOptionsFamilyProvider(_selectedJenisKendaraanId),
//     );

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SizedBox(
//           height: 460,
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // --- KOLOM KIRI: FORM ---
//               Expanded(
//                 flex: 2,
//                 child: Form(
//                   key: _formKey,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Dropdown Type Engine
//                         typeEngineOptions.when(
//                           data: (options) => DropdownButtonFormField<String>(
//                             value: _selectedTypeEngineId,
//                             decoration: const InputDecoration(
//                               labelText: 'Type Engine',
//                             ),
//                             items: options
//                                 .map(
//                                   (opt) => DropdownMenuItem(
//                                     value: opt.id,
//                                     child: Text(opt.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             onChanged: (value) => setState(() {
//                               _selectedTypeEngineId = value;
//                               _selectedMerkId = null;
//                               _selectedTypeChassisId = null;
//                               _selectedJenisKendaraanId = null;
//                               _selectedVarianBodyId = null;
//                             }),
//                             validator: (v) =>
//                                 v == null ? 'Wajib dipilih' : null,
//                           ),
//                           loading: () =>
//                               const Center(child: CircularProgressIndicator()),

//                           error: (e, st) => const Text('Error'),
//                         ),
//                         const SizedBox(height: 16),

//                         // Dropdown Merk
//                         merkOptions.when(
//                           data: (options) => DropdownButtonFormField<String>(
//                             value: _selectedMerkId,
//                             decoration: const InputDecoration(
//                               labelText: 'Merk',
//                             ),
//                             items: options
//                                 .map(
//                                   (opt) => DropdownMenuItem(
//                                     value: opt.id as String,
//                                     child: Text(opt.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             onChanged: (value) => setState(() {
//                               _selectedMerkId = value;
//                               _selectedTypeChassisId = null;
//                               _selectedJenisKendaraanId = null;
//                               _selectedVarianBodyId = null;
//                             }),
//                             validator: (v) =>
//                                 v == null ? 'Wajib dipilih' : null,
//                           ),
//                           loading: () =>
//                               const Center(child: CircularProgressIndicator()),

//                           error: (e, st) => const Text('Error'),
//                         ),
//                         const SizedBox(height: 16),

//                         // Dropdown Type Chassis
//                         typeChassisOptions.when(
//                           data: (options) => DropdownButtonFormField<String>(
//                             value: _selectedTypeChassisId,
//                             decoration: const InputDecoration(
//                               labelText: 'Type Chassis',
//                             ),
//                             items: options
//                                 .map(
//                                   (opt) => DropdownMenuItem(
//                                     value: opt.id as String,
//                                     child: Text(opt.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             onChanged: (value) => setState(() {
//                               _selectedTypeChassisId = value;
//                               _selectedJenisKendaraanId = null;
//                               _selectedVarianBodyId = null;
//                             }),
//                             validator: (v) =>
//                                 v == null ? 'Wajib dipilih' : null,
//                           ),
//                           loading: () =>
//                               const Center(child: CircularProgressIndicator()),
//                           error: (e, st) => const Text('Error'),
//                         ),
//                         const SizedBox(height: 16),

//                         // Dropdown Jenis Kendaraan
//                         jenisKendaraanOptions.when(
//                           data: (options) => DropdownButtonFormField<String>(
//                             value: _selectedJenisKendaraanId,
//                             decoration: const InputDecoration(
//                               labelText: 'Jenis Kendaraan',
//                             ),
//                             items: options
//                                 .map(
//                                   (opt) => DropdownMenuItem(
//                                     value: opt.id as String,
//                                     child: Text(opt.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             onChanged: (value) => setState(() {
//                               _selectedJenisKendaraanId = value;
//                               _selectedVarianBodyId = null;
//                             }),
//                             validator: (v) =>
//                                 v == null ? 'Wajib dipilih' : null,
//                           ),
//                           loading: () =>
//                               const Center(child: CircularProgressIndicator()),
//                           error: (e, st) => const Text('Error'),
//                         ),
//                         const SizedBox(height: 16),

//                         // Dropdown Varian Body
//                         varianBodyOptions.when(
//                           data: (options) => DropdownButtonFormField<int>(
//                             value: _selectedVarianBodyId,
//                             decoration: const InputDecoration(
//                               labelText: 'Varian Body',
//                             ),
//                             items: options
//                                 .map(
//                                   (opt) => DropdownMenuItem(
//                                     value: opt.id as int,
//                                     child: Text(opt.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             onChanged: (value) =>
//                                 setState(() => _selectedVarianBodyId = value),
//                             validator: (v) =>
//                                 v == null ? 'Wajib dipilih' : null,
//                           ),
//                           loading: () =>
//                               const Center(child: CircularProgressIndicator()),
//                           error: (e, st) => const Text('Error'),
//                         ),
//                         const SizedBox(height: 16),

//                         // Input Deskripsi
//                         TextFormField(
//                           controller: _deskripsiController,
//                           decoration: const InputDecoration(
//                             labelText: 'Deskripsi',
//                           ),
//                           textCapitalization: TextCapitalization.characters,
//                           validator: (v) =>
//                               (v == null || v.isEmpty) ? 'Wajib diisi' : null,
//                         ),
//                         const SizedBox(height: 24),
//                         // Tombol Pilih Gambar
//                         // --- PERUBAHAN 1: TOMBOL BERSEBELAHAN & NAMA FILE ---
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             Row(
//                               children: [
//                                 // Tombol Pilih/Ganti Gambar
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     icon: const Icon(Icons.picture_as_pdf),
//                                     label: Text(
//                                       _selectedFile == null
//                                           ? 'Pilih Gambar'
//                                           : 'Ganti Gambar',
//                                     ),
//                                     onPressed: _pickFile,
//                                     style: ElevatedButton.styleFrom(
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ),

//                                 // Tombol Upload (muncul jika file sudah dipilih)
//                                 if (_selectedFile != null) ...[
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: ElevatedButton.icon(
//                                       icon: const Icon(Icons.upload_file),
//                                       label: const Text('Upload Gambar'),
//                                       onPressed: () {
//                                         if (_formKey.currentState!.validate()) {
//                                           widget.onUpload(
//                                             _selectedVarianBodyId!,
//                                             _deskripsiController.text,
//                                             _selectedFile!,
//                                           );
//                                         }
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.green,
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 16,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),

//                             // Menampilkan nama file yang dipilih
//                             if (_selectedFile != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 8.0),
//                                 child: Text(
//                                   'File: ${_selectedFile!.path.split(Platform.pathSeparator).last}',
//                                   style: Theme.of(context).textTheme.bodySmall,
//                                   textAlign: TextAlign.center,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               // --- KOLOM KANAN: PREVIEW PDF ---
//               // --- PERUBAHAN 2: FRAME DENGAN CARD ---
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   // height: 400,
//                   clipBehavior: Clip
//                       .antiAlias, // Penting agar preview tidak keluar dari border
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade400),
//                     borderRadius: BorderRadius.circular(
//                       8.0,
//                     ), // Samakan dengan field input
//                   ),
//                   child: _pdfController != null
//                       ? PdfView(
//                           key: ValueKey(_selectedFile!.path),
//                           controller: _pdfController!,
//                         )
//                       : const Center(
//                           child: Icon(
//                             Icons.picture_as_pdf_outlined,
//                             color: Colors.grey,
//                             size: 60,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
