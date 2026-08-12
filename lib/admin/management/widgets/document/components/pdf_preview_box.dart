// lib/admin/management/widgets/document/components/pdf_preview_box.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Kotak preview PDF berukuran A4 portrait.
/// Menampilkan placeholder jika [previewContent] null.
class DocPreviewBox extends StatelessWidget {
  final Widget? previewContent;
  final ColorScheme colorScheme;

  const DocPreviewBox({
    super.key,
    required this.previewContent,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          if (previewContent != null)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 Portrait
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child:
              previewContent ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

/// Widget stateful yang menangani rendering PDF dari bytes atau URL loader.
class A4PdfPreviewer extends StatefulWidget {
  final Future<Uint8List> Function()? futureLoader;
  final Uint8List? bytes;
  final String cacheKey;
  final Color backgroundColor;

  const A4PdfPreviewer({
    super.key,
    this.futureLoader,
    this.bytes,
    required this.cacheKey,
    this.backgroundColor = const Color.fromARGB(255, 229, 229, 229),
  });

  @override
  State<A4PdfPreviewer> createState() => _A4PdfPreviewerState();
}

class _A4PdfPreviewerState extends State<A4PdfPreviewer> {
  Uint8List? _pdfData;
  bool _isLoading = true;
  String? _errorMessage;
  final _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant A4PdfPreviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cacheKey != oldWidget.cacheKey) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _pdfData = null;
      });
      _initData();
    }
  }

  Future<void> _initData() async {
    try {
      Uint8List data;
      if (widget.bytes != null) {
        data = Uint8List.fromList(widget.bytes!);
      } else if (widget.futureLoader != null) {
        final res = await widget.futureLoader!();
        data = Uint8List.fromList(res);
      } else {
        throw Exception('Tidak ada data file');
      }

      if (mounted) {
        setState(() {
          _pdfData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_errorMessage != null || _pdfData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 6),
            const Text(
              'Gagal memuat PDF',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }
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
        _pdfData!,
        sourceName: widget.cacheKey,
        key: ValueKey(widget.cacheKey),
        controller: _pdfController,
        params: PdfViewerParams(
          textSelectionParams: const PdfTextSelectionParams(enabled: false),
          sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
            calculateInitialZoom: (doc, controller, altFitScale, coverScale) => altFitScale,
          ),
          backgroundColor: widget.backgroundColor,
        ),
      ),
    );
  }
}

