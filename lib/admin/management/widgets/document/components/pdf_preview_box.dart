// lib/admin/management/widgets/document/components/pdf_preview_box.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Function helper untuk membuka modal dialog preview PDF dalam ukuran besar.
void showPdfPreviewDialog(
  BuildContext context, {
  required Widget previewWidget,
  required String title,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              // Body preview
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  child: previewWidget,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Kotak preview PDF berukuran A4 portrait.
/// Menampilkan placeholder jika [previewContent] null.
class DocPreviewBox extends StatelessWidget {
  final Widget? previewContent;
  final ColorScheme colorScheme;
  final VoidCallback? onOpenPreview;
  final String title;

  const DocPreviewBox({
    super.key,
    required this.previewContent,
    required this.colorScheme,
    this.onOpenPreview,
    this.title = 'Preview PDF',
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = previewContent != null;

    Widget child = Container(
      height: 450,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          if (hasPreview)
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
          child: Stack(
            children: [
              Positioned.fill(
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
              if (hasPreview)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap:
                          onOpenPreview ??
                          () => showPdfPreviewDialog(
                            context,
                            previewWidget: previewContent!,
                            title: title,
                          ),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 18,
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

    // if (hasPreview) {
    //   return Tooltip(
    //     message: 'Klik untuk membuka preview penuh',
    //     child: InkWell(
    //       borderRadius: BorderRadius.circular(6),
    //       onTap:
    //           onOpenPreview ??
    //           () => showPdfPreviewDialog(
    //             context,
    //             previewWidget: previewContent!,
    //             title: title,
    //           ),
    //       child: child,
    //     ),
    //   );
    // }

    return child;
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

