// File: lib/admin/master/widgets/pilih_file_pdf_card.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/providers/master_data_providers.dart';
import 'package:pdfrx/pdfrx.dart';

// UBAH JADI STATEFUL WIDGET AGAR BISA SIMPAN STATE VIEW MODE
class PilihFilePdfCard extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;
  final bool isLoading;

  const PilihFilePdfCard({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  ConsumerState<PilihFilePdfCard> createState() => _PilihFilePdfCardState();
}

class _PilihFilePdfCardState extends ConsumerState<PilihFilePdfCard> {
  // State untuk mode tampilan: True = Horizontal (3 Kolom), False = Vertical (List ke bawah)
  bool _isHorizontalView = true;

  Future<PdfFileData?> _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // WAJIB TRUE AGAR JALAN DI WEB
    );

    if (result != null) {
      final file = result.files.single;

      // --- VALIDASI UKURAN FILE (Max 1 MB) ---
      final int sizeInBytes = file.size; // Ambil size langsung dari FilePicker
      const int maxBytes = 1024 * 1024; // 1 MB

      if (sizeInBytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal: Ukuran file melebihi 1 MB.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // Ambil bytes untuk Web dan Desktop
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = File(file.path!).readAsBytesSync();
      }

      if (fileBytes != null) {
        return PdfFileData(
          name: file.name,
          bytes: fileBytes,
          size: sizeInBytes,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isVarianBodySelected =
        ref.watch(mguSelectedVarianBodyIdProvider) != null;

    final gambarUtamaFile = ref.watch(mguGambarUtamaFileProvider);
    // Kita tidak perlu cek terurai/kontruksi untuk mengaktifkan tombol
    // final gambarTeruraiFile = ref.watch(mguGambarTeruraiFileProvider);
    // final gambarKontruksiFile = ref.watch(mguGambarKontruksiFileProvider);

    // LOGIKA BARU: Hanya Gambar Utama yang WAJIB
    final allFilesSelected = gambarUtamaFile != null;
    return Card(
      color: isVarianBodySelected
          ? null
          : Theme.of(context).cardColor.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DENGAN TOMBOL TOGGLE ---
            Row(
              children: [
                Text(
                  '2. Pilih File PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVarianBodySelected ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol kecil untuk ganti layout
                InkWell(
                  onTap: () {
                    setState(() {
                      _isHorizontalView = !_isHorizontalView;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      // Ganti icon sesuai mode
                      _isHorizontalView
                          ? Icons
                                .view_list // Icon untuk switch ke Vertical
                          : Icons
                                .view_column, // Icon untuk switch ke Horizontal
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (!isVarianBodySelected) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '(Pilih Varian Body dulu)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1),

            // --- PILIH LAYOUT BERDASARKAN STATE ---
            if (_isHorizontalView)
              _buildHorizontalLayout(
                isVarianBodySelected,
                gambarUtamaFile,
                ref.watch(mguGambarTeruraiFileProvider), // Baca langsung
                ref.watch(mguGambarKontruksiFileProvider), // Baca langsung
              )
            else
              _buildVerticalLayout(
                isVarianBodySelected,
                gambarUtamaFile,
                ref.watch(mguGambarTeruraiFileProvider),
                ref.watch(mguGambarKontruksiFileProvider),
              ),

            const SizedBox(height: 10),

            // Tombol Upload
            SizedBox(
              width: double.infinity,
              height: 34,
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Gambar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: allFilesSelected ? widget.onSubmit : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // === LAYOUT 1: HORIZONTAL (YANG BARU) ===
  Widget _buildHorizontalLayout(
    bool enabled,
    PdfFileData? fUtama,
    PdfFileData? fTerurai,
    PdfFileData? fKontruksi,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildHorizontalItem(
            label: 'Gambar Utama',
            file: fUtama,
            onPressed: enabled
                ? () async {
                    final f = await _pickPdfFile();
                    if (f != null) {
                      ref.read(mguGambarUtamaFileProvider.notifier).state = f;
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHorizontalItem(
            label: 'Gambar Terurai',
            file: fTerurai,
            onPressed: enabled
                ? () async {
                    final f = await _pickPdfFile();
                    if (f != null) {
                      ref.read(mguGambarTeruraiFileProvider.notifier).state = f;
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHorizontalItem(
            label: 'Gambar Kontruksi',
            file: fKontruksi,
            onPressed: enabled
                ? () async {
                    final f = await _pickPdfFile();
                    if (f != null) {
                      ref.read(mguGambarKontruksiFileProvider.notifier).state =
                          f;
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // === LAYOUT 2: VERTICAL (YANG LAMA - DITUMPUK) ===
  Widget _buildVerticalLayout(
    bool enabled,
    PdfFileData? fUtama,
    PdfFileData? fTerurai,
    PdfFileData? fKontruksi,
  ) {
    return Column(
      children: [
        _buildVerticalItem(
          label: 'Gambar Utama',
          file: fUtama,
          onPressed: enabled
              ? () async {
                  final f = await _pickPdfFile();
                  if (f != null) {
                    ref.read(mguGambarUtamaFileProvider.notifier).state = f;
                  }
                }
              : null,
        ),
        const SizedBox(height: 16),
        _buildVerticalItem(
          label: 'Gambar Terurai',
          file: fTerurai,
          onPressed: enabled
              ? () async {
                  final f = await _pickPdfFile();
                  if (f != null) {
                    ref.read(mguGambarTeruraiFileProvider.notifier).state = f;
                  }
                }
              : null,
        ),
        const SizedBox(height: 16),
        _buildVerticalItem(
          label: 'Gambar Kontruksi',
          file: fKontruksi,
          onPressed: enabled
              ? () async {
                  final f = await _pickPdfFile();
                  if (f != null) {
                    ref.read(mguGambarKontruksiFileProvider.notifier).state = f;
                  }
                }
              : null,
        ),
      ],
    );
  }

  // --- ITEM WIDGET UTK HORIZONTAL (Input ATAS, Preview BAWAH) ---
  Widget _buildHorizontalItem({
    required String label,
    PdfFileData? file,
    VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            file?.name ?? 'Belum ada file...',
            style: TextStyle(
              color: file != null
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 248,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
            color: colorScheme.surfaceContainerLow,
          ),
          child: file != null
              ? _PdfPreviewer(file: file)
              : Center(
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
        ),
      ],
    );
  }

  // --- ITEM WIDGET UTK VERTICAL (Input KIRI, Preview KANAN) ---
  Widget _buildVerticalItem({
    required String label,
    PdfFileData? file,
    VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kiri: Input
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file?.name ?? 'Belum ada file dipilih...',
                  style: TextStyle(
                    color: file != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(label),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Kanan: Preview
        Expanded(
          flex: 3,
          child: Container(
            height: 400, // Lebih tinggi untuk mode vertical
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
              color: colorScheme.surfaceContainerLow,
            ),
            child: file != null
                ? _PdfPreviewer(file: file)
                : Center(
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 40,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// Widget khusus untuk preview PDF, menggunakan pdfrx
class _PdfPreviewer extends StatefulWidget {
  final PdfFileData file;
  const _PdfPreviewer({required this.file});

  @override
  State<_PdfPreviewer> createState() => _PdfPreviewerState();
}

class _PdfPreviewerState extends State<_PdfPreviewer> {
  final _pdfController = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    final bytesCopy = Uint8List.fromList(widget.file.bytes);
    return GestureDetector(
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
        bytesCopy,
        sourceName: widget.file.name,
        key: ValueKey('${widget.file.name}_${widget.file.size}'),
        controller: _pdfController,
        params: PdfViewerParams(
          textSelectionParams: const PdfTextSelectionParams(enabled: false),
          sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
            calculateInitialZoom: (doc, controller, altFitScale, coverScale) => altFitScale,
          ),
        ),
      ),
    );
  }
}
