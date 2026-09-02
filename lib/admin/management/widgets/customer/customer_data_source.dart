// lib/admin/management/widgets/customer/customer_data_source.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:master_gambar/admin/management/providers/customer_providers.dart';
import 'package:master_gambar/admin/management/widgets/customer/edit_customer_dialog.dart';
import 'package:master_gambar/app/core/app_helpers.dart';
import 'package:master_gambar/app/core/providers.dart';
import 'package:master_gambar/data/models/customer.dart';

class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final int totalRecords;
  final int rowsPerPage;
  final int currentPage;
  final BuildContext context;
  final WidgetRef ref;

  CustomerDataSource({
    required this.customers,
    required this.totalRecords,
    required this.rowsPerPage,
    required this.currentPage,
    required this.context,
    required this.ref,
  });

  @override
  DataRow? getRow(int index) {
    final int localIndex = index - ((currentPage - 1) * rowsPerPage);

    if (localIndex < 0 || localIndex >= customers.length) {
      return null;
    }

    final customer = customers[localIndex];
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final authToken = ref.read(authTokenProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Ambil base URL dari instance Dio yang aktif
    final baseUrl = ref.read(apiClientProvider).dio.options.baseUrl;

    return DataRow(
      cells: [
        DataCell(SelectableText(customer.namaPt)),
        DataCell(SelectableText(customer.pj)),
        DataCell(SelectableText(customer.namaLengkap ?? '-')),
        DataCell(SelectableText(customer.jabatan ?? '-')),
        DataCell(SelectableText(customer.namaDrafter ?? '-')),
        DataCell(SelectableText(customer.namaPemeriksa ?? '-')),
        DataCell(
          (customer.signaturePj != null &&
                  customer.signaturePj!.isNotEmpty &&
                  authToken != null)
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Image.network(
                    '$baseUrl/admin/customers/${customer.id}/paraf?v=${customer.updatedAt.millisecondsSinceEpoch}',
                    headers: {'Authorization': 'Bearer $authToken'},
                    fit: BoxFit.contain,
                    color: colorScheme.onSurface,
                    colorBlendMode: BlendMode.srcIn,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                    // Tambahkan Tooltip di sini
                    errorBuilder: (context, error, stackTrace) => Tooltip(
                      message: 'Error: ${error.toString()}',
                      child: Icon(Icons.error, color: colorScheme.error),
                    ),
                  ),
                )
              : const Icon(
                  Icons.cancel,
                  size: 15,
                  color: Colors.red,
                  semanticLabel: 'Tidak Ada',
                ),
        ),
        DataCell(
          (customer.signatureDrafter != null &&
                  customer.signatureDrafter!.isNotEmpty &&
                  authToken != null)
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Image.network(
                    '$baseUrl/admin/customers/${customer.id}/paraf-drafter?v=${customer.updatedAt.millisecondsSinceEpoch}',
                    headers: {'Authorization': 'Bearer $authToken'},
                    fit: BoxFit.contain,
                    color: colorScheme.onSurface,
                    colorBlendMode: BlendMode.srcIn,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                    // Tambahkan Tooltip di sini
                    errorBuilder: (context, error, stackTrace) => Tooltip(
                      message: 'Error: ${error.toString()}',
                      child: Icon(Icons.error, color: colorScheme.error),
                    ),
                  ),
                )
              : const Icon(
                  Icons.cancel,
                  size: 15,
                  color: Colors.red,
                  semanticLabel: 'Tidak Ada',
                ),
        ),
        DataCell(
          (customer.signaturePemeriksa != null &&
                  customer.signaturePemeriksa!.isNotEmpty &&
                  authToken != null)
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Image.network(
                    '$baseUrl/admin/customers/${customer.id}/paraf-pemeriksa?v=${customer.updatedAt.millisecondsSinceEpoch}',
                    headers: {'Authorization': 'Bearer $authToken'},
                    fit: BoxFit.contain,
                    color: colorScheme.onSurface,
                    colorBlendMode: BlendMode.srcIn,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                    errorBuilder: (context, error, stackTrace) => Tooltip(
                      message: 'Error: ${error.toString()}',
                      child: Icon(Icons.error, color: colorScheme.error),
                    ),
                  ),
                )
              : const Icon(
                  Icons.cancel,
                  size: 15,
                  color: Colors.red,
                  semanticLabel: 'Tidak Ada',
                ),
        ),

        DataCell(
          SelectableText(dateFormat.format(customer.createdAt.toLocal())),
        ),
        DataCell(
          SelectableText(dateFormat.format(customer.updatedAt.toLocal())),
        ),
        DataCell(
          _buildStatusTdpWidget(
            customer.statusTdp,
            customer.tdpMasaBerlaku,
            colorScheme,
            hasDocument: customer.hasDocument,
            documentCustomerId: customer.documentCustomerId,
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange, size: 15),
                tooltip: 'Edit Customer\n${customer.namaPt}',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditCustomerDialog(customer: customer),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 15,
                ),
                tooltip: 'Document Customer:\n${customer.namaPt}',
                onPressed: () {
                  ref.read(selectedDocumentCustomerProvider.notifier).state =
                      customer;
                  ref.read(configurationTabIndexProvider.notifier).state = 1;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => totalRecords;

  @override
  int get selectedRowCount => 0;

  Widget _buildStatusTdpWidget(
    String? status,
    DateTime? masaBerlaku,
    ColorScheme colorScheme, {
    bool hasDocument = false,
    int? documentCustomerId,
  }) {
    if (status == null || status == '-' || status == 'Tanpa TDP') {
      if (hasDocument || documentCustomerId != null || status == 'Tanpa TDP') {
        // final docIdText = documentCustomerId != null ? ' (ID: $documentCustomerId)' : ''; //$docIdText
        return Tooltip(
          message:
              'Dokumen Customer sudah tersedia\nFile TDP tidak dimasukkan.',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_circle_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Tanpa TDP',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }

      return const Tooltip(
        message: 'Belum ada data dokumen customer.',
        child: Text(
          '-',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
    }

    String tglStr = '';
    if (masaBerlaku != null) {
      tglStr = '\nMasa Berlaku: ${formatTanggalIndonesia(masaBerlaku)}';
    }

    Color color;
    String tooltip;
    IconData icon;

    switch (status) {
      case 'Aktif':
        color = Colors.green.shade600;
        tooltip =
            'Aktif: Masa berlaku TDP masih aman (lebih dari 5 pekan).$tglStr';
        icon = Icons.check_circle;
        break;
      case 'WARNING':
        color = Colors.orange.shade800;
        tooltip =
            'WARNING: Masa berlaku TDP akan habis dalam 5 pekan atau kurang!$tglStr';
        icon = Icons.warning_amber;
        break;
      case 'Expired':
        color = Colors.red.shade700;
        tooltip = 'Expired: Masa berlaku TDP sudah lewat / kadaluarsa!$tglStr';
        icon = Icons.cancel;
        break;
      default:
        color = colorScheme.onSurface;
        tooltip = 'Status: $status$tglStr';
        icon = Icons.help_outline;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
