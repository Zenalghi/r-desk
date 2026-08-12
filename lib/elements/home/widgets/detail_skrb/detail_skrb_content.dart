// File: lib/elements/home/widgets/detail_skrb/detail_skrb_content.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/data/models/skrb.dart';
import '../../providers/page_state_provider.dart';
import '../../providers/skrb_providers.dart';
import 'doc_item.dart';
import 'detail_skrb_doc_row.dart';
import 'detail_skrb_pdf_preview.dart';
import 'detail_skrb_footer.dart';

class DetailSkrbContent extends ConsumerWidget {
  final int skrbId;
  final bool showPdfCard;
  final bool isLoadingPdf;
  final String? pdfCardTitle;
  final List<Uint8List> pdfBytesList;
  final bool isProcessing;
  final String? processingKey;
  final VoidCallback onClosePdfPreview;
  final Future<void> Function(String key, bool isHidden) onToggleHide;
  final Future<void> Function(String key) onUploadFile;
  final Future<void> Function(DocItem item) onPreviewPdf;
  final Future<void> Function({required bool download}) onMerge;
  final Future<void> Function(int targetPhase) onSwitchPhase;
  final VoidCallback onResetFiles;
  final void Function(Skrb skrb) onShowHistory;
  final VoidCallback? onLiveUpdate;

  const DetailSkrbContent({
    super.key,
    required this.skrbId,
    required this.showPdfCard,
    required this.isLoadingPdf,
    required this.pdfCardTitle,
    required this.pdfBytesList,
    required this.isProcessing,
    required this.processingKey,
    required this.onClosePdfPreview,
    required this.onToggleHide,
    required this.onUploadFile,
    required this.onPreviewPdf,
    required this.onMerge,
    required this.onSwitchPhase,
    required this.onResetFiles,
    required this.onShowHistory,
    this.onLiveUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final skrbAsync = ref.watch(skrbDetailProvider(skrbId));

    return skrbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat Detail SKRB: $err',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Tabel Permohonan'),
              onPressed: () {
                ref.read(pageStateProvider.notifier).state = PageState(
                  pageIndex: 2,
                );
              },
            ),
          ],
        ),
      ),
      data: (skrb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(skrbSaveCallbackProvider.notifier).state = () =>
              onMerge(download: false);
        });
        final isLocked = (skrb.fase == 2);
        final items = DocItem.buildList(skrb);

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: showPdfCard ? 6 : 12,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   'Daftar Dokumen SKRB:',
                              //   style: TextStyle(
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withAlpha(
                                            20,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                'No',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                'Nama & Jenis Dokumen',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Status File',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                'Actions',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...items.map(
                                        (item) => DetailSkrbDocRow(
                                          skrb: skrb,
                                          item: item,
                                          isLocked: isLocked,
                                          isProcessing: isProcessing,
                                          processingKey: processingKey,
                                          onToggleHide: onToggleHide,
                                          onUploadFile: onUploadFile,
                                          onPreviewPdf: onPreviewPdf,
                                          onLiveUpdate: onLiveUpdate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showPdfCard &&
                        (isLoadingPdf || pdfBytesList.isNotEmpty)) ...[
                      const SizedBox(width: 12),
                      DetailSkrbPdfPreview(
                        showPdfCard: showPdfCard,
                        isLoadingPdf: isLoadingPdf,
                        pdfCardTitle: pdfCardTitle,
                        pdfBytesList: pdfBytesList,
                        onClose: onClosePdfPreview,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DetailSkrbFooter(
              skrb: skrb,
              isProcessing: isProcessing,
              onMerge: onMerge,
              onSwitchPhase: onSwitchPhase,
              onResetFiles: onResetFiles,
              onShowHistory: () => onShowHistory(skrb),
            ),
          ],
        );
      },
    );
  }
}
