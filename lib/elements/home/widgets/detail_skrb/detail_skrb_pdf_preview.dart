// File: lib/elements/home/widgets/detail_skrb/detail_skrb_pdf_preview.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class DetailSkrbPdfPreview extends StatelessWidget {
  final bool showPdfCard;
  final bool isLoadingPdf;
  final String? pdfCardTitle;
  final List<Uint8List> pdfBytesList;
  final VoidCallback onClose;

  const DetailSkrbPdfPreview({
    super.key,
    required this.showPdfCard,
    required this.isLoadingPdf,
    required this.pdfCardTitle,
    required this.pdfBytesList,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!showPdfCard || (!isLoadingPdf && pdfBytesList.isEmpty)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: 6,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      pdfCardTitle ?? 'Preview Dokumen PDF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Tutup Preview',
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: isLoadingPdf
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 2),
                            Text(
                              'Memuat dokumen preview...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : pdfBytesList.length == 1
                    ? _SingleSkrbPdfViewer(
                        bytes: pdfBytesList.first,
                        sourceName: pdfCardTitle ?? 'preview.pdf',
                        keyVal: ValueKey(pdfBytesList.first.hashCode),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(1),
                        itemCount: pdfBytesList.length,
                        itemBuilder: (context, idx) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 1),
                                  Text(
                                    'Dokumen TDP ke-${idx + 1} (dari total ${pdfBytesList.length} file)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 600,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withAlpha(60),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _SingleSkrbPdfViewer(
                                    bytes: pdfBytesList[idx],
                                    sourceName: 'preview_$idx.pdf',
                                    keyVal: ValueKey(pdfBytesList[idx].hashCode),
                                  ),
                                ),
                              ),
                            ),
                            if (idx < pdfBytesList.length - 1)
                              const SizedBox(height: 2),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleSkrbPdfViewer extends StatefulWidget {
  final Uint8List bytes;
  final String sourceName;
  final Key keyVal;
  const _SingleSkrbPdfViewer({
    required this.bytes,
    required this.sourceName,
    required this.keyVal,
  });

  @override
  State<_SingleSkrbPdfViewer> createState() => _SingleSkrbPdfViewerState();
}

class _SingleSkrbPdfViewerState extends State<_SingleSkrbPdfViewer> {
  final _controller = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        if (_controller.isReady) {
          final current = _controller.currentZoom;
          final fit = _controller.alternativeFitScale ?? _controller.minScale;
          final cover = _controller.coverScale;
          if ((current - fit).abs() < 0.05) {
            _controller.setZoom(details.localPosition, cover);
          } else {
            _controller.setZoom(details.localPosition, fit);
          }
        }
      },
      onDoubleTap: () {},
      child: PdfViewer.data(
        widget.bytes,
        sourceName: widget.sourceName,
        key: widget.keyVal,
        controller: _controller,
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

